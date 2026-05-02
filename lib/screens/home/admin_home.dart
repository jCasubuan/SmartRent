import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'admin_tabs/dashboard_tab.dart';
import 'admin_tabs/admin_dummy_tabs.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DashboardTab(),
    InboxTab(),
    ScannerTab(),
    ReportsTab(),
    AdminProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: SafeArea(child: _tabs[_currentIndex]),
      floatingActionButton: GestureDetector(
        onTap: () => setState(() => _currentIndex = 2),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt,
            color: AppColors.defaultForeground,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.background,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', index: 0, currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
              _NavItem(icon: Icons.inbox_outlined, activeIcon: Icons.inbox, label: 'Inbox', index: 1, currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
              const SizedBox(width: 48), // space for FAB
              _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Reports', index: 3, currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
              _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', index: 4, currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.primary : AppColors.textLight,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}