import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/core/widgets/cached_image.dart';
import 'package:smart_rent/core/utils/price_formatter.dart';
import 'package:smart_rent/screens/auth/landing_page.dart';
import 'package:smart_rent/screens/client/rental_request_screen.dart';
import 'package:smart_rent/services/user_service.dart';

/// Customer-facing gown detail screen.
class ClientGownDetailScreen extends StatefulWidget {
  final GownModel gown;
  final bool isBookmarked;

  const ClientGownDetailScreen({
    super.key,
    required this.gown,
    this.isBookmarked = false,
  });

  @override
  State<ClientGownDetailScreen> createState() =>
      _ClientGownDetailScreenState();
}

class _ClientGownDetailScreenState extends State<ClientGownDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  late bool _isBookmarked;
  bool _hasSubmittedRequest = false;

  /// Fallback estimated availability date fetched from the active rental,
  /// used when the gown doc itself doesn't have the date field set.
  DateTime? _fallbackReturnDate;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.isBookmarked;
    _fetchFallbackDate();
    _checkExistingRequest();
  }

  /// Checks if the current user already has a pending or approved request
  /// for this gown. If so, disables the rent button.
  Future<void> _checkExistingRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rentals')
          .where('gownId', isEqualTo: widget.gown.id)
          .where('customerId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'approved', 'picked_up'])
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        setState(() => _hasSubmittedRequest = true);
      }
    } catch (e) {
      debugPrint('[ClientGownDetail._checkExistingRequest] $e');
    }
  }

  /// If the gown is non-available and missing its expected date on the doc,
  /// look up the active rental for this gown to get the return date.
  Future<void> _fetchFallbackDate() async {
    final gown = widget.gown;
    // Only fetch if the gown is rented but missing the date on its own doc.
    if (gown.status != 'rented' || gown.rentalReturnDate != null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rentals')
          .where('gownId', isEqualTo: gown.id)
          .where('status', isEqualTo: 'picked_up')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        final data = snapshot.docs.first.data();
        final returnDate = (data['returnDate'] as Timestamp?)?.toDate();
        if (returnDate != null) {
          setState(() => _fallbackReturnDate = returnDate);
        }
      }
    } catch (e) {
      debugPrint('[ClientGownDetailScreen._fetchFallbackDate] $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginPrompt('bookmark this gown');
      return;
    }
    final wasBookmarked = _isBookmarked;
    setState(() => _isBookmarked = !_isBookmarked);
    if (wasBookmarked) {
      await UserService.removeBookmark(widget.gown.id);
    } else {
      await UserService.addBookmark(widget.gown.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasBookmarked
                ? 'Removed from bookmarks'
                : 'Added to bookmarks',
          ),
          backgroundColor: AppColors.textDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showLoginPrompt(String action) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please sign in to $action'),
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleRent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Sign in to Rent',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'You need to be signed in to rent a gown. '
            'This helps the shop keep track of your booking.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(
                    color: AppColors.textMid, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.defaultForeground,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Logged in — open rental request form
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RentalRequestScreen(gown: widget.gown),
      ),
    );

    if (submitted == true && mounted) {
      setState(() => _hasSubmittedRequest = true);
    }
  }

  void _openImageViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageViewerScreen(
          imageUrls: widget.gown.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final gown = widget.gown;
    final images = gown.imageUrls;
    final hasImages = images.isNotEmpty;
    final imageCount = images.length;
    final isAvailable = gown.status == 'available' && !_hasSubmittedRequest;

    // Customer-friendly button text based on gown status
    final buttonText = _hasSubmittedRequest
        ? 'Request Submitted ✓'
        : switch (gown.status) {
            'available' => 'Rent this Item',
            'reserved'  => 'Temporarily Unavailable',
            'rented'    => 'Currently Rented Out',
            'cleaning'  => 'Under Maintenance',
            'repair'    => 'Under Maintenance',
            _           => 'Currently Unavailable',
          };

    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(r.s(20), r.s(8), r.s(20), r.s(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: r.s(52),
                child: ElevatedButton(
                  onPressed: isAvailable ? _handleRent : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.defaultForeground,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: r.sp(16),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Image section ─────────────────────────────────────────────
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
                              onPageChanged: (i) =>
                                  setState(() => _currentImageIndex = i),
                              itemBuilder: (context, index) =>
                                  GestureDetector(
                                onTap: () => _openImageViewer(index),
                                child: CachedImage(
                                  imageUrl: images[index],
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  errorWidget: _imagePlaceholder(),
                                ),
                              ),
                            )
                          : _imagePlaceholder(),
                    ),
                    // Space for dot indicators — same approach as admin detail
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

                // Bookmark button — top-right
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 12,
                  child: GestureDetector(
                    onTap: _toggleBookmark,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.overlayDark,
                      child: Icon(
                        _isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: _isBookmarked
                            ? AppColors.primary
                            : AppColors.defaultForeground,
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // Image counter — top-right, below bookmark
                if (hasImages && imageCount > 1)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 52,
                    right: 12,
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

                // Dot indicators — sit in the 28px gap, same as admin
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
                                : AppColors.defaultForeground
                                    .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),

            // ── Info card — overlaps image by 20px ────────────────────────
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(r.s(20), r.s(20), r.s(20), r.s(32)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge + estimated availability
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: r.s(10), vertical: r.s(5)),
                          decoration: BoxDecoration(
                            color: AppColors.gownStatusColor(gown.status),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppColors.gownStatusLabel(gown.status),
                            style: TextStyle(
                              fontSize: r.sp(11),
                              fontWeight: FontWeight.w700,
                              color: AppColors.defaultForeground,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (!isAvailable && gown.status != 'reserved') ...[
                          const SizedBox(width: 8),
                          if (gown.status == 'rented' &&
                              (gown.rentalReturnDate != null ||
                                  _fallbackReturnDate != null))
                            _EstimatedDateChip(
                                date: gown.rentalReturnDate ??
                                    _fallbackReturnDate!)
                          else if (gown.status == 'cleaning' &&
                              gown.cleaningExpectedDate != null)
                            _EstimatedDateChip(
                                date: gown.cleaningExpectedDate!)
                          else if (gown.status == 'repair' &&
                              gown.repairExpectedDate != null)
                            _EstimatedDateChip(
                                date: gown.repairExpectedDate!),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Name
                    Text(
                      gown.name,
                      style: TextStyle(
                        fontSize: r.sp(24),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),

                    SizedBox(height: r.s(6)),

                    // Price
                    Text(
                      '₱${PriceFormatter.format(gown.rentalPrice)}',
                      style: TextStyle(
                        fontSize: r.sp(22),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),

                    SizedBox(height: r.s(16)),
                    const Divider(color: AppColors.border),
                    SizedBox(height: r.s(14)),

                    // Category + Color chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(label: gown.category),
                        _InfoChip(label: gown.color),
                      ],
                    ),

                    // Description
                    if (gown.description.isNotEmpty) ...[
                      SizedBox(height: r.s(16)),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: r.sp(15),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: r.s(6)),
                      Text(
                        gown.description,
                        style: TextStyle(
                          fontSize: r.sp(14),
                          color: AppColors.textMid,
                          height: 1.6,
                        ),
                      ),
                    ],

                    // Measurements
                    if (gown.measurements.isNotEmpty) ...[
                      SizedBox(height: r.s(20)),
                      Text(
                        'Measurements',
                        style: TextStyle(
                          fontSize: r.sp(15),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: r.s(4)),
                      Text(
                        'All measurements are in centimeters (cm)',
                        style: TextStyle(
                          fontSize: r.sp(12),
                          color: AppColors.textLight,
                        ),
                      ),
                      SizedBox(height: r.s(10)),
                      _MeasurementsGrid(measurements: gown.measurements),
                    ],

                    SizedBox(height: r.s(16)),
                  ],
                ),
              ),
            ),
          ],
        ),
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

// ── Full-screen zoomable image viewer ─────────────────────────────────────────
//
// Opened when the user taps an image. Each image gets its own
// TransformationController so zoom state is independent per page.
// InteractiveViewer conflict with PageView is resolved by disabling
// PageView scrolling when the image is zoomed in.

class _ImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageViewerScreen({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  // Counts active pointers. When >= 2, it's a pinch — disable PageView scroll
  // immediately so InteractiveViewer gets all gesture events including horizontal.
  int _activePointers = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.imageUrls.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Listener counts fingers on screen. 2+ fingers = pinch gesture.
          // PageView is locked immediately when pinch starts — before any
          // gesture recognizer can claim the horizontal drag.
          Listener(
            onPointerDown: (_) => setState(() => _activePointers++),
            onPointerUp: (_) => setState(() => _activePointers--),
            onPointerCancel: (_) => setState(() => _activePointers--),
            child: PageView.builder(
              controller: _pageController,
              physics: _activePointers >= 2
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: imageCount,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) => _ZoomablePage(
                imageUrl: widget.imageUrls[index],
              ),
            ),
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
          if (imageCount > 1)
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
                  '${_currentIndex + 1}/$imageCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.defaultForeground,
                  ),
                ),
              ),
            ),

          // Dot indicators
          if (imageCount > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imageCount, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.defaultForeground
                              .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomablePage extends StatefulWidget {
  final String imageUrl;

  const _ZoomablePage({required this.imageUrl});

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> {
  final TransformationController _controller = TransformationController();
  bool _isZoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDoubleTap(TapDownDetails details) {
    if (_isZoomed) {
      _controller.value = Matrix4.identity();
      setState(() => _isZoomed = false);
    } else {
      final position = details.localPosition;
      const scale = 2.5;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);
      _controller.value = Matrix4.identity()
        ..translate(x, y)
        ..scale(scale);
      setState(() => _isZoomed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _onDoubleTap,
      onDoubleTap: () {},
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1.0,
        maxScale: 5.0,
        panEnabled: true,
        onInteractionEnd: (details) {
          final scale = _controller.value.getMaxScaleOnAxis();
          final nowZoomed = scale > 1.05;
          if (nowZoomed != _isZoomed) {
            setState(() => _isZoomed = nowZoomed);
          }
        },
        child: Center(
          child: CachedImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.contain,
            errorWidget: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.border,
              size: 60,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(6)),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: r.sp(13),
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Measurements grid ─────────────────────────────────────────────────────────

class _MeasurementsGrid extends StatelessWidget {
  final Map<String, String> measurements;

  const _MeasurementsGrid({required this.measurements});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final entries =
        measurements.entries.where((e) => e.value.isNotEmpty).toList();

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
          padding: EdgeInsets.symmetric(horizontal: r.s(12), vertical: r.s(8)),
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
                '$val cm',
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

// ── Estimated date chip (for cleaning/repair) ─────────────────────────────────

class _EstimatedDateChip extends StatelessWidget {
  final DateTime date;
  const _EstimatedDateChip({required this.date});

  String get _formatted {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_outlined,
              size: 11, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text(
            'Available by $_formatted',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMid,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rental return date chip (fetches from active rental) ──────────────────────
