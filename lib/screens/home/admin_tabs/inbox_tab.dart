import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/models/rental_model.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/screens/admin/cleaning/cleaning_screen.dart';
import 'package:smart_rent/screens/admin/gowns/gown_detail_screen.dart';
import 'package:smart_rent/screens/admin/overdue/overdue_screen.dart';
import 'package:smart_rent/screens/admin/repair/repair_screen.dart';
import 'package:smart_rent/services/admin_log_service.dart';
import 'package:smart_rent/services/rental_service.dart';

/// Admin inbox — three tabs:
///   Notifications — read-only audit log of all activity
///   Pending       — new requests waiting for approve / decline
///   Active        — approved rentals waiting to be picked up
class InboxTab extends StatefulWidget {
  const InboxTab({super.key});

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceGrey,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Inbox',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: r.sp(18),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.defaultForeground,
          unselectedLabelColor: AppColors.textMid,
          labelStyle:
              TextStyle(fontWeight: FontWeight.w700, fontSize: r.sp(13)),
          unselectedLabelStyle: TextStyle(fontSize: r.sp(13)),
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Notifications'),
            Tab(text: 'Pending'),
            Tab(text: 'Awaiting Pickup'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NotificationsList(tabController: _tabController),
          const _PendingList(),
          const _ActiveList(),
        ],
      ),
    );
  }
}

// ── Notifications list (audit log) ────────────────────────────────────────────

class _NotificationsList extends StatelessWidget {
  final TabController tabController;

  const _NotificationsList({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminLogService.logsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return _errorView();
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return _emptyView(
            icon: Icons.notifications_outlined,
            title: 'No activity yet',
            subtitle: 'Actions and events will be logged here.',
          );
        }

        // Group logs by date section
        final items = _buildGroupedItems(logs);

        // Check if there are any unread
        final hasUnread = logs.any(
            (n) => (n['isRead'] as bool? ?? true) == false);

        return Column(
          children: [
            // Mark all as read button — only show when unread exist
            if (hasUnread)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => AdminLogService.markAllRead(),
                      child: const Text(
                        'Mark all as read',
                        style: TextStyle(
                          fontSize: 12,
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item is String) {
                    // Date header
                    return Padding(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 0 : 16,
                        bottom: 8,
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                        ),
                      ),
                    );
                  }
                  // Notification card
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _NotificationCard(
                        log: item as Map<String, dynamic>,
                        tabController: tabController),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Groups logs by date and inserts string headers between sections.
  /// Returns a mixed list: String (header) or Map<String, dynamic> (log entry).
  List<dynamic> _buildGroupedItems(List<Map<String, dynamic>> logs) {
    final List<dynamic> items = [];
    String? lastDateLabel;

    for (final log in logs) {
      final createdAt = (log['createdAt'] as Timestamp?)?.toDate();
      final dateLabel = _dateSectionLabel(createdAt);

      if (dateLabel != lastDateLabel) {
        items.add(dateLabel);
        lastDateLabel = dateLabel;
      }
      items.add(log);
    }

    return items;
  }

  /// Returns a human-friendly date section label.
  String _dateSectionLabel(DateTime? date) {
    if (date == null) return 'Just now';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDay = DateTime(date.year, date.month, date.day);

    final diff = today.difference(logDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${diff} days ago';

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ── Notification card ─────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final TabController tabController;
  const _NotificationCard({required this.log, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final id = log['id'] as String? ?? '';
    final type = log['type'] as String? ?? '';
    final title = log['title'] as String? ?? '';
    final body = log['body'] as String? ?? '';
    final isRead = log['isRead'] as bool? ?? false;
    final targetType = log['targetType'] as String?;
    final targetId = log['targetId'] as String?;
    final createdAt = (log['createdAt'] as Timestamp?)?.toDate();

    return GestureDetector(
      onTap: () {
        // Mark as read on tap
        if (!isRead) AdminLogService.markRead(id);
        // Navigate to target
        _navigateToTarget(context, targetType, targetId);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? AppColors.background
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: isRead
              ? null
              : Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _iconColor(type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon(type), color: _iconColor(type), size: 18),
            ),
            const SizedBox(width: 12),
            // Content
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
                            fontSize: 13,
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMid,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 3-dot menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AppColors.textLight, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onSelected: (action) {
                if (action == 'read') {
                  AdminLogService.markRead(id);
                } else if (action == 'delete') {
                  AdminLogService.deleteLog(id);
                }
              },
              itemBuilder: (_) => [
                if (!isRead)
                  const PopupMenuItem(
                    value: 'read',
                    child: Row(
                      children: [
                        Icon(Icons.done, size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Mark as read',
                            style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 16, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete',
                          style:
                              TextStyle(fontSize: 13, color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTarget(
      BuildContext context, String? targetType, String? targetId) {
    if (targetType == null || targetId == null || targetId.isEmpty) return;

    final type = log['type'] as String? ?? '';

    switch (targetType) {
      case 'gown':
        FirebaseFirestore.instance
            .collection('gowns')
            .doc(targetId)
            .get()
            .then((doc) {
          if (doc.exists && context.mounted) {
            final gown = GownModel.fromFirestore(doc);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GownDetailScreen(gown: gown),
              ),
            );
          } else if (context.mounted) {
            _showGone(context);
          }
        });
        break;
      case 'cleaning':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CleaningScreen()),
        );
        break;
      case 'repair':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RepairScreen()),
        );
        break;
      case 'overdue':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OverdueScreen()),
        );
        break;
      case 'rental':
        // Rental request → switch to Pending tab (index 1)
        // Approved/picked up → switch to Awaiting Pickup tab (index 2)
        if (type == AdminLogType.rentalRequested) {
          tabController.animateTo(1);
        } else if (type == AdminLogType.rentalApproved ||
            type == AdminLogType.rentalPickedUp) {
          tabController.animateTo(2);
        } else {
          // For completed, rejected, no-show, cancelled — go to gown detail
          FirebaseFirestore.instance
              .collection('gowns')
              .doc(targetId)
              .get()
              .then((doc) {
            if (doc.exists && context.mounted) {
              final gown = GownModel.fromFirestore(doc);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GownDetailScreen(gown: gown),
                ),
              );
            } else if (context.mounted) {
              _showGone(context);
            }
          });
        }
        break;
    }
  }

  void _showGone(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This item no longer exists'),
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  IconData _icon(String type) {
    return switch (type) {
      'rental_requested' => Icons.inbox_outlined,
      'rental_approved' => Icons.check_circle_outline,
      'rental_rejected' => Icons.cancel_outlined,
      'rental_picked_up' => Icons.shopping_bag_outlined,
      'rental_completed' => Icons.assignment_turned_in_outlined,
      'rental_no_show' => Icons.person_off_outlined,
      'rental_cancelled' => Icons.block_outlined,
      'gown_added' => Icons.add_circle_outline,
      'gown_edited' => Icons.edit_outlined,
      'gown_deleted' => Icons.delete_outline,
      'gown_sent_cleaning' => Icons.local_laundry_service_outlined,
      'gown_marked_clean' => Icons.check_circle_outline,
      'gown_sent_repair' => Icons.build_outlined,
      'gown_repair_done' => Icons.check_circle_outline,
      'rental_overdue' || 'cleaning_overdue' || 'repair_overdue' =>
        Icons.warning_amber_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  Color _iconColor(String type) {
    return switch (type) {
      'rental_requested' => AppColors.primary,
      'rental_approved' || 'rental_picked_up' => AppColors.rentalApproved,
      'rental_rejected' || 'rental_no_show' || 'rental_cancelled' =>
        AppColors.error,
      'rental_completed' || 'gown_marked_clean' || 'gown_repair_done' =>
        AppColors.rentalCompleted,
      'gown_added' => AppColors.primary,
      'gown_edited' => AppColors.statusCleaning,
      'gown_deleted' => AppColors.error,
      'gown_sent_cleaning' => AppColors.statusCleaning,
      'gown_sent_repair' => AppColors.statusRepair,
      'rental_overdue' || 'cleaning_overdue' || 'repair_overdue' =>
        AppColors.error,
      _ => AppColors.textMid,
    };
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.month}/${date.day}/${date.year}';
  }
}

// ── Pending list ──────────────────────────────────────────────────────────────

class _PendingList extends StatelessWidget {
  const _PendingList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RentalModel>>(
      stream: RentalService.pendingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return _errorView();
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _emptyView(
            icon: Icons.inbox_outlined,
            title: 'No pending requests',
            subtitle: 'New rental requests will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _PendingCard(rental: requests[index]),
        );
      },
    );
  }
}

// ── Active list ───────────────────────────────────────────────────────────────

class _ActiveList extends StatelessWidget {
  const _ActiveList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RentalModel>>(
      stream: RentalService.approvedRentalsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return _errorView();
        }

        final rentals = snapshot.data ?? [];
        if (rentals.isEmpty) {
          return _emptyView(
            icon: Icons.schedule_outlined,
            title: 'No awaiting pickups',
            subtitle: 'Approved rentals awaiting customer pickup will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: rentals.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _ActiveCard(rental: rentals[index]),
        );
      },
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _errorView() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.border),
          SizedBox(height: 12),
          Text(
            'No notifications yet.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'New updates and alerts will appear here.',
            style: TextStyle(fontSize: 13, color: AppColors.textMid),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Widget _emptyView({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 52, color: AppColors.border),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textMid),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime date) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

// ── Pending card ──────────────────────────────────────────────────────────────

class _PendingCard extends StatefulWidget {
  final RentalModel rental;
  const _PendingCard({required this.rental});

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  bool _isProcessing = false;

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    final success = await RentalService.approveRequest(
      widget.rental.id,
      widget.rental.gownId,
    );
    if (mounted) {
      setState(() => _isProcessing = false);
      if (!success) _showError('Failed to approve. Please try again.');
    }
  }

  Future<void> _decline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Decline Request',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Decline the rental request for "${widget.rental.gownName}" '
          'by ${widget.rental.customerName}?',
          style: const TextStyle(fontSize: 14, height: 1.5),
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
              'Decline',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    final success = await RentalService.rejectRequest(widget.rental.id);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (!success) _showError('Failed to decline. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rental;
    final hasImage = r.gownImageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Gown image with PENDING badge ────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: hasImage
                        ? Image.network(
                            r.gownImageUrl,
                            width: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'PENDING',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.defaultForeground,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // ── Details + buttons ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.gownName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customer: ${r.customerName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pick up:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(r.pickupDate),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Return:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(r.returnDate),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(height: 12),
                    _isProcessing
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _approve,
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text(
                                    'Approve',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor:
                                        AppColors.defaultForeground,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(22),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _decline,
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text(
                                    'Decline',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(
                                        color: AppColors.error, width: 1.5),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(22),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.checkroom_outlined,
        color: AppColors.border,
        size: 32,
      ),
    );
  }
}

// ── Active card ───────────────────────────────────────────────────────────────

class _ActiveCard extends StatefulWidget {
  final RentalModel rental;
  const _ActiveCard({required this.rental});

  @override
  State<_ActiveCard> createState() => _ActiveCardState();
}

class _ActiveCardState extends State<_ActiveCard> {
  bool _isProcessing = false;

  Future<void> _confirmPickup() async {
    final r = widget.rental;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Pickup',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          '${r.customerName} has arrived to pick up "${r.gownName}"?\n\n'
          'This will mark the gown as rented out.',
          style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMid, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rentalApproved,
              foregroundColor: AppColors.defaultForeground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    final success = await RentalService.confirmPickup(r.id, r.gownId);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${r.gownName}" picked up by ${r.customerName}.'),
          backgroundColor: AppColors.rentalApproved,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      } else {
        _showError('Failed to confirm pickup. Please try again.');
      }
    }
  }

  Future<void> _markNoShow() async {
    final r = widget.rental;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: AppColors.rentalNoShow, size: 20),
            SizedBox(width: 8),
            Text('Mark as No-show',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          '${r.customerName} didn\'t come to pick up "${r.gownName}"?\n\n'
          'This will cancel the booking and the gown will remain available for others.',
          style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMid, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rentalNoShow,
              foregroundColor: AppColors.defaultForeground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm No-show',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    final success = await RentalService.markNoShow(r.id);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${r.gownName}" marked as no-show.'),
          backgroundColor: AppColors.rentalNoShow,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      } else {
        _showError('Failed to update. Please try again.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rental;
    final hasImage = r.gownImageUrl.isNotEmpty;

    // Highlight if pickup date has passed (customer is late)
    final isLate = r.pickupDate.isBefore(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: isLate
            ? Border.all(color: AppColors.rentalNoShow.withValues(alpha: 0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gown image with badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: hasImage
                        ? Image.network(r.gownImageUrl,
                            width: 100, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder())
                        : _imagePlaceholder(),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isLate
                            ? AppColors.rentalNoShow
                            : AppColors.rentalApproved,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(10)),
                      ),
                      child: Text(
                        isLate ? 'LATE PICKUP' : 'AWAITING',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.defaultForeground,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Details + buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.gownName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Customer: ${r.customerName}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMid,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pick up:',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(_formatDate(r.pickupDate),
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isLate
                                          ? AppColors.rentalNoShow
                                          : AppColors.textDark)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Return:',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(_formatDate(r.returnDate),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(height: 12),
                    _isProcessing
                        ? const Center(
                            child: SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primary)))
                        : Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _confirmPickup,
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Picked Up',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.rentalApproved,
                                    foregroundColor: AppColors.defaultForeground,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _markNoShow,
                                  icon: const Icon(Icons.person_off_outlined, size: 16),
                                  label: const Text('No-show',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.rentalNoShow,
                                    side: const BorderSide(
                                        color: AppColors.rentalNoShow, width: 1.5),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.checkroom_outlined,
          color: AppColors.border, size: 32),
    );
  }
}


