import 'package:flutter/material.dart';

class MyDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String hint;
  final void Function(T?)? onChanged;
  final Widget Function(T) itemLabel;
  final EdgeInsetsGeometry? padding;

  const MyDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
    this.hint = '',
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          borderRadius: BorderRadius.circular(16),
          isExpanded: true,
          style: Theme.of(context).textTheme.bodyLarge,
          hint: hint.isNotEmpty ? Text(hint) : null,
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: itemLabel(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
} 