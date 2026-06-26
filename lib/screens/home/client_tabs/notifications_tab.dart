import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/rental_model.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/screens/auth/landing_page.dart';
import 'package:smart_rent/screens/client/request_details_screen.dart';
import 'package:smart_rent/services/notification_service.dart';

/// Customer notifications tab — shows in-app notifications written by admin
/// actions (approve, decline, complete). Grouped by date (Today, Yesterday,
/// then actual dates). Each notification has a 3-dot menu for deletion.
class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final user = FirebaseAuth.instance.currentUser;

    // ── Guest ──────────────────────────────────────────────────────────────
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _appBar(r),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: r.s(40)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: r.s(64), color: AppColors.border),
                SizedBox(height: r.s(16)),
                Text(
                  'Sign in to see your notifications',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: r.sp(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: r.s(8)),
                Text(
                  'We\'ll let you know here when your booking is confirmed or if there are any updates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: r.sp(13),
                    color: AppColors.textMid,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: r.s(28)),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LandingPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.defaultForeground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Text(
                    'SIGN IN',
                    style:
                        TextStyle(fontSize: r.sp(15), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Logged in ──────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(r),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService.notificationsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'We couldn\'t load your notifications. Please check your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMid),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: r.s(64), color: AppColors.border),
                  SizedBox(height: r.s(16)),
                  Text(
                    'Nothing here yet',
                    style: TextStyle(
                      fontSize: r.sp(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: r.s(8)),
                  Text(
                    'When the shop confirms or updates\nyour booking, you\'ll see it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: r.sp(13),
                      color: AppColors.textMid,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group notifications by date
          final grouped = _groupByDate(notifications);

          // Check if there are any unread
          final hasUnread = notifications.any(
              (n) => (n['isRead'] as bool? ?? true) == false);

          return Column(
            children: [
              // Mark all as read button
              if (hasUnread)
                Padding(
                  padding: EdgeInsets.fromLTRB(r.s(16), r.s(12), r.s(16), 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            NotificationService.markAllRead(user.uid),
                        child: Text(
                          'Mark all as read',
                          style: TextStyle(
                            fontSize: r.sp(12),
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(r.s(16), r.s(12), r.s(16), r.s(24)),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final section = grouped[index];
                    return _DateSection(
                      label: section.label,
                      notifications: section.items,
                      customerId: user.uid,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _appBar(Responsive r) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Notifications',
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
          fontSize: r.sp(18),
        ),
      ),
    );
  }

  /// Groups notifications by date label (Today, Yesterday, or "Mon DD, YYYY").
  List<_DateGroup> _groupByDate(List<Map<String, dynamic>> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Map<String, dynamic>>> map = {};
    final List<String> orderedKeys = [];

    for (final notif in notifications) {
      final ts = notif['createdAt'];
      DateTime? dt;
      if (ts != null) {
        try {
          dt = (ts as Timestamp).toDate();
        } catch (_) {}
      }

      String label;
      if (dt == null) {
        label = 'Today';
      } else {
        final notifDay = DateTime(dt.year, dt.month, dt.day);
        if (notifDay == today) {
          label = 'Today';
        } else if (notifDay == yesterday) {
          label = 'Yesterday';
        } else {
          label = _formatDateLabel(dt);
        }
      }

      if (!map.containsKey(label)) {
        map[label] = [];
        orderedKeys.add(label);
      }
      map[label]!.add(notif);
    }

    return orderedKeys
        .map((key) => _DateGroup(label: key, items: map[key]!))
        .toList();
  }

  String _formatDateLabel(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Date group model ──────────────────────────────────────────────────────────

class _DateGroup {
  final String label;
  final List<Map<String, dynamic>> items;
  const _DateGroup({required this.label, required this.items});
}

// ── Date section widget ───────────────────────────────────────────────────────

class _DateSection extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> notifications;
  final String customerId;

  const _DateSection({
    required this.label,
    required this.notifications,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: r.s(8), bottom: r.s(10)),
          child: Text(
            label,
            style: TextStyle(
              fontSize: r.sp(13),
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ...notifications.map((notif) => Padding(
              padding: EdgeInsets.only(bottom: r.s(8)),
              child: _NotificationCard(
                notif: notif,
                customerId: customerId,
              ),
            )),
      ],
    );
  }
}

// ── Notification card ─────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notif;
  final String customerId;

  const _NotificationCard({
    required this.notif,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final type = notif['type'] as String? ?? 'approved';
    final title = notif['title'] as String? ?? '';
    final body = notif['body'] as String? ?? '';
    final isRead = notif['isRead'] as bool? ?? true;
    final notifId = notif['id'] as String? ?? '';
    final rentalId = notif['rentalId'] as String? ?? '';

    final createdAt = notif['createdAt'];
    final timeStr = _formatTime(createdAt);

    final iconData = _iconForType(type);
    final iconColor = _colorForType(type);

    return GestureDetector(
      onTap: () {
        // Mark as read on tap
        if (!isRead && notifId.isNotEmpty) {
          NotificationService.markRead(customerId, notifId);
        }
        // Navigate to the rental request details
        _navigateToRental(context, rentalId);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isRead
              ? AppColors.background
              : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? AppColors.border
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(r.s(14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: r.s(44),
                height: r.s(44),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: r.s(22)),
              ),

              SizedBox(width: r.s(12)),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: r.sp(14),
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: r.s(8),
                            height: r.s(8),
                            margin: EdgeInsets.only(right: r.s(4)),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: r.s(4)),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: r.sp(13),
                        color: AppColors.textMid,
                        height: 1.4,
                      ),
                    ),
                    if (timeStr.isNotEmpty) ...[
                      SizedBox(height: r.s(6)),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: r.sp(11),
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 3-dot menu
              _MoreMenu(
                isRead: isRead,
                onMarkRead: () {
                  if (notifId.isNotEmpty) {
                    NotificationService.markRead(customerId, notifId);
                  }
                },
                onDelete: () => _handleDelete(context, notifId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRental(BuildContext context, String rentalId) {
    if (rentalId.isEmpty) return;

    FirebaseFirestore.instance
        .collection('rentals')
        .doc(rentalId)
        .get()
        .then((doc) {
      if (doc.exists && context.mounted) {
        final rental = RentalModel.fromFirestore(doc);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailsScreen(rental: rental),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('This request no longer exists'),
            backgroundColor: AppColors.textDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });
  }

  void _handleDelete(BuildContext context, String notifId) async {
    if (notifId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Notification',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: const Text(
          'Are you sure you want to delete this notification?',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                  color: AppColors.textMid, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.defaultForeground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success =
        await NotificationService.deleteNotification(customerId, notifId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Notification deleted'
                : 'Failed to delete. Please try again.',
          ),
          backgroundColor: success ? AppColors.textDark : AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'approved'  => Icons.check_circle_outline,
      'rejected'  => Icons.cancel_outlined,
      'completed' => Icons.assignment_turned_in_outlined,
      'overdue'   => Icons.warning_amber_outlined,
      _           => Icons.notifications_outlined,
    };
  }

  Color _colorForType(String type) {
    return switch (type) {
      'approved'  => AppColors.rentalApproved,
      'rejected'  => AppColors.rentalDeclined,
      'completed' => AppColors.rentalCompleted,
      'overdue'   => AppColors.error,
      _           => AppColors.primary,
    };
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';

      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min $amPm';
    } catch (_) {
      return '';
    }
  }
}

// ── 3-dot menu button ─────────────────────────────────────────────────────────

class _MoreMenu extends StatelessWidget {
  final bool isRead;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _MoreMenu({
    required this.isRead,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'read') onMarkRead();
        if (value == 'delete') onDelete();
      },
      icon: Icon(
        Icons.more_vert,
        color: AppColors.textLight,
        size: r.s(20),
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: r.s(28), minHeight: r.s(28)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        if (!isRead)
          PopupMenuItem<String>(
            value: 'read',
            child: Row(
              children: [
                Icon(Icons.done, size: r.s(18), color: AppColors.primary),
                SizedBox(width: r.s(8)),
                Text(
                  'Mark as read',
                  style: TextStyle(fontSize: r.sp(13)),
                ),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: r.s(18), color: AppColors.error),
              SizedBox(width: r.s(8)),
              Text(
                'Delete',
                style: TextStyle(fontSize: r.sp(13), color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
