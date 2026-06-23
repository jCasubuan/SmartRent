import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/rental_model.dart';
import 'package:smart_rent/screens/auth/landing_page.dart';
import 'package:smart_rent/screens/client/request_details_screen.dart';
import 'package:smart_rent/services/rental_service.dart';

/// Customer transactions tab — shows all rental requests grouped by status.
/// Tabs: Current (pending) | Approved | Declined (rejected + cancelled)
class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Guest — prompt to sign in
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'My Rental Requests',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 64, color: AppColors.border),
                const SizedBox(height: 16),
                const Text(
                  'Sign in to see your requests',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Once you sign in, all your rental requests will show up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMid,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LandingPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.defaultForeground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text(
                    'SIGN IN',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Rental Requests',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.defaultForeground,
          unselectedLabelColor: AppColors.textMid,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Approved'),
            Tab(text: 'Declined'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: StreamBuilder<List<RentalModel>>(
        stream: RentalService.customerRentalsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'We couldn\'t load your requests. Please check your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMid),
              ),
            );
          }

          final all = snapshot.data ?? [];
          final current =
              all.where((r) => r.status == 'pending').toList();
          final approved =
              all.where((r) => r.status == 'approved').toList();
          final declined = all
              .where((r) =>
                  r.status == 'rejected' || r.status == 'cancelled')
              .toList();
          final completed =
              all.where((r) => r.status == 'completed').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _RequestList(rentals: current,   emptyMessage: 'No pending requests yet.'),
              _RequestList(rentals: approved,  emptyMessage: 'No approved bookings yet.'),
              _RequestList(rentals: declined,  emptyMessage: 'No declined requests.'),
              _RequestList(rentals: completed, emptyMessage: 'No completed rentals yet.'),
            ],
          );
        },
      ),
    );
  }
}

// ── Request list ──────────────────────────────────────────────────────────────

class _RequestList extends StatelessWidget {
  final List<RentalModel> rentals;
  final String emptyMessage;

  const _RequestList({
    required this.rentals,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (rentals.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 14, color: AppColors.textLight),
        ),
      );
    }

    final grouped = _groupByDate(rentals);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final section = grouped[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Text(
                section.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            ...section.items.map((rental) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RequestCard(rental: rental),
                )),
          ],
        );
      },
    );
  }

  List<_DateGroup> _groupByDate(List<RentalModel> rentals) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<RentalModel>> map = {};
    final List<String> orderedKeys = [];

    for (final rental in rentals) {
      final dt = rental.createdAt;
      String label;
      if (dt == null) {
        label = 'Today';
      } else {
        final rentalDay = DateTime(dt.year, dt.month, dt.day);
        if (rentalDay == today) {
          label = 'Today';
        } else if (rentalDay == yesterday) {
          label = 'Yesterday';
        } else {
          label = _formatDateLabel(dt);
        }
      }

      if (!map.containsKey(label)) {
        map[label] = [];
        orderedKeys.add(label);
      }
      map[label]!.add(rental);
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
  final List<RentalModel> items;
  const _DateGroup({required this.label, required this.items});
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final RentalModel rental;

  const _RequestCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    final r = rental;
    final hasImage = r.gownImageUrl.isNotEmpty;
    final statusColor = AppColors.rentalStatusColor(r.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gown image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasImage
                  ? Image.network(
                      r.gownImageUrl,
                      width: 80,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            const SizedBox(width: 12),

            // Info + button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      AppColors.rentalStatusLabel(r.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Gown name
                  Text(
                    r.gownName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // View Details button
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RequestDetailsScreen(rental: r),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.defaultForeground,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 80,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.checkroom_outlined,
          color: AppColors.border, size: 28),
    );
  }
}
