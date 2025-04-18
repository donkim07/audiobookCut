package com.example.audiobookcut

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.audiobookcut/audio"
    private val TAG = "AudioCutter"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val binaryMessenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (binaryMessenger != null) {
            MethodChannel(binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                Log.d(TAG, "Method called: ${call.method}")
                
                if (call.method.equals("cutAudio", ignoreCase = true)) {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    val startMs = call.argument<Int>("startMs") ?: 0
                    val endMs = call.argument<Int>("endMs") ?: 0

                    Log.d(TAG, "Cutting audio: $inputPath -> $outputPath ($startMs to $endMs ms)")

                    try {
                        cutAudio(inputPath!!, outputPath!!, startMs, endMs)
                        Log.d(TAG, "Audio cut successfully")
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Audio cutting failed", e)
                        result.error("ERROR", "Audio cutting failed", e.message)
                    }
                } else {
                    result.notImplemented()
                }
            }
        } else {
            Log.e(TAG, "Flutter binary messenger is null")
        }
    }

    @Throws(Exception::class)
    private fun cutAudio(inputPath: String, outputPath: String, startMs: Int, endMs: Int) {
        Log.d(TAG, "Starting to cut audio...")
        
        val extractor = MediaExtractor()
        extractor.setDataSource(inputPath)
        val trackIndex = selectTrack(extractor)
        Log.d(TAG, "Selected track: $trackIndex")
        
        extractor.selectTrack(trackIndex)

        val format = extractor.getTrackFormat(trackIndex)
        val mime = format.getString(MediaFormat.KEY_MIME)
        val duration = format.getLong(MediaFormat.KEY_DURATION)
        Log.d(TAG, "Track format: $mime, duration: ${duration/1000}ms")
        
        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val muxerTrackIndex = muxer.addTrack(format)
        muxer.start()

        Log.d(TAG, "Seeking to $startMs ms")
        extractor.seekTo(startMs * 1000L, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
        val buffer = ByteBuffer.allocate(1024 * 1024)
        val info = MediaCodec.BufferInfo()
        
        var samplesCount = 0

        while (true) {
            val sampleSize = extractor.readSampleData(buffer, 0)
            if (sampleSize < 0) {
                Log.d(TAG, "End of samples reached")
                break
            }

            val sampleTime = extractor.sampleTime
            if (sampleTime > endMs * 1000L) {
                Log.d(TAG, "End time reached: $sampleTime > ${endMs * 1000L}")
                break
            }

            info.offset = 0
            info.size = sampleSize
            info.presentationTimeUs = sampleTime
            info.flags = extractor.sampleFlags
            muxer.writeSampleData(muxerTrackIndex, buffer, info)
            extractor.advance()
            samplesCount++
            
            if (samplesCount % 100 == 0) {
                Log.d(TAG, "Processed $samplesCount samples")
            }
        }

        Log.d(TAG, "Total samples processed: $samplesCount")
        muxer.stop()
        muxer.release()
        extractor.release()
        Log.d(TAG, "Audio cut completed")
    }

    private fun selectTrack(extractor: MediaExtractor): Int {
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME)
            Log.d(TAG, "Track $i mime type: $mime")
            if (mime?.startsWith("audio/") == true) {
                return i
            }
        }
        throw IllegalArgumentException("No audio track found in $extractor")
    }
}