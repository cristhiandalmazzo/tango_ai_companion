import 'package:flutter/material.dart';

class InterestsChips extends StatelessWidget {
  final List<String> allInterests;
  final List<String> selectedInterests;
  final ValueChanged<List<String>> onSelectionChanged;

  const InterestsChips({
    Key? key,
    required this.allInterests,
    required this.selectedInterests,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: allInterests.map((interest) {
        final isSelected = selectedInterests.contains(interest);
        return ChoiceChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (selected) {
            final newSelected = List<String>.from(selectedInterests);
            if (selected) {
              newSelected.add(interest);
            } else {
              newSelected.remove(interest);
            }
            onSelectionChanged(newSelected);
          },
        );
      }).toList(),
    );
  }
}
