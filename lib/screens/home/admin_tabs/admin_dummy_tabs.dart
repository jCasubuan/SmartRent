import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/utils/logout_helper.dart';

class InboxTab extends StatelessWidget {
  const InboxTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Inbox', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
    );
  }
}

class ScannerTab extends StatelessWidget {
  const ScannerTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Scanner', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
    );
  }
}

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Reports', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
    );
  }
}

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

  Future<void> _handleLogout(BuildContext context) =>
      LogoutHelper.logout(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Admin profile image
            Center(
              child: Image.asset(
                'assets/icons/profile.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 16),

            // Admin label
            const Text(
              'Admin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),

            const Spacer(),

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => _handleLogout(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'LOG OUT',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}