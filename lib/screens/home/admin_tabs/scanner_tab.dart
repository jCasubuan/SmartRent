import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';

class ScannerTab extends StatelessWidget {
  const ScannerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Scanner',
        style: TextStyle(fontSize: 18, color: AppColors.textLight),
      ),
    );
  }
}
