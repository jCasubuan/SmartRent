import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Favorites', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
    );
  }
}

class CartTab extends StatelessWidget {
  const CartTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Cart', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
    );
  }
}

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Notifications', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile', style: TextStyle(fontSize: 18, color: AppColors.textLight)),
    );
  }
}