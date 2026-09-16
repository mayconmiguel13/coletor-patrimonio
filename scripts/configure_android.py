import glob
import os

def main():
    print("Iniciando configuracao do projeto nativo Android...")

    # 1. Permissoes no AndroidManifest.xml
    manifest_path = "android/app/src/main/AndroidManifest.xml"
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = f.read()

        perms = """
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.FLASHLIGHT" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
    <uses-feature android:name="android.hardware.camera.flash" android:required="false" />
"""
        if "<application" in manifest:
            manifest = manifest.replace("<application", perms + "\n    <application", 1)
            with open(manifest_path, "w", encoding="utf-8") as f:
                f.write(manifest)
            print("AndroidManifest.xml atualizado com permissoes.")

    # 2. Criar regras do ProGuard
    proguard_path = "android/app/proguard-rules.pro"
    proguard_content = """-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep interface dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn dev.steenbakker.mobile_scanner.**
-dontwarn com.google.mlkit.**
"""
    with open(proguard_path, "w", encoding="utf-8") as f:
        f.write(proguard_content)
    print("proguard-rules.pro configurado.")

    # 3. Injetar suporte a Bip nativo (AudioTrack PCM + ToneGenerator + Vibrator) no MainActivity.kt
    main_activity_files = glob.glob("android/app/src/main/**/MainActivity.kt", recursive=True)
    if main_activity_files:
        kt_path = main_activity_files[0]
        kt_code = """package com.coletor.coletor_patrimonio

import android.content.Context
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.ToneGenerator
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.coletor.patrimonio/feedback"
    private var toneGenerator: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        try {
            toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "beepSuccess" -> {
                    vibratePhone(200)
                    playBeepAudio(2500.0, 90)
                    result.success(null)
                }
                "vibrateOnly" -> {
                    vibratePhone(200)
                    result.success(null)
                }
                "beepError" -> {
                    vibrateError()
                    playErrorAudio()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun vibratePhone(durationMs: Long) {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vm?.defaultVibrator ?: (getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator)
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }

            val audioAttrs = android.media.AudioAttributes.Builder()
                .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                .build()

            if (vibrator != null && vibrator.hasVibrator()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val effect = VibrationEffect.createOneShot(durationMs, 255)
                    vibrator.vibrate(effect, audioAttrs)
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(durationMs)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun vibrateError() {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vm?.defaultVibrator ?: (getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator)
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }

            val audioAttrs = android.media.AudioAttributes.Builder()
                .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                .build()

            if (vibrator != null && vibrator.hasVibrator()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val timings = longArrayOf(0, 180, 100, 180)
                    val amplitudes = intArrayOf(0, 255, 0, 255)
                    val effect = VibrationEffect.createWaveform(timings, amplitudes, -1)
                    vibrator.vibrate(effect, audioAttrs)
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(400)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun playBeepAudio(frequency: Double, durationMs: Int) {
        thread(start = true) {
            try {
                // Tenta ToneGenerator direto no canal STREAM_MUSIC
                try {
                    toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, durationMs)
                } catch (_: Exception) {}

                // Gera onda senoidal pura PCM 16-bit diretamente no AudioTrack
                val sampleRate = 44100
                val numSamples = (durationMs * sampleRate) / 1000
                val generatedSnd = ByteArray(2 * numSamples)
                for (i in 0 until numSamples) {
                    val dVal = Math.sin(2.0 * Math.PI * i.toDouble() / (sampleRate / frequency))
                    val sVal = (dVal * 32767).toInt().toShort()
                    generatedSnd[2 * i] = (sVal.toInt() and 0x00ff).toByte()
                    generatedSnd[2 * i + 1] = ((sVal.toInt() and 0xff00) ushr 8).toByte()
                }
                val track = AudioTrack(
                    AudioManager.STREAM_MUSIC,
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    generatedSnd.size,
                    AudioTrack.MODE_STATIC
                )
                track.write(generatedSnd, 0, generatedSnd.size)
                track.play()
                Thread.sleep((durationMs + 40).toLong())
                track.release()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun playErrorAudio() {
        thread(start = true) {
            try {
                try {
                    toneGenerator?.startTone(ToneGenerator.TONE_PROP_NACK, 250)
                } catch (_: Exception) {}

                playBeepAudio(700.0, 150)
                Thread.sleep(180)
                playBeepAudio(550.0, 200)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
"""
        with open(kt_path, "w", encoding="utf-8") as f:
            f.write(kt_code)
        print(f"MainActivity.kt configurado com suporte a Bip e Vibracao em {kt_path}.")

    # 4. Forcar local.properties com sdk 21 e 35
    with open("android/local.properties", "a", encoding="utf-8") as f:
        f.write("\nflutter.minSdkVersion=21\nflutter.compileSdkVersion=35\n")
    print("local.properties atualizado com sdk 21 e 35.")

    # 5. Ajustar compileSdk 35, minSdk 21 e desativar minificacao R8 de forma compativel
    for path in glob.glob("android/app/build.gradle*"):
        with open(path, "r", encoding="utf-8") as f:
            bg = f.read()
        bg = bg.replace("flutter.minSdkVersion", "21")
        bg = bg.replace("flutter.compileSdkVersion", "35")
        bg = bg.replace("compileSdkVersion 34", "compileSdkVersion 35")
        bg = bg.replace("minSdkVersion 16", "minSdkVersion 21")
        bg = bg.replace("minSdkVersion 19", "minSdkVersion 21")
        bg = bg.replace("minSdkVersion 23", "minSdkVersion 21")

        if path.endswith(".kts"):
            target = 'signingConfig = signingConfigs.getByName("debug")'
            if target in bg:
                replacement = target + '\n            isMinifyEnabled = false\n            isShrinkResources = false'
                bg = bg.replace(target, replacement, 1)
        else:
            target = 'signingConfig signingConfigs.debug'
            if target in bg:
                replacement = target + '\n            minifyEnabled false\n            shrinkResources false'
                bg = bg.replace(target, replacement, 1)

        with open(path, "w", encoding="utf-8") as f:
            f.write(bg)
        print(f"build.gradle configurado com sucesso em {path}.")

if __name__ == "__main__":
    main()
