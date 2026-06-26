import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';

class ScannerTab extends StatelessWidget {
  const ScannerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Center(
      child: Text(
        'Scanner',
        style: TextStyle(fontSize: r.sp(18), color: AppColors.textLight),
      ),
    );
  }
}
