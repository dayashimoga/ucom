package com.unicom.ai

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONObject

class MainActivity: FlutterActivity(), TextToSpeech.OnInitListener {
    private val AICORE_CHANNEL = "com.unicom.ai/aicore"
    private val SPEECH_CHANNEL = "com.unicom.ai/speech"
    private val PERMISSION_REQUEST_MIC = 1001

    private var textToSpeech: TextToSpeech? = null
    private var isTtsInitialized = false
    private var pendingTtsText: String? = null
    private var pendingTtsLang: String? = null
    private var pendingTtsRate: Float = 1.0f

    private var speechRecognizer: SpeechRecognizer? = null
    private var speechChannel: MethodChannel? = null
    private var isContinuousListening = false
    private var isListeningActive = false
    private var currentListeningLang = "en-US"
    private var pendingPermissionResult: MethodChannel.Result? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize Android native Text-To-Speech engine
        textToSpeech = TextToSpeech(this, this)

        // 1. Android GenAI / AICore Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AICORE_CHANNEL).setMethodCallHandler { call, result ->
            val status = probeAICoreStatus()
            val isAvailable = status["isAvailable"] as? Boolean ?: false

            when (call.method) {
                "probeAICore", "checkCapability" -> {
                    result.success(status)
                }
                "getFeatureStatus" -> {
                    result.success(status["statusCode"] ?: "NOT_SUPPORTED")
                }
                "prepareModel" -> {
                    if (!isAvailable) {
                        result.error("UNSUPPORTED", status["fallbackReason"] as? String ?: "On-device GenAI unsupported on this hardware", status)
                    } else {
                        result.success(mapOf("status" to "READY", "model" to "gemini-nano"))
                    }
                }
                "warmup" -> {
                    if (!isAvailable) {
                        result.error("UNSUPPORTED", status["fallbackReason"] as? String ?: "On-device GenAI unsupported on this hardware", status)
                    } else {
                        result.success(true)
                    }
                }
                "generate", "executeInference" -> {
                    if (!isAvailable) {
                        val reason = status["fallbackReason"] as? String ?: "AICore is not available on this hardware."
                        result.error("AICORE_UNAVAILABLE", reason, status)
                    } else {
                        result.error("DEVICE_VALIDATION_BLOCKED", "Physical Gemini Nano inference requires supported hardware with Google AICore service bound and model prepared.", status)
                    }
                }
                "generateStreaming" -> {
                    if (!isAvailable) {
                        val reason = status["fallbackReason"] as? String ?: "AICore is not available on this hardware."
                        result.error("AICORE_UNAVAILABLE", reason, status)
                    } else {
                        result.error("DEVICE_VALIDATION_BLOCKED", "Physical Gemini Nano streaming requires supported hardware.", status)
                    }
                }
                "summarize" -> {
                    if (!isAvailable) {
                        val reason = status["fallbackReason"] as? String ?: "AICore is not available on this hardware."
                        result.error("AICORE_UNAVAILABLE", reason, status)
                    } else {
                        result.error("DEVICE_VALIDATION_BLOCKED", "Physical Gemini Nano summarization requires supported hardware.", status)
                    }
                }
                "cancel" -> {
                    result.success(true)
                }
                "getDiagnostics" -> {
                    val sdkInt = Build.VERSION.SDK_INT
                    val manufacturer = Build.MANUFACTURER
                    val model = Build.MODEL
                    val hardware = Build.HARDWARE
                    val memoryInfo = android.app.ActivityManager.MemoryInfo()
                    (getSystemService(android.content.Context.ACTIVITY_SERVICE) as? android.app.ActivityManager)?.getMemoryInfo(memoryInfo)

                    result.success(mapOf(
                        "sdkInt" to sdkInt,
                        "manufacturer" to manufacturer,
                        "model" to model,
                        "hardware" to hardware,
                        "totalRamMb" to (memoryInfo.totalMem / (1024 * 1024)),
                        "availRamMb" to (memoryInfo.availMem / (1024 * 1024)),
                        "aicoreStatus" to status
                    ))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 2. Android Native Speech & Audio Channel (TTS + STT + Mic)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPEECH_CHANNEL)
        speechChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppDataDirectory" -> {
                    result.success(filesDir.absolutePath)
                }
                "speakText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val language = call.argument<String>("language") ?: "en"
                    val rate = call.argument<Double>("rate")?.toFloat() ?: 1.0f

                    if (!isTtsInitialized || textToSpeech == null) {
                        pendingTtsText = text
                        pendingTtsLang = language
                        pendingTtsRate = rate
                        result.success(true)
                        return@setMethodCallHandler
                    }

                    try {
                        val locale = parseLocale(language)
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
                        pendingPermissionResult = result
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), PERMISSION_REQUEST_MIC)
                    }
                }
                "isSpeechRecognitionAvailable" -> {
                    val isAvail = SpeechRecognizer.isRecognitionAvailable(this)
                    result.success(isAvail)
                }
                "startListening" -> {
                    val language = call.argument<String>("language") ?: "en-US"
                    val continuous = call.argument<Boolean>("continuous") ?: false
                    val hasPerm = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

                    if (!hasPerm) {
                        result.error("PERMISSION_DENIED", "RECORD_AUDIO permission is not granted.", null)
                        return@setMethodCallHandler
                    }

                    if (!SpeechRecognizer.isRecognitionAvailable(this)) {
                        result.error("RECOGNIZER_UNAVAILABLE", "Speech recognition service is not available on this device.", null)
                        return@setMethodCallHandler
                    }

                    isContinuousListening = continuous
                    isListeningActive = true
                    currentListeningLang = language

                    startRecognizerInternal(language)
                    result.success(true)
                }
                "stopListening" -> {
                    isContinuousListening = false
                    isListeningActive = false
                    mainHandler.post {
                        try {
                            speechRecognizer?.stopListening()
                        } catch (e: Exception) {
                            // Ignored
                        }
                        speechChannel?.invokeMethod("onListeningStopped", null)
                    }
                    result.success(true)
                }
                "cancelListening" -> {
                    isContinuousListening = false
                    isListeningActive = false
                    mainHandler.post {
                        try {
                            speechRecognizer?.cancel()
                        } catch (e: Exception) {
                            // Ignored
                        }
                        speechChannel?.invokeMethod("onListeningStopped", null)
                    }
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 3. Android Keystore Hardware-Backed Secure Storage Channel
        val SECURE_STORAGE_CHANNEL = "com.unicom.ai/secure_storage"
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURE_STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            val vaultFile = File(filesDir, ".secure_keystore_vault.json")
            when (call.method) {
                "saveKey" -> {
                    val keyId = call.argument<String>("keyId") ?: ""
                    val value = call.argument<String>("value") ?: ""
                    try {
                        val json = if (vaultFile.exists()) JSONObject(vaultFile.readText()) else JSONObject()
                        if (value.isEmpty()) {
                            json.remove(keyId)
                        } else {
                            json.put(keyId, encryptSecure(value))
                        }
                        vaultFile.writeText(json.toString())
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SECURE_STORE_ERROR", e.localizedMessage, null)
                    }
                }
                "getKey" -> {
                    val keyId = call.argument<String>("keyId") ?: ""
                    try {
                        if (!vaultFile.exists()) {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        val json = JSONObject(vaultFile.readText())
                        if (!json.has(keyId)) {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        val encrypted = json.getString(keyId)
                        val decrypted = decryptSecure(encrypted)
                        result.success(decrypted)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                "removeKey" -> {
                    val keyId = call.argument<String>("keyId") ?: ""
                    try {
                        if (vaultFile.exists()) {
                            val json = JSONObject(vaultFile.readText())
                            json.remove(keyId)
                            vaultFile.writeText(json.toString())
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SECURE_REMOVE_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private val KEY_ALIAS = "unicom_master_key"
    private val ANDROID_KEYSTORE = "AndroidKeyStore"
    private val TRANSFORMATION = "AES/GCM/NoPadding"

    private fun getOrCreateSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        if (keyStore.containsAlias(KEY_ALIAS)) {
            val entry = keyStore.getEntry(KEY_ALIAS, null) as KeyStore.SecretKeyEntry
            return entry.secretKey
        }
        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        keyGenerator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
        )
        return keyGenerator.generateKey()
    }

    private fun encryptSecure(plaintext: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateSecretKey())
        val iv = cipher.iv
        val ciphertext = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))
        val combined = ByteArray(iv.size + ciphertext.size)
        System.arraycopy(iv, 0, combined, 0, iv.size)
        System.arraycopy(ciphertext, 0, combined, iv.size, ciphertext.size)
        return Base64.encodeToString(combined, Base64.NO_WRAP)
    }

    private fun decryptSecure(encoded: String): String? {
        return try {
            val combined = Base64.decode(encoded, Base64.NO_WRAP)
            val iv = ByteArray(12)
            val ciphertext = ByteArray(combined.size - 12)
            System.arraycopy(combined, 0, iv, 0, 12)
            System.arraycopy(combined, 12, ciphertext, 0, ciphertext.size)
            val cipher = Cipher.getInstance(TRANSFORMATION)
            val spec = GCMParameterSpec(128, iv)
            cipher.init(Cipher.DECRYPT_MODE, getOrCreateSecretKey(), spec)
            String(cipher.doFinal(ciphertext), Charsets.UTF_8)
        } catch (e: Exception) {
            null
        }
    }

    private fun startRecognizerInternal(language: String) {
        mainHandler.post {
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

                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 2000L)
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 1500L)
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 1500L)
                }

                speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {
                        speechChannel?.invokeMethod("onListeningReady", null)
                    }

                    override fun onBeginningOfSpeech() {
                        speechChannel?.invokeMethod("onBeginningOfSpeech", null)
                    }

                    override fun onRmsChanged(rmsdB: Float) {
                        speechChannel?.invokeMethod("onRmsChanged", rmsdB)
                    }

                    override fun onBufferReceived(buffer: ByteArray?) {}

                    override fun onEndOfSpeech() {
                        speechChannel?.invokeMethod("onEndOfSpeech", null)
                    }

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

                        // In continuous mode, auto-restart on timeout or no match if still active
                        if (isContinuousListening && isListeningActive && (error == SpeechRecognizer.ERROR_NO_MATCH || error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT)) {
                            mainHandler.postDelayed({
                                if (isListeningActive && isContinuousListening) {
                                    startRecognizerInternal(currentListeningLang)
                                }
                            }, 300)
                            return
                        }

                        speechChannel?.invokeMethod("onError", mapOf(
                            "code" to error,
                            "message" to errorMsg
                        ))

                        if (!isContinuousListening) {
                            isListeningActive = false
                            speechChannel?.invokeMethod("onListeningStopped", null)
                        }
                    }

                    override fun onResults(results: Bundle?) {
                        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val recognizedText = matches?.firstOrNull() ?: ""

                        if (recognizedText.isNotEmpty()) {
                            speechChannel?.invokeMethod("onFinalTranscript", mapOf(
                                "text" to recognizedText,
                                "isFinal" to true
                            ))
                        }

                        if (isContinuousListening && isListeningActive) {
                            mainHandler.postDelayed({
                                if (isListeningActive && isContinuousListening) {
                                    startRecognizerInternal(currentListeningLang)
                                }
                            }, 200)
                        } else {
                            isListeningActive = false
                            speechChannel?.invokeMethod("onListeningStopped", null)
                        }
                    }

                    override fun onPartialResults(partialResults: Bundle?) {
                        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val partialText = matches?.firstOrNull() ?: ""
                        if (partialText.isNotEmpty()) {
                            speechChannel?.invokeMethod("onPartialTranscript", mapOf(
                                "text" to partialText,
                                "isFinal" to false
                            ))
                        }
                    }

                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })

                speechRecognizer?.startListening(intent)
            } catch (e: Exception) {
                speechChannel?.invokeMethod("onError", mapOf(
                    "code" to -1,
                    "message" to (e.localizedMessage ?: "Failed to start speech recognizer")
                ))
                isListeningActive = false
                speechChannel?.invokeMethod("onListeningStopped", null)
            }
        }
    }

    private fun parseLocale(lang: String): Locale {
        return try {
            if (lang.contains("-") || lang.contains("_")) {
                Locale.forLanguageTag(lang.replace('_', '-'))
            } else {
                Locale(lang)
            }
        } catch (e: Exception) {
            Locale.getDefault()
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_MIC) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
            speechChannel?.invokeMethod("onPermissionResult", granted)
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            isTtsInitialized = true
            if (pendingTtsText != null) {
                val text = pendingTtsText!!
                val lang = pendingTtsLang ?: "en"
                val rate = pendingTtsRate
                pendingTtsText = null
                pendingTtsLang = null
                try {
                    textToSpeech?.language = parseLocale(lang)
                    textToSpeech?.setSpeechRate(rate)
                    textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "unicom_tts_pending")
                } catch (_: Exception) {}
            }
        }
    }

    override fun onDestroy() {
        isListeningActive = false
        isContinuousListening = false
        mainHandler.removeCallbacksAndMessages(null)
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
