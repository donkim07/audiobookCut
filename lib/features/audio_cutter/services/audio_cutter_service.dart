import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import '../models/cut_segment.dart';

class AudioCutterService {
  static Future<String> getOutputDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${directory.path}/audio_cuts');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir.path;
  }

  static Future<(bool, String)> cutAudio({
    required String inputPath,
    required List<CutSegment> segments,
    required String outputDir,
    required Function(double) onProgress,
  }) async {
    try {
      for (int i = 0; i < segments.length; i++) {
        final segment = segments[i];
        final startTime = _calculateStartTime(segments, i);
        final duration = segment.duration;
        
        final outputPath = '$outputDir/${segment.name}.mp3';
        
        // Build FFmpeg command
        final command = '-i "$inputPath" -ss $startTime -t ${duration.inSeconds} '
            '-c:a libmp3lame -q:a 2 "$outputPath"';

        final session = await FFmpegKit.execute(command);
        final returnCode = await session.getReturnCode();

        if (!ReturnCode.isSuccess(returnCode)) {
          return (false, 'Failed to cut segment ${segment.name}');
        }

        // Update progress
        onProgress((i + 1) / segments.length);
      }
      return (true, 'Successfully cut all segments');
    } catch (e) {
      return (false, 'Error: ${e.toString()}');
    }
  }

  static String _calculateStartTime(List<CutSegment> segments, int currentIndex) {
    Duration totalDuration = Duration.zero;
    for (int i = 0; i < currentIndex; i++) {
      totalDuration += segments[i].duration;
    }
    return _formatDuration(totalDuration);
  }

  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
} 