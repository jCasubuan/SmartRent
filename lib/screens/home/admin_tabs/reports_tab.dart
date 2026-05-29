import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Reports',
        style: TextStyle(fontSize: 18, color: AppColors.textLight),
      ),
    );
  }
}
