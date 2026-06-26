import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';

/// A square icon button used for social sign-in options (Google, Facebook).
class SocialIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;

  const SocialIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: r.s(56),
        height: r.s(56),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.background,
        ),
        child: Center(child: icon),
      ),
    );
  }
}
