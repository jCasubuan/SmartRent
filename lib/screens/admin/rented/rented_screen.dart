import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/rental_model.dart';
import 'package:smart_rent/core/widgets/cached_image.dart';
import 'package:smart_rent/services/gown_service.dart';
import 'package:smart_rent/services/rental_service.dart';

/// Admin screen showing all currently rented out gowns (approved rentals).
/// List layout with gown image, customer info, dates, and "Mark as Returned".
/// Supports search and sort.
class RentedScreen extends StatefulWidget {
  const RentedScreen({super.key});

  @override
  State<RentedScreen> createState() => _RentedScreenState();
}

class _RentedScreenState extends State<RentedScreen> {
  final _searchController = TextEditingController();
  String _sortBy = 'newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RentalModel> _filter(List<RentalModel> rentals) {
    final q = _searchController.text.toLowerCase().trim();
    var result = rentals;

    if (q.isNotEmpty) {
      result = result.where((r) {
        return r.gownName.toLowerCase().contains(q) ||
            r.customerName.toLowerCase().contains(q) ||
            r.gownCategory.toLowerCase().contains(q) ||
            r.phone.contains(q);
      }).toList();
    }

    switch (_sortBy) {
      case 'customer':
        result.sort((a, b) => a.customerName
            .toLowerCase()
            .compareTo(b.customerName.toLowerCase()));
      case 'gown':
        result.sort((a, b) =>
            a.gownName.toLowerCase().compareTo(b.gownName.toLowerCase()));
      case 'newest':
      default:
        result.sort((a, b) {
          final aDate = a.approvedAt ?? a.createdAt ?? DateTime(2000);
          final bDate = b.approvedAt ?? b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
    }

    return result;
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
          'Currently Rented Out',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Search + Sort row ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Search gown, customer...',
                        hintStyle: const TextStyle(
                            color: AppColors.textLight, fontSize: 12),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textLight, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    color: AppColors.textLight, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: const Icon(Icons.sort,
                          color: AppColors.textLight, size: 16),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textDark),
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                      items: const [
                        DropdownMenuItem(
                            value: 'newest', child: Text('Newest')),
                        DropdownMenuItem(
                            value: 'customer', child: Text('Customer')),
                        DropdownMenuItem(
                            value: 'gown', child: Text('Gown')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<RentalModel>>(
              stream: RentalService.pickedUpRentalsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  );
                }

                final allRentals = snapshot.data ?? [];
                final rentals = _filter(allRentals);

                if (allRentals.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checkroom_outlined,
                            size: 52, color: AppColors.border),
                        SizedBox(height: 12),
                        Text(
                          'No gowns currently rented out.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (rentals.isEmpty) {
                  return const Center(
                    child: Text(
                      'No results match your search.',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textLight),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: rentals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _RentedCard(rental: rentals[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rented card ───────────────────────────────────────────────────────────────

class _RentedCard extends StatefulWidget {
  final RentalModel rental;
  const _RentedCard({required this.rental});

  @override
  State<_RentedCard> createState() => _RentedCardState();
}

class _RentedCardState extends State<_RentedCard> {
  bool _isProcessing = false;

  Future<void> _markReturned() async {
    final r = widget.rental;
    final hasImage = r.gownImageUrl.isNotEmpty;

    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: hasImage
                      ? CachedImage(
                          imageUrl: r.gownImageUrl,
                          width: 80, height: 96, fit: BoxFit.cover)
                      : _sheetPlaceholder(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mark as Returned',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      Text(
                        '"${r.gownName}" has been returned by ${r.customerName}.',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMid,
                            height: 1.4),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'What should happen to the gown next?',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Cleaning',
                    icon: Icons.local_laundry_service_outlined,
                    color: AppColors.statusCleaning,
                    onTap: () => Navigator.pop(ctx, 'cleaning'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Available',
                    icon: Icons.check_circle_outline,
                    color: AppColors.rentalApproved,
                    onTap: () => Navigator.pop(ctx, 'available'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Repair',
                    icon: Icons.build_outlined,
                    color: AppColors.statusRepair,
                    onTap: () => Navigator.pop(ctx, 'repair'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: AppColors.textMid,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == 'cleaning') {
      final cleaningDates = await _showCleaningDateDialog();
      if (cleaningDates == null || !mounted) return;

      setState(() => _isProcessing = true);
      final rentalSuccess = await RentalService.completeRental(
        widget.rental.id,
        widget.rental.gownId,
        nextGownStatus: 'cleaning',
      );

      if (!rentalSuccess) {
        if (mounted) {
          setState(() => _isProcessing = false);
          _showError('Failed to update. Please try again.');
        }
        return;
      }

      await GownService.sendToCleaning(
        gownId: widget.rental.gownId,
        startDate: cleaningDates.start,
        expectedDate: cleaningDates.expected,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccess(
            '${widget.rental.gownName} sent to cleaning. Expected back by ${_formatDate(cleaningDates.expected)}.');
      }
      return;
    }

    if (choice == 'repair') {
      final repairDates = await _showRepairDateDialog();
      if (repairDates == null || !mounted) return;

      setState(() => _isProcessing = true);
      final rentalSuccess = await RentalService.completeRental(
        widget.rental.id,
        widget.rental.gownId,
        nextGownStatus: 'repair',
      );

      if (!rentalSuccess) {
        if (mounted) {
          setState(() => _isProcessing = false);
          _showError('Failed to update. Please try again.');
        }
        return;
      }

      await GownService.sendToRepair(
        gownId: widget.rental.gownId,
        startDate: repairDates.start,
        expectedDate: repairDates.expected,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccess(
            '${widget.rental.gownName} sent to repair. Expected back by ${_formatDate(repairDates.expected)}.');
      }
      return;
    }

    setState(() => _isProcessing = true);
    final success = await RentalService.completeRental(
      widget.rental.id,
      widget.rental.gownId,
      nextGownStatus: choice,
    );
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        _showSuccess('${widget.rental.gownName} returned and marked as available.');
      } else {
        _showError('Failed to update. Please try again.');
      }
    }
  }

  Future<({DateTime start, DateTime expected})?> _showCleaningDateDialog() async {
    DateTime expectedDate = DateTime.now().add(const Duration(days: 3));
    final today = DateTime.now();

    return showDialog<({DateTime start, DateTime expected})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.local_laundry_service_outlined,
                  color: AppColors.statusCleaning, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"${widget.rental.gownName}" will be sent to cleaning',
                  style: const TextStyle(
                    fontSize: 15,
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
              const Text('Start Date',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGrey,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.textLight),
                    const SizedBox(width: 8),
                    Text(_formatDate(today),
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMid,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Text('Today',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Expected Completion',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: expectedDate,
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
                  if (picked != null) {
                    setDialogState(() => expectedDate = picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.statusCleaning),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.statusCleaning),
                      const SizedBox(width: 8),
                      Text(_formatDate(expectedDate),
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.statusCleaning),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.textMid,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, (start: today, expected: expectedDate)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusCleaning,
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
      ),
    );
  }

  Future<({DateTime start, DateTime expected})?> _showRepairDateDialog() async {
    DateTime expectedDate = DateTime.now().add(const Duration(days: 5));
    final today = DateTime.now();

    return showDialog<({DateTime start, DateTime expected})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.build_outlined,
                  color: AppColors.statusRepair, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"${widget.rental.gownName}" will be sent to repair',
                  style: const TextStyle(
                    fontSize: 15,
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
              const Text('Start Date',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGrey,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.textLight),
                    const SizedBox(width: 8),
                    Text(_formatDate(today),
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMid,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Text('Today',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Expected Completion',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: expectedDate,
                    firstDate: today.add(const Duration(days: 1)),
                    lastDate: today.add(const Duration(days: 90)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.statusRepair,
                          onPrimary: AppColors.defaultForeground,
                          onSurface: AppColors.textDark,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() => expectedDate = picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.statusRepair),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.statusRepair),
                      const SizedBox(width: 8),
                      Text(_formatDate(expectedDate),
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.statusRepair),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.textMid,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, (start: today, expected: expectedDate)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusRepair,
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
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.rentalApproved,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _sheetPlaceholder() {
    return Container(
      width: 80,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.checkroom_outlined,
          color: AppColors.border, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rental;
    final hasImage = r.gownImageUrl.isNotEmpty;
    final isOverdue = r.returnDate.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: isOverdue
            ? Border.all(color: AppColors.error.withValues(alpha: 0.5))
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
                        ? CachedImage(
                            imageUrl: r.gownImageUrl,
                            width: 100,
                            fit: BoxFit.cover)
                        : _imagePlaceholder(),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? AppColors.error
                            : AppColors.rentalApproved,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(10)),
                      ),
                      child: Text(
                        isOverdue ? 'OVERDUE' : 'RENTED',
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

              // Details + button
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
                    const SizedBox(height: 2),
                    _CustomerEmailText(customerId: r.customerId),
                    Text('Phone: ${r.phone}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textLight)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pick up:',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(_formatDate(r.pickupDate),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Return:',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(_formatDate(r.returnDate),
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isOverdue
                                          ? AppColors.error
                                          : AppColors.textDark)),
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
                                    color: AppColors.primary)))
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _markReturned,
                              icon: const Icon(
                                  Icons.assignment_turned_in_outlined,
                                  size: 16),
                              label: const Text('Mark as Returned',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor:
                                    AppColors.defaultForeground,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(22)),
                              ),
                            ),
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

// ── Action button for bottom sheet ────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Customer email text (async) ───────────────────────────────────────────────

class _CustomerEmailText extends StatefulWidget {
  final String customerId;
  const _CustomerEmailText({required this.customerId});

  @override
  State<_CustomerEmailText> createState() => _CustomerEmailTextState();
}

class _CustomerEmailTextState extends State<_CustomerEmailText> {
  String? _email;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.customerId)
          .get();
      if (mounted) {
        setState(() => _email = doc.data()?['email'] as String? ?? '');
      }
    } catch (_) {
      if (mounted) setState(() => _email = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_email == null || _email!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text('Email: $_email',
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}
