import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';

/// A styled [TextFormField] used in admin gown forms (Add / Edit).
///
/// Differs from [InputField] in that the prefix icon is optional
/// and uses [AppColors.inputHint] for hint and icon colour.
class GownFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  const GownFormField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: TextStyle(fontSize: r.sp(14), color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.inputHint, fontSize: r.sp(14)),
        counterText: '',
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.inputHint, size: r.s(20))
            : null,
        contentPadding:
            EdgeInsets.symmetric(horizontal: r.s(16), vertical: r.s(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
