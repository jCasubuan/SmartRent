import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        '© 2026 SmartRent. All rights reserved.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textLight,
        ),
      ),
    );
  }
}