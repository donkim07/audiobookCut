import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimeInputCard extends StatefulWidget {
  final int index;
  final Function(int) onRemove;
  final bool isLast;
  final VoidCallback? onAddNext;
  final bool enabled;

  const TimeInputCard({
    super.key,
    required this.index,
    required this.onRemove,
    required this.isLast,
    this.onAddNext,
    this.enabled = true,
  });

  @override
  State<TimeInputCard> createState() => _TimeInputCardState();
}

class _TimeInputCardState extends State<TimeInputCard> {
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String get timeValue => _timeController.text;
  String get nameValue => _nameController.text;

  @override
  void dispose() {
    _timeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a time';
    }
    
    final parts = value.split(':');
    if (parts.length != 3) {
      return 'Use format HH:MM:SS';
    }

    try {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);

      if (hours < 0 || minutes < 0 || seconds < 0) {
        return 'Time cannot be negative';
      }
      if (minutes >= 60 || seconds >= 60) {
        return 'Invalid time format';
      }
    } catch (e) {
      return 'Invalid time format';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: widget.enabled ? 1.0 : 0.6,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Segment ${widget.index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (widget.index > 0)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: widget.enabled ? () => widget.onRemove(widget.index) : null,
                      color: Theme.of(context).colorScheme.error,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'Time (HH:MM:SS)',
                        border: OutlineInputBorder(),
                        helperText: 'Format: 00:00:00',
                      ),
                      enabled: widget.enabled,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
                        LengthLimitingTextInputFormatter(8),
                        _TimeInputFormatter(),
                      ],
                      validator: _validateTime,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Segment Name',
                        border: OutlineInputBorder(),
                      ),
                      enabled: widget.enabled,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
                          return 'Use only letters, numbers, - and _';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (widget.isLast && widget.onAddNext != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: IconButton.filled(
                    onPressed: widget.enabled ? widget.onAddNext : null,
                    icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.isEmpty) return newValue;
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 5) {
        if (text[i] != ':') buffer.write(':');
      }
      if (text[i] != ':') buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
} 