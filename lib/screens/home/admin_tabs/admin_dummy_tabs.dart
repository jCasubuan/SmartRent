import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';

class InventoryTab extends StatelessWidget {
  const InventoryTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Inventory', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
    );
  }
}

class TransactionsTab extends StatelessWidget {
  const TransactionsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Transactions', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
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

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Admin Profile', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
    );
  }
}