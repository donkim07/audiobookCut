import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cut_segment.dart';
import '../services/audio_cutter_service.dart';

class AudioState {
  final String? selectedFilePath;
  final List<CutSegment> segments;
  final bool isProcessing;
  final double progress;
  final String? errorMessage;
  final String? successMessage;

  AudioState({
    this.selectedFilePath,
    this.segments = const [],
    this.isProcessing = false,
    this.progress = 0.0,
    this.errorMessage,
    this.successMessage,
  });

  AudioState copyWith({
    String? selectedFilePath,
    List<CutSegment>? segments,
    bool? isProcessing,
    double? progress,
    String? errorMessage,
    String? successMessage,
  }) {
    return AudioState(
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      segments: segments ?? this.segments,
      isProcessing: isProcessing ?? this.isProcessing,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class AudioStateNotifier extends StateNotifier<AudioState> {
  AudioStateNotifier() : super(AudioState());

  void setSelectedFile(String path) {
    state = state.copyWith(
      selectedFilePath: path,
      errorMessage: null,
      successMessage: null,
    );
  }

  void addSegment(CutSegment segment) {
    state = state.copyWith(
      segments: [...state.segments, segment],
      errorMessage: null,
    );
  }

  void removeSegment(int index) {
    final newSegments = [...state.segments];
    newSegments.removeAt(index);
    state = state.copyWith(
      segments: newSegments,
      errorMessage: null,
    );
  }

  void updateSegment(int index, CutSegment segment) {
    final newSegments = [...state.segments];
    newSegments[index] = segment;
    state = state.copyWith(segments: newSegments);
  }

  Future<void> processAudioCuts() async {
    if (state.selectedFilePath == null) {
      state = state.copyWith(
        errorMessage: 'No audio file selected',
        isProcessing: false,
      );
      return;
    }

    if (state.segments.isEmpty) {
      state = state.copyWith(
        errorMessage: 'No segments defined',
        isProcessing: false,
      );
      return;
    }

    state = state.copyWith(
      isProcessing: true,
      progress: 0.0,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final outputDir = await AudioCutterService.getOutputDirectory();
      final (success, message) = await AudioCutterService.cutAudio(
        inputPath: state.selectedFilePath!,
        segments: state.segments,
        outputDir: outputDir,
        onProgress: (progress) {
          state = state.copyWith(progress: progress);
        },
      );

      state = state.copyWith(
        isProcessing: false,
        progress: 1.0,
        errorMessage: success ? null : message,
        successMessage: success ? message : null,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Error: ${e.toString()}',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }
}

final audioStateProvider = StateNotifierProvider<AudioStateNotifier, AudioState>((ref) {
  return AudioStateNotifier();
}); 