import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/smart_rent_logo.jpg',
              width: r.s(260),
              fit: BoxFit.contain,
            ),
            SizedBox(height: r.s(48)),
            SizedBox(
              width: r.s(24),
              height: r.s(24),
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(height: r.s(16)),
            Text(
              'Please wait...',
              style: TextStyle(
                fontSize: r.sp(13),
                color: AppColors.textMid,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}