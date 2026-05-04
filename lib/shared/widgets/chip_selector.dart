import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';

class ChipOption<T> {
  const ChipOption({required this.value, required this.label});

  final T value;
  final String label;
}

class ChipSelector<T> extends StatelessWidget {
  const ChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<ChipOption<T>> options;
  final T? selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = option.value == selected;
        return InkWell(
          onTap: () => onChanged(option.value),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : context.appSurfaceAlt,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text(
              option.label,
              style: TextStyle(
                color: isSelected ? Colors.white : context.appTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
