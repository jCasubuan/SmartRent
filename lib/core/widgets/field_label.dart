import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';

/// A small uppercase label used above form input fields.
/// Set [isRequired] to true to show a red asterisk after the label.
class FieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const FieldLabel({super.key, required this.label, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    if (!isRequired) {
      return Text(
        label,
        style: TextStyle(
          fontSize: r.sp(11),
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
          style: TextStyle(
            fontSize: r.sp(11),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            letterSpacing: 0.8,
          ),
        ),
        Text(
          ' *',
          style: TextStyle(
            fontSize: r.sp(12),
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}
