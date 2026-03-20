import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_rent/core/constants/app_colors.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String? _adminName;

  // Hardcoded stats — swap with Firestore fetch in future sprint
  final Map<String, dynamic> _stats = {
    'total': 45,
    'customer': 120,
    'overdue': 3,
    'cleaning': 8,
    'rented': 25,
  };

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _adminName = doc.data()?['name']?.toString().split(' ').first;
        });
      }
    } catch (_) {}
  }

  Future<void> _onRefresh() async {
    await _loadAdminName();
    // TODO: re-fetch stats from Firestore in future sprint
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Hello, ${_adminName ?? 'Admin'}!',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 24),

            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                // Total Gowns
                _StatCard(
                  label: 'TOTAL',
                  value: _stats['total'].toString(),
                  icon: const _IconPlaceholder(),
                  onTap: () {
                    // TODO: navigate to full inventory
                  },
                ),

                // Customers
                _StatCard(
                  label: 'CUSTOMER',
                  value: _stats['customer'].toString(),
                  icon: const _IconPlaceholder(),
                  onTap: () {
                    // TODO: navigate to customers list
                  },
                ),

                // Overdue
                _StatCard(
                  label: 'OVERDUE',
                  value: _stats['overdue'].toString(),
                  icon: const _IconPlaceholder(),
                  onTap: () {
                    // TODO: navigate to overdue list
                  },
                ),

                // Cleaning
                _StatCard(
                  label: 'CLEANING',
                  value: _stats['cleaning'].toString(),
                  icon: const _IconPlaceholder(),
                  onTap: () {
                    // TODO: navigate to cleaning list
                  },
                ),

                // Rented
                _StatCard(
                  label: 'RENTED',
                  value: _stats['rented'].toString(),
                  icon: const _IconPlaceholder(),
                  onTap: () {
                    // TODO: navigate to rented list
                  },
                ),

                // Add Gown
                _StatCard(
                  label: 'ADD\nGOWN',
                  value: '',
                  icon: const _IconPlaceholder(),
                  isAction: true,
                  onTap: () {
                    // TODO: navigate to add gown screen
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Stat card widget
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;
  final VoidCallback onTap;
  final bool isAction;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon placeholder
            icon,

            const SizedBox(height: 8),

            // Label
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
                letterSpacing: 0.8,
              ),
            ),

            // Value (hidden for action cards)
            if (!isAction) ...[
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Icon placeholder — replace with Image.asset once icons are ready
class _IconPlaceholder extends StatelessWidget {
  const _IconPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}