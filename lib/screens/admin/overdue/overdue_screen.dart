import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/models/rental_model.dart';
import 'package:smart_rent/services/gown_service.dart';
import 'package:smart_rent/services/rental_service.dart';

/// Admin overdue screen — shows all items past their expected date.
/// Tabs: Rentals (customer hasn't returned) | Cleaning | Repair
class OverdueScreen extends StatefulWidget {
  const OverdueScreen({super.key});

  @override
  State<OverdueScreen> createState() => _OverdueScreenState();
}

class _OverdueScreenState extends State<OverdueScreen>
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
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Overdue',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.defaultForeground,
          unselectedLabelColor: AppColors.textMid,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          indicator: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(20),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Rentals'),
            Tab(text: 'Cleaning'),
            Tab(text: 'Repair'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OverdueRentalsTab(),
          _OverdueGownsTab(status: 'cleaning'),
          _OverdueGownsTab(status: 'repair'),
        ],
      ),
    );
  }
}

// ── Overdue rentals tab ───────────────────────────────────────────────────────

class _OverdueRentalsTab extends StatelessWidget {
  const _OverdueRentalsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RentalModel>>(
      stream: RentalService.pickedUpRentalsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final all = snapshot.data ?? [];
        final now = DateTime.now();
        final overdue =
            all.where((r) => r.returnDate.isBefore(now)).toList();

        if (overdue.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 52, color: AppColors.border),
                SizedBox(height: 12),
                Text(
                  'No overdue rentals.',
                  style: TextStyle(fontSize: 14, color: AppColors.textLight),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: overdue.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _OverdueRentalCard(rental: overdue[index]),
        );
      },
    );
  }
}

// ── Overdue gowns tab (cleaning / repair) ─────────────────────────────────────

class _OverdueGownsTab extends StatefulWidget {
  final String status;
  const _OverdueGownsTab({required this.status});

  @override
  State<_OverdueGownsTab> createState() => _OverdueGownsTabState();
}

class _OverdueGownsTabState extends State<_OverdueGownsTab> {
  List<Map<String, dynamic>> _overdueGowns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final List<Map<String, dynamic>> gowns;
    if (widget.status == 'cleaning') {
      gowns = await GownService.getCleaningGownsWithDates();
    } else {
      gowns = await GownService.getRepairGownsWithDates();
    }

    final now = DateTime.now();
    final dateKey = widget.status == 'cleaning'
        ? 'cleaningExpectedDate'
        : 'repairExpectedDate';

    final overdue = gowns.where((entry) {
      final expected = entry[dateKey] as DateTime?;
      return expected != null && expected.isBefore(now);
    }).toList();

    if (mounted) {
      setState(() {
        _overdueGowns = overdue;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_overdueGowns.isEmpty) {
      final label = widget.status == 'cleaning' ? 'cleaning' : 'repair';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 52, color: AppColors.border),
            const SizedBox(height: 12),
            Text(
              'No overdue $label items.',
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    final dateKey = widget.status == 'cleaning'
        ? 'cleaningExpectedDate'
        : 'repairExpectedDate';

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _overdueGowns.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = _overdueGowns[index];
        final gown = entry['gown'] as GownModel;
        final expected = entry[dateKey] as DateTime?;
        return _OverdueGownCard(
          gown: gown,
          expectedDate: expected,
          statusLabel: widget.status == 'cleaning' ? 'Cleaning' : 'Repair',
        );
      },
    );
  }
}

// ── Overdue rental card ───────────────────────────────────────────────────────

class _OverdueRentalCard extends StatelessWidget {
  final RentalModel rental;
  const _OverdueRentalCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    final r = rental;
    final hasImage = r.gownImageUrl.isNotEmpty;
    final overdueDays = DateTime.now().difference(r.returnDate).inDays;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasImage
                  ? Image.network(r.gownImageUrl,
                      width: 70, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overdue badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$overdueDays DAY${overdueDays > 1 ? 'S' : ''} OVERDUE',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.defaultForeground,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.gownName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Customer: ${r.customerName}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMid),
                  ),
                  Text(
                    'Phone: ${r.phone}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined,
                          size: 12, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_formatDate(r.returnDate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _placeholder() {
    return Container(
      width: 70,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.checkroom_outlined,
          color: AppColors.border, size: 28),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ── Overdue gown card (cleaning/repair) ───────────────────────────────────────

class _OverdueGownCard extends StatelessWidget {
  final GownModel gown;
  final DateTime? expectedDate;
  final String statusLabel;

  const _OverdueGownCard({
    required this.gown,
    required this.expectedDate,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = gown.imageUrls.isNotEmpty;
    final overdueDays = expectedDate != null
        ? DateTime.now().difference(expectedDate!).inDays
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasImage
                  ? Image.network(gown.imageUrls.first,
                      width: 70, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overdue badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$overdueDays DAY${overdueDays > 1 ? 'S' : ''} OVERDUE',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.defaultForeground,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    gown.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Status: $statusLabel',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMid),
                  ),
                  Text(
                    'Category: ${gown.category}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 4),
                  if (expectedDate != null)
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined,
                            size: 12, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${_formatDate(expectedDate!)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _placeholder() {
    return Container(
      width: 70,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.checkroom_outlined,
          color: AppColors.border, size: 28),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
