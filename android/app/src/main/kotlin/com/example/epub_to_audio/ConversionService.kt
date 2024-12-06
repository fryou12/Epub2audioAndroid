package com.example.epub_to_audio

import android.app.*
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import android.content.Context
import android.util.Log

private const val TAG = "EpubToAudio:ConversionService"

class ConversionService : Service() {
    private val CHANNEL_ID = "epub_to_audio_channel"
    private val NOTIFICATION_ID = 1
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Service onCreate - Initialisation du service de conversion")
        acquireWakeLock()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(TAG, "onStartCommand - Action reçue: ${intent?.action ?: "null"}")
        when (intent?.action) {
            "UPDATE_PROGRESS" -> {
                val progress = intent.getIntExtra("progress", 0)
                val total = intent.getIntExtra("total", 0)
                Log.i(TAG, "Mise à jour de la progression - Chapitre $progress sur $total (${if (total > 0) (progress * 100) / total else 0}%)")
                updateNotification(progress, total)
            }
            else -> {
                Log.i(TAG, "Démarrage du service en mode foreground")
                createNotificationChannel()
                startForeground(NOTIFICATION_ID, createInitialNotification())
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        Log.i(TAG, "onBind appelé - Service non bindable")
        return null
    }

    override fun onDestroy() {
        Log.i(TAG, "Service onDestroy - Nettoyage des ressources")
        releaseWakeLock()
        super.onDestroy()
    }

    private fun acquireWakeLock() {
        Log.i(TAG, "Acquisition du WakeLock pour maintenir le service actif")
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "EpubToAudio::ConversionWakeLock"
        ).apply {
            acquire(3 * 60 * 60 * 1000L) // 3 heures maximum
            Log.i(TAG, "WakeLock acquis avec succès - Durée maximale: 3 heures")
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                Log.i(TAG, "Libération du WakeLock")
                it.release()
                Log.i(TAG, "WakeLock libéré avec succès")
            } else {
                Log.i(TAG, "WakeLock déjà libéré")
            }
        }
        wakeLock = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.i(TAG, "Création du canal de notification pour Android O et supérieur")
            val name = "ePub to Audio"
            val descriptionText = "Service de conversion ePub vers Audio"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(true)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.i(TAG, "Canal de notification créé avec succès - ID: $CHANNEL_ID")
        }
    }

    private fun createInitialNotification(): Notification {
        Log.i(TAG, "Création de la notification initiale")
        val pendingIntent: PendingIntent =
            Intent(this, MainActivity::class.java).let { notificationIntent ->
                notificationIntent.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                PendingIntent.getActivity(
                    this, 0, notificationIntent,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    }
                )
            }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Conversion en cours")
            .setContentText("Préparation de la conversion...")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentIntent(pendingIntent)
            .setTicker("Conversion ePub vers Audio")
            .setOngoing(true)
            .setProgress(100, 0, true)
            .build()
    }

    private fun updateNotification(progress: Int, total: Int) {
        val percent = if (total > 0) (progress * 100) / total else 0
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Conversion en cours")
            .setContentText("Progression : $progress sur $total segments")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setProgress(100, percent, false)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
        Log.i(TAG, "Notification mise à jour : $progress/$total segments ($percent%)")
    }
}
