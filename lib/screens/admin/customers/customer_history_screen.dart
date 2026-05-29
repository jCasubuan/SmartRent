import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/rental_model.dart';
import 'package:smart_rent/core/utils/price_formatter.dart';
import 'package:smart_rent/services/customer_service.dart';

/// Shows the full rental history for a specific customer.
/// Rentals are grouped by the date they were approved, newest group first.
class CustomerHistoryScreen extends StatefulWidget {
  final CustomerEntry customer;

  const CustomerHistoryScreen({super.key, required this.customer});

  @override
  State<CustomerHistoryScreen> createState() =>
      _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  List<RentalModel> _rentals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rentals = await CustomerService.getCustomerHistory(
        widget.customer.customerId);
    if (mounted) {
      setState(() {
        _rentals = rentals;
        _isLoading = false;
      });
    }
  }

  // ── Group rentals by date ─────────────────────────────────────────────────

  /// Returns a list of [_DateGroup] — each group has a date label and its rentals.
  List<_DateGroup> get _grouped {
    final Map<String, List<RentalModel>> map = {};

    for (final r in _rentals) {
      final date = r.approvedAt ?? r.createdAt;
      final label = date != null ? _dateLabel(date) : 'Unknown date';
      map.putIfAbsent(label, () => []).add(r);
    }

    // Preserve insertion order (already sorted newest-first from service).
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
        title: const Text(
          'Customer History',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _rentals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 52, color: AppColors.border),
                      const SizedBox(height: 12),
                      Text(
                        'No rental history for\n${widget.customer.customerName}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _grouped.length,
                  itemBuilder: (context, index) {
                    final group = _grouped[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 8, bottom: 10),
                          child: Text(
                            group.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),

                        // Rental cards for this date
                        ...group.rentals.map(
                          (rental) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RentalHistoryCard(rental: rental),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}

// ── Date group model ──────────────────────────────────────────────────────────

class _DateGroup {
  final String label;
  final List<RentalModel> rentals;
  const _DateGroup({required this.label, required this.rentals});
}

// ── Rental history card ───────────────────────────────────────────────────────

class _RentalHistoryCard extends StatelessWidget {
  final RentalModel rental;

  const _RentalHistoryCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    final r = rental;
    final hasImage = r.gownImageUrl.isNotEmpty;

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
                      errorBuilder: (_, _, _) => _placeholder(),
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
                    label: 'Gown Rented:',
                    value: r.gownName,
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Category:',
                    value: r.gownCategory,
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Color:',
                    value: r.gownColor,
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Price:',
                    value: '₱${PriceFormatter.format(r.gownPrice)}',
                    valueColor: AppColors.primary,
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
