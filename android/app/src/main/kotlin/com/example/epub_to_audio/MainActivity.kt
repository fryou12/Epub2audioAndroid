package com.example.epub_to_audio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import android.util.Log
import android.content.Intent
import android.os.Build
import android.app.NotificationManager
import android.app.NotificationChannel
import android.os.Bundle
import android.content.Context
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import org.json.JSONObject
import org.json.JSONArray
import java.io.File
import kotlin.math.roundToInt

private const val TAG = "EpubToAudio:MainActivity"
private const val SYNTHESIS_TIMEOUT = 600_000L // 10 minutes

class MainActivity: FlutterActivity() {
    private val PYTHON_CHANNEL = "com.example.epub_to_audio/python"
    private val SERVICE_CHANNEL = "com.example.epub_to_audio/service"
    private var conversionService: Intent? = null
    private val conversionScope = CoroutineScope(Dispatchers.Default + Job())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        createNotificationChannel()

        // Canal Python
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PYTHON_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPythonAvailable" -> handlePythonCheck(result)
                "getVoices" -> handleGetVoices(result)
                "synthesize" -> handleSynthesis(call, result)
                else -> result.notImplemented()
            }
        }

        // Canal Service
        setupServiceChannel(flutterEngine)
    }

    private fun handlePythonCheck(result: Result) {
        try {
            Log.i(TAG, "Checking Python availability...")
            if (!Python.isStarted()) {
                Log.i(TAG, "Python not started, initializing...")
                Python.start(AndroidPlatform(context))
            }
            val py = Python.getInstance()
            val testModule = py.getModule("test_module")
            val testResult = testModule.callAttr("test_function").toString()
            Log.i(TAG, "Test result: $testResult")
            
            val module = py.getModule("edge_tts_module")
            Log.i(TAG, "Python initialization successful")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Python error: ${e.message}", e)
            result.error("PYTHON_ERROR", e.message, null)
        }
    }

    private fun handleGetVoices(result: Result) {
        try {
            Log.i(TAG, "Getting voices...")
            val py = Python.getInstance()
            val module = py.getModule("edge_tts_module")
            val voicesJson = module.callAttr("get_voices").toString()
            Log.i(TAG, "Voices received: $voicesJson")
            
            val jsonResponse = JSONObject(voicesJson)
            if (jsonResponse.has("error")) {
                val error = jsonResponse.getString("error")
                Log.e(TAG, "Error getting voices: $error")
                result.error("VOICE_ERROR", error, null)
                return
            }
            
            if (jsonResponse.has("voices")) {
                result.success(voicesJson)
            } else {
                result.error("VOICE_ERROR", "Invalid response format", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting voices: ${e.message}", e)
            result.error("VOICE_ERROR", e.message, null)
        }
    }

    private fun handleSynthesis(call: MethodCall, result: Result) {
        val text = call.argument<String>("text")!!
        val voiceId = call.argument<String>("voiceId")!!
        val outputFile = call.argument<String>("outputFile")!!
        
        conversionScope.launch {
            try {
                Log.i(TAG, "Starting synthesis with voice: $voiceId")
                val py = Python.getInstance()
                val module = py.getModule("edge_tts_module")
                
                withTimeout(SYNTHESIS_TIMEOUT) {
                    val response = withContext(Dispatchers.IO) {
                        module.callAttr(
                            "synthesize",
                            text,
                            voiceId,
                            outputFile
                        ).toString()
                    }
                    
                    val jsonResponse = JSONObject(response)
                    if (jsonResponse.has("success") && jsonResponse.getBoolean("success")) {
                        val results = jsonResponse.getJSONArray("results")
                        val totalSegments = jsonResponse.getInt("total_segments")
                        val chapterSegments = mutableMapOf<Int, MutableList<String>>()
                        
                        // Initialisation de la progression avec le nombre total de segments
                        updateServiceProgress(0, totalSegments)
                        
                        // Traitement des résultats
                        for (i in 0 until results.length()) {
                            val result = results.getJSONObject(i)
                            if (result.has("output_file")) {
                                val chapterIdx = result.optInt("chapter", 0)
                                chapterSegments.getOrPut(chapterIdx) { mutableListOf() }
                                    .add(result.getString("output_file"))
                                
                                // Mise à jour de la progression basée sur le nombre de segments traités
                                val progress = result.optInt("progress", 0)
                                updateServiceProgress(progress, totalSegments)
                            }
                        }
                        
                        // Fusion des fichiers audio par chapitre
                        val finalChapterFiles = mutableListOf<String>()
                        for ((chapterIdx, segments) in chapterSegments.entries.sortedBy { it.key }) {
                            val chapterOutputFile = "${outputFile}_chapter_$chapterIdx.mp3"
                            try {
                                AudioMerger.mergeAudioFiles(segments, chapterOutputFile)
                                finalChapterFiles.add(chapterOutputFile)
                            } catch (e: Exception) {
                                Log.e(TAG, "Erreur lors de la fusion du chapitre $chapterIdx: ${e.message}")
                            }
                        }
                        
                        // Fusion finale des chapitres
                        try {
                            AudioMerger.mergeAudioFiles(finalChapterFiles, outputFile)
                            finalChapterFiles.forEach { File(it).delete() }
                            withContext(Dispatchers.Main) {
                                result.success(JSONObject().put("success", true).toString())
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error during final merge: ${e.message}")
                            withContext(Dispatchers.Main) {
                                result.error("MERGE_ERROR", e.message, null)
                            }
                        }
                    } else {
                        withContext(Dispatchers.Main) {
                            result.error("SYNTHESIS_ERROR", "Synthesis failed", response)
                        }
                    }
                }
            } catch (e: TimeoutCancellationException) {
                Log.e(TAG, "Synthesis timeout: ${e.message}")
                withContext(Dispatchers.Main) {
                    result.error("TIMEOUT_ERROR", "Synthesis timeout after ${SYNTHESIS_TIMEOUT/1000} seconds", null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Synthesis error: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    result.error("SYNTHESIS_ERROR", e.message, null)
                }
            }
        }
    }

    private fun setupServiceChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startConversionService" -> {
                    Log.i(TAG, "Démarrage du service de conversion")
                    startService()
                    moveTaskToBack(true)
                    result.success(null)
                }
                "stopConversionService" -> {
                    Log.i(TAG, "Arrêt du service de conversion")
                    stopService()
                    result.success(null)
                }
                "updateProgress" -> {
                    val progress = call.argument<Int>("progress") ?: 0
                    val total = call.argument<Int>("total") ?: 0
                    Log.i(TAG, "Envoi de la mise à jour de progression au service: $progress/$total")
                    updateServiceProgress(progress, total)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startService() {
        val serviceIntent = Intent(this, ConversionService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopService() {
        val serviceIntent = Intent(this, ConversionService::class.java)
        stopService(serviceIntent)
    }

    private fun updateServiceProgress(progress: Int, total: Int) {
        Log.i(TAG, "Mise à jour de la progression dans MainActivity: $progress/$total")
        val intent = Intent(this, ConversionService::class.java).apply {
            action = "UPDATE_PROGRESS"
            putExtra("progress", progress)
            putExtra("total", total)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "ePub to Audio"
            val descriptionText = "Service de conversion ePub vers Audio"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel("epub_to_audio_channel", name, importance).apply {
                description = descriptionText
                setShowBadge(true)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        conversionScope.cancel()
        stopService()
        super.onDestroy()
    }
}
