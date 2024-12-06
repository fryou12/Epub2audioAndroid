package com.example.epub_to_audio

import android.util.Log
import java.io.*
import kotlinx.coroutines.*
import java.nio.channels.FileChannel

private const val TAG = "EpubToAudio:AudioMerger"

class AudioMerger {
    companion object {
        suspend fun mergeAudioFiles(inputFiles: List<String>, outputFile: String) = withContext(Dispatchers.IO) {
            try {
                Log.i(TAG, "Début de la fusion des fichiers audio: ${inputFiles.size} fichiers")
                
                // Vérifie que tous les fichiers existent
                val existingFiles = inputFiles.filter { file ->
                    val exists = File(file).exists()
                    if (!exists) {
                        Log.e(TAG, "Fichier manquant: $file")
                    }
                    exists
                }
                
                if (existingFiles.isEmpty()) {
                    throw IOException("Aucun fichier à fusionner n'existe")
                }
                
                // Vérifie la taille des fichiers
                existingFiles.forEach { file ->
                    val size = File(file).length()
                    Log.i(TAG, "Taille du fichier $file: $size bytes")
                }
                
                val output = FileOutputStream(outputFile)
                val outChannel = output.channel
                var totalBytesWritten = 0L

                existingFiles.forEachIndexed { index, inputFile ->
                    try {
                        val input = FileInputStream(inputFile)
                        val inChannel = input.channel
                        val fileSize = inChannel.size()
                        
                        // Skip MP3 header for all files except the first one
                        val position = if (index == 0) 0L else 128L
                        val bytesToWrite = fileSize - position
                        
                        Log.i(TAG, "Fusion de $inputFile (taille: $fileSize, position: $position, à écrire: $bytesToWrite)")
                        
                        val bytesWritten = inChannel.transferTo(position, bytesToWrite, outChannel)
                        totalBytesWritten += bytesWritten
                        
                        Log.i(TAG, "Écrit $bytesWritten bytes depuis $inputFile")
                        
                        inChannel.close()
                        input.close()
                        
                        // Supprime le fichier temporaire après la fusion
                        if (File(inputFile).delete()) {
                            Log.i(TAG, "Fichier temporaire supprimé: $inputFile")
                        } else {
                            Log.w(TAG, "Impossible de supprimer le fichier temporaire: $inputFile")
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Erreur lors de la fusion du fichier $inputFile: ${e.message}")
                        throw e
                    }
                }

                outChannel.close()
                output.close()
                
                val finalSize = File(outputFile).length()
                Log.i(TAG, "Fusion terminée. Taille finale: $finalSize bytes (total écrit: $totalBytesWritten)")
                
                if (finalSize == 0L) {
                    throw IOException("Le fichier fusionné est vide")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Erreur lors de la fusion des fichiers audio: ${e.message}")
                throw e
            }
        }
    }
}
