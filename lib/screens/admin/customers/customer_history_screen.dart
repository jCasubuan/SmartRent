import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/rental_model.dart';
import 'package:smart_rent/core/utils/price_formatter.dart';
import 'package:smart_rent/services/customer_service.dart';

/// Shows the rental history for a specific customer with three tabs:
/// Approved (approved/completed), Declined (rejected), and Cancelled.
class CustomerHistoryScreen extends StatefulWidget {
  final CustomerEntry customer;

  const CustomerHistoryScreen({super.key, required this.customer});

  @override
  State<CustomerHistoryScreen> createState() =>
      _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<RentalModel> _pendingRentals = [];
  List<RentalModel> _approvedRentals = [];
  List<RentalModel> _declinedRentals = [];
  List<RentalModel> _cancelledRentals = [];
  bool _pendingLoading = true;
  bool _approvedLoading = true;
  bool _declinedLoading = true;
  bool _cancelledLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPending();
    _loadApproved();
    _loadDeclined();
    _loadCancelled();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    final rentals = await CustomerService.getCustomerPendingHistory(
        widget.customer.customerId);
    if (mounted) {
      setState(() {
        _pendingRentals = rentals;
        _pendingLoading = false;
      });
    }
  }

  Future<void> _loadApproved() async {
    final rentals = await CustomerService.getCustomerApprovedHistory(
        widget.customer.customerId);
    if (mounted) {
      setState(() {
        _approvedRentals = rentals;
        _approvedLoading = false;
      });
    }
  }

  Future<void> _loadDeclined() async {
    final rentals = await CustomerService.getCustomerDeclinedHistory(
        widget.customer.customerId);
    if (mounted) {
      setState(() {
        _declinedRentals = rentals;
        _declinedLoading = false;
      });
    }
  }

  Future<void> _loadCancelled() async {
    final rentals = await CustomerService.getCustomerCancelledHistory(
        widget.customer.customerId);
    if (mounted) {
      setState(() {
        _cancelledRentals = rentals;
        _cancelledLoading = false;
      });
    }
  }

  // ── Group rentals by date ─────────────────────────────────────────────────

  List<_DateGroup> _grouped(List<RentalModel> rentals,
      {bool useCreatedAt = false}) {
    final Map<String, List<RentalModel>> map = {};

    for (final r in rentals) {
      final date = useCreatedAt ? r.createdAt : (r.approvedAt ?? r.createdAt);
      final label = date != null ? _dateLabel(date) : 'Unknown date';
      map.putIfAbsent(label, () => []).add(r);
    }

    return map.entries
        .map((e) => _DateGroup(label: e.key, rentals: e.value))
        .toList();
  }

  String _dateLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.customer.customerName,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Tabs ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.defaultForeground,
              unselectedLabelColor: AppColors.textMid,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(
                  text: _pendingLoading
                      ? 'Pending'
                      : 'Pending (${_pendingRentals.length})',
                ),
                Tab(
                  text: _approvedLoading
                      ? 'Approved'
                      : 'Approved (${_approvedRentals.length})',
                ),
                Tab(
                  text: _declinedLoading
                      ? 'Declined'
                      : 'Declined (${_declinedRentals.length})',
                ),
                Tab(
                  text: _cancelledLoading
                      ? 'Cancelled'
                      : 'Cancelled (${_cancelledRentals.length})',
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Tab content ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pending tab
                _buildRentalList(
                  isLoading: _pendingLoading,
                  rentals: _pendingRentals,
                  cardStyle: _CardStyle.pending,
                  emptyIcon: Icons.hourglass_empty_outlined,
                  emptyText:
                      'No pending requests for\n${widget.customer.customerName}.',
                ),

                // Approved tab
                _buildRentalList(
                  isLoading: _approvedLoading,
                  rentals: _approvedRentals,
                  cardStyle: _CardStyle.approved,
                  emptyIcon: Icons.receipt_long_outlined,
                  emptyText:
                      'No approved rentals for\n${widget.customer.customerName}.',
                ),

                // Declined tab
                _buildRentalList(
                  isLoading: _declinedLoading,
                  rentals: _declinedRentals,
                  cardStyle: _CardStyle.declined,
                  emptyIcon: Icons.cancel_outlined,
                  emptyText:
                      'No declined requests for\n${widget.customer.customerName}.',
                ),

                // Cancelled tab
                _buildRentalList(
                  isLoading: _cancelledLoading,
                  rentals: _cancelledRentals,
                  cardStyle: _CardStyle.cancelled,
                  emptyIcon: Icons.block_outlined,
                  emptyText:
                      'No cancelled requests for\n${widget.customer.customerName}.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalList({
    required bool isLoading,
    required List<RentalModel> rentals,
    required _CardStyle cardStyle,
    required IconData emptyIcon,
    required String emptyText,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (rentals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 52, color: AppColors.border),
            const SizedBox(height: 12),
            Text(
              emptyText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final useCreatedAt = cardStyle != _CardStyle.approved;
    final groups = _grouped(rentals, useCreatedAt: useCreatedAt);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Text(
                group.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                ),
              ),
            ),

            // Rental cards
            ...group.rentals.map(
              (rental) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RentalHistoryCard(
                  rental: rental,
                  cardStyle: cardStyle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Card style enum ───────────────────────────────────────────────────────────

enum _CardStyle { pending, approved, declined, cancelled }

// ── Date group model ──────────────────────────────────────────────────────────

class _DateGroup {
  final String label;
  final List<RentalModel> rentals;
  const _DateGroup({required this.label, required this.rentals});
}

// ── Rental history card ───────────────────────────────────────────────────────

class _RentalHistoryCard extends StatelessWidget {
  final RentalModel rental;
  final _CardStyle cardStyle;

  const _RentalHistoryCard({
    required this.rental,
    required this.cardStyle,
  });

  @override
  Widget build(BuildContext context) {
    final r = rental;
    final hasImage = r.gownImageUrl.isNotEmpty;

    // Style based on card type
    final Color borderColor;
    final Color cardBg;
    final Color gownNameColor;
    final Color detailColor;

    switch (cardStyle) {
      case _CardStyle.pending:
        borderColor = AppColors.rentalPending.withValues(alpha: 0.4);
        cardBg = AppColors.rentalPending.withValues(alpha: 0.03);
        gownNameColor = AppColors.rentalPending;
        detailColor = AppColors.textDark;
      case _CardStyle.declined:
        borderColor = AppColors.error.withValues(alpha: 0.4);
        cardBg = AppColors.error.withValues(alpha: 0.03);
        gownNameColor = AppColors.error;
        detailColor = AppColors.textDark;
      case _CardStyle.cancelled:
        borderColor = AppColors.rentalCancelled.withValues(alpha: 0.5);
        cardBg = AppColors.rentalCancelled.withValues(alpha: 0.04);
        gownNameColor = AppColors.textMid;
        detailColor = AppColors.textMid;
      case _CardStyle.approved:
        borderColor = AppColors.border;
        cardBg = AppColors.background;
        gownNameColor = AppColors.primary;
        detailColor = AppColors.primary;
    }

    final isHighlighted = cardStyle != _CardStyle.approved;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: borderColor, width: isHighlighted ? 1.5 : 1.0),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gown image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: hasImage
                      ? Image.network(
                          r.gownImageUrl,
                          width: 90,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),

                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        label: 'Gown:',
                        value: r.gownName,
                        valueColor: gownNameColor,
                      ),
                      const SizedBox(height: 6),
                      _DetailRow(
                        label: 'Category:',
                        value: r.gownCategory,
                        valueColor: detailColor,
                      ),
                      const SizedBox(height: 6),
                      _DetailRow(
                        label: 'Color:',
                        value: r.gownColor,
                        valueColor: detailColor,
                      ),
                      const SizedBox(height: 6),
                      _DetailRow(
                        label: 'Price:',
                        value: '₱${PriceFormatter.format(r.gownPrice)}',
                        valueColor: detailColor,
                      ),
                      const SizedBox(height: 8),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.rentalStatusColor(r.status)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.rentalStatusColor(r.status)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          AppColors.rentalStatusLabel(r.status),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rentalStatusColor(r.status),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Cancellation reason (only for cancelled cards)
            if (cardStyle == _CardStyle.cancelled &&
                r.cancellationReason != null &&
                r.cancellationReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${r.cancellationReason}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMid,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 90,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.checkroom_outlined,
          color: AppColors.border, size: 32),
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, height: 1.4),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
