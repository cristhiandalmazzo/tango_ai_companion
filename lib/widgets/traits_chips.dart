import 'package:flutter/material.dart';

class TraitsChips extends StatelessWidget {
  final List<String> allTraits;
  final List<String> selectedTraits;
  final ValueChanged<List<String>> onSelectionChanged;

  const TraitsChips({
    Key? key,
    required this.allTraits,
    required this.selectedTraits,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: allTraits.map((trait) {
        final isSelected = selectedTraits.contains(trait);
        return ChoiceChip(
          label: Text(trait),
          selected: isSelected,
          onSelected: (selected) {
            final newSelected = List<String>.from(selectedTraits);
            if (selected) {
              newSelected.add(trait);
            } else {
              newSelected.remove(trait);
            }
            onSelectionChanged(newSelected);
          },
        );
      }).toList(),
    );
  }
}
