import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/services/notification_service.dart';
import 'client_tabs/home_tab.dart';
import 'client_tabs/transactions_tab.dart';
import 'client_tabs/notifications_tab.dart';
import 'client_tabs/profile_tab.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  int _currentIndex = 0;
  String? _photoUrl;

  final List<Widget> _tabs = const [
    HomeTab(),
    TransactionsTab(),
    NotificationsTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  void _loadPhoto() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.photoURL != null) {
      setState(() => _photoUrl = user.photoURL);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _tabs[_currentIndex]),
      bottomNavigationBar: BottomAppBar(
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
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'Transactions',
                index: 1,
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
              _NotificationsNavItem(
                index: 2,
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
              // Profile tab — shows user's actual photo if signed in via
              // Google or Facebook, otherwise falls back to person icon
              _ProfileNavItem(
                photoUrl: _photoUrl,
                index: 3,
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

// ── Notifications nav item with live unread badge ─────────────────────────────

class _NotificationsNavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NotificationsNavItem({
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    final user = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with badge
          user == null
              ? Icon(
                  isSelected ? Icons.notifications : Icons.notifications_outlined,
                  color: isSelected ? AppColors.primary : AppColors.textLight,
                  size: 24,
                )
              : StreamBuilder<int>(
                  stream: NotificationService.unreadCountStream(user.uid),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.notifications
                              : Icons.notifications_outlined,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textLight,
                          size: 24,
                        ),
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
            'Notifications',
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

// ── Profile nav item — shows user photo when available ────────────────────────

class _ProfileNavItem extends StatelessWidget {
  final String? photoUrl;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _ProfileNavItem({
    required this.photoUrl,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;

    Widget avatar;
    if (photoUrl != null) {
      // Google / Facebook user — show their actual profile photo
      avatar = CircleAvatar(
        radius: 13,
        backgroundImage: NetworkImage(photoUrl!),
        // Gold ring when selected
        backgroundColor:
            isSelected ? AppColors.primary : Colors.transparent,
      );
    } else {
      // Email/password or guest — show person icon
      avatar = Icon(
        isSelected ? Icons.person : Icons.person_outline,
        color: isSelected ? AppColors.primary : AppColors.textLight,
        size: 24,
      );
    }

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gold ring around photo when selected
          if (photoUrl != null)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: avatar,
            )
          else
            avatar,
          const SizedBox(height: 2),
          Text(
            'Profile',
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
