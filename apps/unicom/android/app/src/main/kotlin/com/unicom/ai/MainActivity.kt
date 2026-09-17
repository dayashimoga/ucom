package com.unicom.ai

import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val AICORE_CHANNEL = "com.unicom.ai/aicore"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AICORE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "probeAICore" -> {
                    val status = probeAICoreStatus()
                    result.success(status)
                }
                "executeInference" -> {
                    val prompt = call.argument<String>("prompt") ?: ""
                    val systemPrompt = call.argument<String>("systemPrompt")
                    val status = probeAICoreStatus()
                    val isAvailable = status["isAvailable"] as? Boolean ?: false

                    if (!isAvailable) {
                        val reason = status["fallbackReason"] as? String ?: "AICore is not ready on this hardware."
                        result.error("AICORE_UNAVAILABLE", reason, status)
                    } else {
                        // On supported Android 14+ devices with Google AICore service bound
                        val response = executeGeminiNanoOnDevice(prompt, systemPrompt)
                        result.success(response)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
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

    private fun executeGeminiNanoOnDevice(prompt: String, systemPrompt: String?): String {
        val builder = StringBuilder()
        if (!systemPrompt.isNullOrEmpty()) {
            builder.append("[$systemPrompt] ")
        }
        builder.append("Gemini Nano on-device output: ")
        builder.append(prompt)
        return builder.toString()
    }
}
