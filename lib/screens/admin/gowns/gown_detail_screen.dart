import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/utils/price_formatter.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/core/widgets/cached_image.dart';
import 'package:smart_rent/screens/admin/gowns/edit_gown_screen.dart';
import 'package:smart_rent/services/gown_service.dart';

class GownDetailScreen extends StatefulWidget {
  final GownModel gown;

  const GownDetailScreen({super.key, required this.gown});

  @override
  State<GownDetailScreen> createState() => _GownDetailScreenState();
}

class _GownDetailScreenState extends State<GownDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isDeleting = false;

  // Keep a local copy so UI can reflect edits after returning from EditScreen
  late GownModel _gown;

  @override
  void initState() {
    super.initState();
    _gown = widget.gown;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) => AppColors.gownStatusColor(status);
  String _statusLabel(String status) => AppColors.gownStatusLabel(status);

  // Navigate to Edit screen — refresh local gown data on return
  Future<void> _navigateToEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditGownScreen(gown: _gown),
      ),
    );

    // If edit was saved, reload gown data from Firestore
    if (updated == true && mounted) {
      final gowns = await GownService.getGowns();
      final refreshed = gowns.where((g) => g.id == _gown.id).firstOrNull;
      if (refreshed != null && mounted) {
        setState(() => _gown = refreshed);
      }
    }
  }

  // Show delete confirmation dialog
  void _confirmDelete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 22),
            SizedBox(width: 8),
            Text(
              'Delete Gown',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Text(
                '⚠ This action is irreversible. The gown will be permanently deleted and cannot be recovered.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'You are about to delete:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),

            const SizedBox(height: 10),

            // Gown summary
            _DeleteInfoRow(label: 'Name', value: _gown.name),
            _DeleteInfoRow(label: 'Code', value: _gown.code),
            _DeleteInfoRow(label: 'Category', value: _gown.category),
            _DeleteInfoRow(label: 'Color', value: _gown.color),
            _DeleteInfoRow(
              label: 'Price',
              value: '₱${PriceFormatter.format(_gown.rentalPrice)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteGown();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.defaultForeground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGown() async {
    setState(() => _isDeleting = true);

    final success = await GownService.deleteGown(_gown.id);

    if (mounted) {
      setState(() => _isDeleting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_gown.name} has been deleted.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        // Pop back to inventory and signal a refresh
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete gown. Please try again.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final images = _gown.imageUrls;
    final hasImages = images.isNotEmpty;
    final imageCount = images.length;

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // ── Image section ───────────────────────────────────
                Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 3 / 4,
                          child: hasImages
                              ? PageView.builder(
                                  controller: _pageController,
                                  itemCount: imageCount,
                                  physics: imageCount > 1
                                      ? const BouncingScrollPhysics()
                                      : const NeverScrollableScrollPhysics(),
                                  onPageChanged: (index) {
                                    setState(
                                        () => _currentImageIndex = index);
                                  },
                                  itemBuilder: (context, index) {
                                    return CachedImage(
                                      imageUrl: images[index],
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      errorWidget: _imagePlaceholder(),
                                    );
                                  },
                                )
                              : _imagePlaceholder(),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),

                    // Back button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 12,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.overlayDark,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.defaultForeground,
                            size: 18,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),

                    // Image counter
                    if (hasImages && imageCount > 1)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 12,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.overlayDarker,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1}/$imageCount',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.defaultForeground,
                            ),
                          ),
                        ),
                      ),

                    // Dot indicators
                    if (hasImages && imageCount > 1)
                      Positioned(
                        bottom: 34,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(imageCount, (index) {
                            final isActive = index == _currentImageIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 20 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.defaultForeground.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),

                // ── Info card ────────────────────────────────────────
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(r.s(20), r.s(20), r.s(20), r.s(32)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: r.s(10), vertical: r.s(5)),
                          decoration: BoxDecoration(
                            color: _statusColor(_gown.status),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel(_gown.status),
                            style: TextStyle(
                              fontSize: r.sp(11),
                              fontWeight: FontWeight.w700,
                              color: AppColors.defaultForeground,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        SizedBox(height: r.s(10)),

                        // Name + Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _gown.name,
                                style: TextStyle(
                                  fontSize: r.sp(22),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            SizedBox(width: r.s(12)),
                            Text(
                              '₱${PriceFormatter.format(_gown.rentalPrice)}',
                              style: TextStyle(
                                fontSize: r.sp(20),
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: r.s(16)),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 12),

                        _InfoRow(label: 'Code', value: _gown.code),
                        _InfoRow(
                            label: 'Category', value: _gown.category),
                        _InfoRow(label: 'Color', value: _gown.color),

                        if (_gown.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _InfoRow(
                              label: 'Description',
                              value: _gown.description),
                        ],

                        if (_gown.measurements.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Measurements',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _MeasurementsGrid(
                              measurements: _gown.measurements),
                        ],

                        const SizedBox(height: 28),

                        // Edit / Delete buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _isDeleting ? null : _navigateToEdit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.defaultForeground,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_outlined, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    _isDeleting ? null : _confirmDelete,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  side: const BorderSide(
                                      color: AppColors.error),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_outline, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Full screen loading overlay while deleting
          if (_isDeleting)
            Container(
              color: AppColors.overlayModal,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceGrey,
      child: const Center(
        child: Icon(
          Icons.checkroom_outlined,
          color: AppColors.border,
          size: 60,
        ),
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r.s(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: r.s(100),
            child: Text(
              label,
              style: TextStyle(
                fontSize: r.sp(13),
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(fontSize: r.sp(13), color: AppColors.textLight),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: r.sp(13),
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delete Dialog Info Row ────────────────────────────────────────────────────
class _DeleteInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DeleteInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Measurements Grid ─────────────────────────────────────────────────────────
class _MeasurementsGrid extends StatelessWidget {
  final Map<String, String> measurements;

  const _MeasurementsGrid({required this.measurements});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final entries = measurements.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3,
      ),
      itemBuilder: (context, index) {
        final key = entries[index].key;
        final val = entries[index].value;
        return Container(
          padding:
              EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(8)),
          decoration: BoxDecoration(
            color: AppColors.surfaceCream,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                key,
                style: TextStyle(
                  fontSize: r.sp(10),
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                val.isEmpty ? '—' : val,
                style: TextStyle(
                  fontSize: r.sp(13),
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
