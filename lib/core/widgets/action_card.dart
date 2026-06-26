import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';

class ActionCard extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(height: r.s(8)),
            Text(
              label,
              style: TextStyle(
                fontSize: r.sp(15),
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}