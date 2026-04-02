import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';

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
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Admin Profile', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
    );
  }
}