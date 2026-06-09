import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/services/gown_service.dart';

/// Admin cleaning screen — shows all gowns currently in 'cleaning' status.
/// Displayed in a 2-column grid with gown image, name, category, and
/// a "Mark as clean" button to return the gown to 'available'.
/// Overdue gowns are highlighted and offer an option to extend the date.
class CleaningScreen extends StatefulWidget {
  const CleaningScreen({super.key});

  @override
  State<CleaningScreen> createState() => _CleaningScreenState();
}

class _CleaningScreenState extends State<CleaningScreen> {
  List<Map<String, dynamic>> _cleaningGowns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final gowns = await GownService.getCleaningGownsWithDates();
    if (mounted) {
      setState(() {
        _cleaningGowns = gowns;
        _isLoading = false;
      });
    }
  }

  // ── Mark as clean ───────────────────────────────────────────────────────

  Future<void> _markAsClean(GownModel gown, DateTime? expectedDate) async {
    final isOverdue = expectedDate != null &&
        expectedDate.isBefore(DateTime.now());
    final overdueDays = isOverdue
        ? DateTime.now().difference(expectedDate).inDays
        : 0;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isOverdue
                  ? Icons.warning_amber_outlined
                  : Icons.check_circle_outline,
              color: isOverdue ? AppColors.error : AppColors.rentalApproved,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOverdue ? 'Cleaning Overdue' : 'Mark as Clean',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overdue warning
            if (isOverdue) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_outlined,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This gown is $overdueDays day${overdueDays > 1 ? 's' : ''} past the expected cleaning date.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            Text(
              '"${gown.name}" — what would you like to do?',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMid,
                height: 1.5,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                  color: AppColors.textMid, fontWeight: FontWeight.w600),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Extend cleaning option (only for overdue)
              if (isOverdue)
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'extend'),
                  child: const Text(
                    'Extend',
                    style: TextStyle(
                      color: AppColors.statusCleaning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, 'clean'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rentalApproved,
                  foregroundColor: AppColors.defaultForeground,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Mark as Clean',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    if (result == 'extend') {
      await _extendCleaning(gown);
      return;
    }

    // result == 'clean'
    final success = await GownService.markAsClean(gown.id);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${gown.name}" is now available for rental.'),
            backgroundColor: AppColors.rentalApproved,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Extend cleaning ─────────────────────────────────────────────────────

  Future<void> _extendCleaning(GownModel gown) async {
    final today = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 3)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.statusCleaning,
            onPrimary: AppColors.defaultForeground,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );

    if (newDate == null || !mounted) return;

    final success = await GownService.sendToCleaning(
      gownId: gown.id,
      startDate: today,
      expectedDate: newDate,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '"${gown.name}" cleaning extended to ${_formatDate(newDate)}.'),
            backgroundColor: AppColors.statusCleaning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to extend. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
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
          'Cleaning',
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
          : _cleaningGowns.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_laundry_service_outlined,
                          size: 52, color: AppColors.border),
                      SizedBox(height: 12),
                      Text(
                        'No gowns in cleaning.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gowns sent to cleaning will appear here.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.48,
                  ),
                  itemCount: _cleaningGowns.length,
                  itemBuilder: (context, index) {
                    final entry = _cleaningGowns[index];
                    final gown = entry['gown'] as GownModel;
                    final expectedDate =
                        entry['cleaningExpectedDate'] as DateTime?;

                    return _CleaningGownCard(
                      gown: gown,
                      expectedDate: expectedDate,
                      formattedExpected: _formatDate(expectedDate),
                      onMarkClean: () =>
                          _markAsClean(gown, expectedDate),
                    );
                  },
                ),
    );
  }
}

// ── Cleaning gown card ────────────────────────────────────────────────────────

class _CleaningGownCard extends StatelessWidget {
  final GownModel gown;
  final DateTime? expectedDate;
  final String formattedExpected;
  final VoidCallback onMarkClean;

  const _CleaningGownCard({
    required this.gown,
    required this.expectedDate,
    required this.formattedExpected,
    required this.onMarkClean,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = gown.imageUrls.isNotEmpty;
    final isOverdue = expectedDate != null &&
        expectedDate!.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.6)
              : AppColors.border,
          width: isOverdue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gown image with optional overdue badge
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(13)),
                  child: hasImage
                      ? Image.network(
                          gown.imageUrls.first,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                // Overdue badge
                if (isOverdue)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_outlined,
                              size: 10, color: AppColors.defaultForeground),
                          SizedBox(width: 3),
                          Text(
                            'OVERDUE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.defaultForeground,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gown.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Category: ${gown.category}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                // Expected date row
                Row(
                  children: [
                    Icon(
                      isOverdue
                          ? Icons.warning_amber_outlined
                          : Icons.schedule_outlined,
                      size: 12,
                      color: isOverdue
                          ? AppColors.error
                          : AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        expectedDate == null
                            ? 'No date set'
                            : isOverdue
                                ? 'Due: $formattedExpected'
                                : 'Expected: $formattedExpected',
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue
                              ? AppColors.error
                              : AppColors.textLight,
                          fontWeight: isOverdue
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mark as clean button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onMarkClean,
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text(
                  'Mark as clean',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceGrey,
      child: const Center(
        child: Icon(Icons.checkroom_outlined,
            color: AppColors.border, size: 36),
      ),
    );
  }
}
