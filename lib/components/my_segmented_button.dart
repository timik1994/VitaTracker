import 'package:flutter/material.dart';

class MySegmentedButton<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final void Function(T) onChanged;
  final String Function(T) label;
  final double? width;

  const MySegmentedButton({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.label,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.1,
        ),
      ),
      child: SegmentedButton<T>(
        segments: values.map((v) => ButtonSegment<T>(
          value: v,
          label: Text(label(v), overflow: TextOverflow.ellipsis),
        )).toList(),
        selected: {selected},
        onSelectionChanged: (Set<T> selectedSet) {
          if (selectedSet.isNotEmpty) {
            onChanged(selectedSet.first);
          }
        },
        style: ButtonStyle(
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          backgroundColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected)
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent),
        ),
      ),
    );
  }
} 