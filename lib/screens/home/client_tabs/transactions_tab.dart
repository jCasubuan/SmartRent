import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/rental_model.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/core/widgets/cached_image.dart';
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
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final user = FirebaseAuth.instance.currentUser;

    // Guest — prompt to sign in
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'My Rental Requests',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: r.sp(18),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: r.s(40)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: r.s(64), color: AppColors.border),
                SizedBox(height: r.s(16)),
                Text(
                  'Sign in to see your requests',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: r.sp(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: r.s(8)),
                Text(
                  'Once you sign in, all your rental requests will show up here.',
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
                  child: Text(
                    'SIGN IN',
                    style: TextStyle(
                        fontSize: r.sp(15), fontWeight: FontWeight.w700),
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
        title: Text(
          'My Rental Requests',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: r.sp(18),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.defaultForeground,
          unselectedLabelColor: AppColors.textMid,
          labelStyle: TextStyle(
              fontWeight: FontWeight.w700, fontSize: r.sp(13)),
          unselectedLabelStyle: TextStyle(fontSize: r.sp(13)),
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelPadding: EdgeInsets.symmetric(horizontal: r.s(16)),
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Approved'),
            Tab(text: 'Ongoing'),
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
          final ongoing =
              all.where((r) => r.status == 'picked_up').toList();
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
              _RequestList(rentals: ongoing,   emptyMessage: 'No ongoing rentals.'),
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
    final r = Responsive(context);
    if (rentals.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(fontSize: r.sp(14), color: AppColors.textLight),
        ),
      );
    }

    final grouped = _groupByDate(rentals);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(r.s(16), r.s(16), r.s(16), r.s(24)),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final section = grouped[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: r.s(8), bottom: r.s(10)),
              child: Text(
                section.label,
                style: TextStyle(
                  fontSize: r.sp(13),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            ...section.items.map((rental) => Padding(
                  padding: EdgeInsets.only(bottom: r.s(12)),
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
    final resp = Responsive(context);
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
        padding: EdgeInsets.all(resp.s(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gown image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasImage
                  ? CachedImage(
                      imageUrl: r.gownImageUrl,
                      width: resp.s(80),
                      height: resp.s(90),
                      fit: BoxFit.cover,
                    )
                  : _placeholder(resp),
            ),

            SizedBox(width: resp.s(12)),

            // Info + button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: resp.s(10), vertical: resp.s(4)),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      AppColors.rentalStatusLabel(r.status),
                      style: TextStyle(
                        fontSize: resp.sp(11),
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  SizedBox(height: resp.s(6)),

                  // Gown name
                  Text(
                    r.gownName,
                    style: TextStyle(
                      fontSize: resp.sp(15),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: resp.s(10)),

                  // View Details button
                  SizedBox(
                    width: double.infinity,
                    height: resp.s(36),
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
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: resp.sp(13),
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

  Widget _placeholder(Responsive resp) {
    return Container(
      width: resp.s(80),
      height: resp.s(90),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.checkroom_outlined,
          color: AppColors.border, size: resp.s(28)),
    );
  }
}
