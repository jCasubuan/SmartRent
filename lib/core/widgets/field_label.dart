import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';

/// A small uppercase label used above form input fields.
/// Set [isRequired] to true to show a red asterisk after the label.
class FieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const FieldLabel({super.key, required this.label, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    if (!isRequired) {
      return Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          letterSpacing: 0.8,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            letterSpacing: 0.8,
          ),
        ),
        const Text(
          ' *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}
