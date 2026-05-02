import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';

/// A small uppercase label used above form input fields.
class FieldLabel extends StatelessWidget {
  final String label;

  const FieldLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
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
}