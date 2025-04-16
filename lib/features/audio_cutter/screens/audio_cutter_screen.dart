import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/time_input_card.dart';
import '../widgets/cut_segment_list.dart';

class AudioCutterScreen extends ConsumerStatefulWidget {
  const AudioCutterScreen({super.key});

  @override
  ConsumerState<AudioCutterScreen> createState() => _AudioCutterScreenState();
}

class _AudioCutterScreenState extends ConsumerState<AudioCutterScreen> {
  String? selectedFilePath;
  List<TimeInputCard> timeInputs = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        selectedFilePath = result.files.single.path;
        // Add initial time input
        if (timeInputs.isEmpty) {
          _addNewTimeInput();
        }
      });
    }
  }

  void _addNewTimeInput() {
    setState(() {
      timeInputs.add(
        TimeInputCard(
          index: timeInputs.length,
          onRemove: _removeTimeInput,
          isLast: true,
          onAddNext: timeInputs.isEmpty ? _addNewTimeInput : null,
        ),
      );
      // Update the previous last card
      if (timeInputs.length > 1) {
        final previousIndex = timeInputs.length - 2;
        timeInputs[previousIndex] = TimeInputCard(
          index: previousIndex,
          onRemove: _removeTimeInput,
          isLast: false,
          onAddNext: null,
        );
      }
    });
  }

  void _removeTimeInput(int index) {
    setState(() {
      timeInputs.removeAt(index);
      // Update indices and isLast status
      for (int i = 0; i < timeInputs.length; i++) {
        timeInputs[i] = TimeInputCard(
          index: i,
          onRemove: _removeTimeInput,
          isLast: i == timeInputs.length - 1,
          onAddNext: i == timeInputs.length - 1 ? _addNewTimeInput : null,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Cutter'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Audio File',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.audio_file),
                        label: const Text('Choose File'),
                      ),
                      if (selectedFilePath != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Selected: ${selectedFilePath!.split('/').last}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: CutSegmentList(
                  timeInputs: timeInputs,
                ),
              ),
              if (selectedFilePath != null)
                FilledButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Implement cutting logic
                    }
                  },
                  icon: const Icon(Icons.cut),
                  label: const Text('Make Cuts'),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 