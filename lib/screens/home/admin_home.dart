import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/widgets/in_app_notification_banner.dart';
import 'package:smart_rent/screens/admin/overdue/overdue_screen.dart';
import 'package:smart_rent/services/gown_service.dart';
import 'package:smart_rent/services/rental_service.dart';
import 'admin_tabs/dashboard_tab.dart';
import 'admin_tabs/inbox_tab.dart';
import 'admin_tabs/scanner_tab.dart';
import 'admin_tabs/reports_tab.dart';
import 'admin_tabs/admin_profile_tab.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;
  StreamSubscription? _pendingSub;
  int _lastPendingCount = -1;

  final List<Widget> _tabs = const [
    DashboardTab(),
    InboxTab(),
    ScannerTab(),
    ReportsTab(),
    AdminProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _listenForNewRequests();
    _checkOverdueItems();
  }

  @override
  void dispose() {
    _pendingSub?.cancel();
    super.dispose();
  }

  /// Checks for overdue rentals, cleaning, and repair gowns on app open.
  /// Shows a banner if any are found.
  Future<void> _checkOverdueItems() async {
    // Small delay to let the UI build first
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final now = DateTime.now();
    int overdueRentals = 0;
    int overdueCleaning = 0;
    int overdueRepair = 0;

    try {
      // Check overdue rentals
      final rentals = await RentalService.pickedUpRentalsStream().first;
      overdueRentals = rentals.where((r) => r.returnDate.isBefore(now)).length;

      // Check overdue cleaning
      final cleaningGowns = await GownService.getCleaningGownsWithDates();
      overdueCleaning = cleaningGowns.where((entry) {
        final expected = entry['cleaningExpectedDate'] as DateTime?;
        return expected != null && expected.isBefore(now);
      }).length;

      // Check overdue repair
      final repairGowns = await GownService.getRepairGownsWithDates();
      overdueRepair = repairGowns.where((entry) {
        final expected = entry['repairExpectedDate'] as DateTime?;
        return expected != null && expected.isBefore(now);
      }).length;
    } catch (e) {
      debugPrint('[AdminHome._checkOverdueItems] $e');
      return;
    }

    final total = overdueRentals + overdueCleaning + overdueRepair;
    if (total == 0 || !mounted) return;

    // Build message
    final parts = <String>[];
    if (overdueRentals > 0) {
      parts.add('$overdueRentals rental${overdueRentals > 1 ? 's' : ''}');
    }
    if (overdueCleaning > 0) {
      parts.add('$overdueCleaning cleaning');
    }
    if (overdueRepair > 0) {
      parts.add('$overdueRepair repair');
    }

    InAppNotificationBanner.show(
      context,
      title: 'Overdue Items',
      body: '${parts.join(', ')} past expected date. Tap to view.',
      icon: Icons.warning_amber_outlined,
      iconColor: AppColors.error,
      duration: const Duration(seconds: 5),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OverdueScreen(),
          ),
        );
      },
    );
  }

  /// Listens to pending rental requests stream and shows a banner when a new one arrives.
  void _listenForNewRequests() {
    _pendingSub = RentalService.pendingRequestsStream().listen(
      (requests) {
        final count = requests.length;

        // Skip initial load
        if (_lastPendingCount == -1) {
          _lastPendingCount = count;
          return;
        }

      if (count > _lastPendingCount && requests.isNotEmpty) {
        // Find the newest request (first in list, sorted newest-first)
        final latest = requests.first;

        if (mounted) {
          InAppNotificationBanner.show(
            context,
            title: 'New Rental Request',
            body: '${latest.customerName} wants to rent "${latest.gownName}"',
            icon: Icons.inbox_outlined,
            iconColor: AppColors.primary,
            onTap: () => setState(() => _currentIndex = 1), // Go to Inbox
          );
        }
      }

      _lastPendingCount = count;
    },
      onError: (e) {
        debugPrint('[AdminHome._listenForNewRequests] $e');
      },
    );
  }

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
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
              // Inbox with live badge count
              _InboxNavItem(
                index: 1,
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
              const SizedBox(width: 48), // space for FAB
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Reports',
                index: 3,
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 4,
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Standard nav item ─────────────────────────────────────────────────────────

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
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inbox nav item with live badge ────────────────────────────────────────────

class _InboxNavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _InboxNavItem({
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
          // Icon with badge
          StreamBuilder<int>(
            stream: RentalService.pendingCountStream(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? Icons.inbox : Icons.inbox_outlined,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textLight,
                    size: 24,
                  ),
                  // Badge — only shown when count > 0
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.defaultForeground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            'Inbox',
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
