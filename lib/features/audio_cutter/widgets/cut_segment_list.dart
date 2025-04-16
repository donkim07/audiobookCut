import 'package:flutter/material.dart';
import 'time_input_card.dart';

class CutSegmentList extends StatelessWidget {
  final List<TimeInputCard> timeInputs;

  const CutSegmentList({
    super.key,
    required this.timeInputs,
  });

  @override
  Widget build(BuildContext context) {
    return timeInputs.isEmpty
        ? Center(
            child: Text(
              'Select an audio file to start adding cut segments',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
        : ListView.builder(
            itemCount: timeInputs.length,
            itemBuilder: (context, index) => timeInputs[index],
          );
  }
} 