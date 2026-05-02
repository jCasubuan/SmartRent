import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/category_model.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/utils/price_formatter.dart';
import 'package:smart_rent/screens/auth/landing_page.dart';
import 'package:smart_rent/services/category_service.dart';
import 'package:smart_rent/services/gown_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String? _userName;
  String _selectedFilter = 'All';

  List<CategoryModel> _categories = [];
  List<GownModel> _gowns = [];
  bool _isLoading = true;

  final List<String> _filters = [
    'All',
    'Popular',
    'Best Offers',
    'Premium Gowns',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _loadUserName(),
        CategoryService.getCategories(),
        GownService.getGowns(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[1] as List<CategoryModel>;
          _gowns = results[2] as List<GownModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[HomeTab._loadData] $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final name = user.displayName ?? '';
      final firstName = name.split(' ').first;
      if (mounted) setState(() => _userName = firstName.isEmpty ? null : firstName);
      return firstName;
    } catch (e) {
      debugPrint('[HomeTab._loadUserName] $e');
      return null;
    }
  }

  Future<void> _onRefresh() async => _loadData();

  List<GownModel> _gownsForCategory(String categoryName) {
    return _gowns
        .where((g) =>
            g.category.toLowerCase() == categoryName.toLowerCase() &&
            g.status == 'available')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // ── Header: search bar + greeting / login button ──────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Search bar
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search gowns...',
                          hintStyle: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textLight,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Greeting or Login button
                  if (user == null)
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LandingPage(),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.defaultForeground,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      _userName != null ? 'Hi, $_userName!' : 'Hi there!',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Filter chips ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.defaultForeground
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Body: loading / empty / category sections ─────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_categories.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No gowns available yet.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = _categories[index];
                  final gowns = _gownsForCategory(category.name);

                  // Skip categories with no available gowns
                  if (gowns.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category header
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Horizontal gown cards
                      SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          itemCount: gowns.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, i) =>
                              _GownCard(gown: gowns[i]),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  );
                },
                childCount: _categories.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// ── Gown card ─────────────────────────────────────────────────────────────────

class _GownCard extends StatefulWidget {
  final GownModel gown;
  const _GownCard({required this.gown});

  @override
  State<_GownCard> createState() => _GownCardState();
}

class _GownCardState extends State<_GownCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final gown = widget.gown;
    final hasImage = gown.imageUrls.isNotEmpty;

    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + favourite toggle
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasImage
                    ? Image.network(
                        gown.imageUrls.first,
                        width: 140,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _isFavorite = !_isFavorite),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.overlayDark,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFavorite ? Icons.star : Icons.star_border,
                      color: _isFavorite
                          ? AppColors.primary
                          : AppColors.defaultForeground,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Name
          Text(
            gown.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 2),

          // Price
          Text(
            '₱${PriceFormatter.format(gown.rentalPrice)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 140,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.checkroom_outlined,
        color: AppColors.border,
        size: 36,
      ),
    );
  }
}
