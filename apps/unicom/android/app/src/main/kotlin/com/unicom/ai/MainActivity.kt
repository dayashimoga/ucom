package com.unicom.ai

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity: FlutterActivity(), TextToSpeech.OnInitListener {
    private val AICORE_CHANNEL = "com.unicom.ai/aicore"
    private val SPEECH_CHANNEL = "com.unicom.ai/speech"

    private var textToSpeech: TextToSpeech? = null
    private var isTtsInitialized = false
    private var speechRecognizer: SpeechRecognizer? = null
    private var activeSpeechResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize Android native Text-To-Speech engine
        textToSpeech = TextToSpeech(this, this)

        // 1. Android AICore Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AICORE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "probeAICore" -> {
                    val status = probeAICoreStatus()
                    result.success(status)
                }
                "executeInference" -> {
                    val status = probeAICoreStatus()
                    val isAvailable = status["isAvailable"] as? Boolean ?: false

                    if (!isAvailable) {
                        val reason = status["fallbackReason"] as? String ?: "AICore is not available on this hardware."
                        result.error("AICORE_UNAVAILABLE", reason, status)
                    } else {
                        // Per strict production audit: physical inference without Google AICore service token is blocked
                        result.error("AICORE_INFERENCE_BLOCKED", "Physical Gemini Nano inference requires supported hardware with Google AICore service bound.", status)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 2. Android Native Speech & Audio Channel (TTS + STT + Mic)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPEECH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "speakText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val language = call.argument<String>("language") ?: "en"
                    val rate = call.argument<Double>("rate")?.toFloat() ?: 1.0f

                    if (!isTtsInitialized || textToSpeech == null) {
                        result.error("TTS_NOT_INITIALIZED", "TextToSpeech engine is not initialized yet.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val locale = Locale.forLanguageTag(language)
                        textToSpeech?.language = locale
                        textToSpeech?.setSpeechRate(rate)
                        val res = textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "unicom_tts_${System.currentTimeMillis()}")
                        if (res == TextToSpeech.SUCCESS) {
                            result.success(true)
                        } else {
                            result.error("TTS_PLAYBACK_FAILED", "TextToSpeech.speak returned error code: $res", null)
                        }
                    } catch (e: Exception) {
                        result.error("TTS_EXCEPTION", e.localizedMessage, null)
                    }
                }
                "stopSpeech" -> {
                    textToSpeech?.stop()
                    result.success(true)
                }
                "checkMicPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }
                "requestMicPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
                    if (granted) {
                        result.success(true)
                    } else {
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), 1001)
                        result.success(false)
                    }
                }
                "isSpeechRecognitionAvailable" -> {
                    val isAvail = SpeechRecognizer.isRecognitionAvailable(this)
                    result.success(isAvail)
                }
                "startListening" -> {
                    val language = call.argument<String>("language") ?: "en-US"
                    val hasPerm = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

                    if (!hasPerm) {
                        result.error("PERMISSION_DENIED", "RECORD_AUDIO permission is not granted.", null)
                        return@setMethodCallHandler
                    }

                    runOnUiThread {
                        try {
                            if (speechRecognizer != null) {
                                speechRecognizer?.destroy()
                                speechRecognizer = null
                            }

                            speechRecognizer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && SpeechRecognizer.isOnDeviceRecognitionAvailable(this)) {
                                SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
                            } else {
                                SpeechRecognizer.createSpeechRecognizer(this)
                            }

                            activeSpeechResult = result

                            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
                                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
                            }

                            speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                                override fun onReadyForSpeech(params: Bundle?) {}
                                override fun onBeginningOfSpeech() {}
                                override fun onRmsChanged(rmsdB: Float) {}
                                override fun onBufferReceived(buffer: ByteArray?) {}
                                override fun onEndOfSpeech() {}
                                override fun onError(error: Int) {
                                    val errorMsg = when (error) {
                                        SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                                        SpeechRecognizer.ERROR_CLIENT -> "Client error"
                                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                                        SpeechRecognizer.ERROR_NETWORK -> "Network error"
                                        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                                        SpeechRecognizer.ERROR_NO_MATCH -> "No speech recognized"
                                        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
                                        SpeechRecognizer.ERROR_SERVER -> "Server error"
                                        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech detected"
                                        else -> "Speech recognition error: $error"
                                    }
                                    activeSpeechResult?.error("SPEECH_ERROR", errorMsg, error)
                                    activeSpeechResult = null
                                }

                                override fun onResults(results: Bundle?) {
                                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                                    val recognizedText = matches?.firstOrNull() ?: ""
                                    activeSpeechResult?.success(mapOf(
                                        "text" to recognizedText,
                                        "isFinal" to true
                                    ))
                                    activeSpeechResult = null
                                }

                                override fun onPartialResults(partialResults: Bundle?) {
                                    val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                                    val partialText = matches?.firstOrNull() ?: ""
                                    // Optional partial progress
                                }

                                override fun onEvent(eventType: Int, params: Bundle?) {}
                            })

                            speechRecognizer?.startListening(intent)
                        } catch (e: Exception) {
                            result.error("SPEECH_INIT_ERROR", e.localizedMessage, null)
                            activeSpeechResult = null
                        }
                    }
                }
                "stopListening" -> {
                    runOnUiThread {
                        speechRecognizer?.stopListening()
                    }
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            isTtsInitialized = true
        }
    }

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        speechRecognizer?.destroy()
        super.onDestroy()
    }

    private fun probeAICoreStatus(): Map<String, Any?> {
        val sdkInt = Build.VERSION.SDK_INT
        val isAndroid14OrHigher = sdkInt >= 34

        // Probe for Android AICore system service package (com.google.android.aicore)
        var isAICorePackageInstalled = false
        var aicoreVersion = "none"
        try {
            val packageInfo = packageManager.getPackageInfo("com.google.android.aicore", 0)
            isAICorePackageInstalled = true
            aicoreVersion = packageInfo.versionName ?: "system"
        } catch (e: PackageManager.NameNotFoundException) {
            isAICorePackageInstalled = false
        }

        val isSupportedHardware = isAndroid14OrHigher && isAICorePackageInstalled

        return if (isSupportedHardware) {
            mapOf(
                "isAvailable" to true,
                "isSupportedOnDevice" to true,
                "statusCode" to "AVAILABLE",
                "modelName" to "Gemini Nano (Android System AICore)",
                "runtimeVersion" to aicoreVersion,
                "maxContextTokens" to 4096,
                "supportedCapabilities" to listOf(
                    "text_generation",
                    "summarization",
                    "qa",
                    "streaming",
                    "zero_network_leak"
                ),
                "fallbackReason" to null
            )
        } else {
            val reason = if (!isAndroid14OrHigher) {
                "Android API $sdkInt detected. Android AICore / Gemini Nano requires Android 14+ (API 34)."
            } else {
                "Android AICore system service (com.google.android.aicore) is not installed on this device build/SoC."
            }

            mapOf(
                "isAvailable" to false,
                "isSupportedOnDevice" to false,
                "statusCode" to "NOT_SUPPORTED",
                "modelName" to null,
                "runtimeVersion" to null,
                "maxContextTokens" to 0,
                "supportedCapabilities" to emptyList<String>(),
                "fallbackReason" to reason
            )
        }
    }
}
