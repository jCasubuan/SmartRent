import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/category_model.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/widgets/gown_card.dart';
import 'package:smart_rent/screens/auth/landing_page.dart';
import 'package:smart_rent/screens/client/gown_detail_screen.dart';
import 'package:smart_rent/services/category_service.dart';
import 'package:smart_rent/services/gown_service.dart';
import 'package:smart_rent/services/user_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _searchController = TextEditingController();

  String _selectedFilter = 'All';
  List<CategoryModel> _categories = [];
  Set<String> _bookmarkedIds = {};
  bool _categoriesLoading = true;

  final List<String> _filters = [
    'All',
    'Popular',
    'Best Offers',
    'Premium Gowns',
  ];

  bool get _isSearching => _searchController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryService.getCategories();
    final bookmarks = await UserService.getBookmarks();
    if (mounted) {
      setState(() {
        _categories = cats;
        _bookmarkedIds = Set<String>.from(bookmarks);
        _categoriesLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    _searchController.clear();
    await _loadCategories();
  }

  List<GownModel> _gownsForCategory(List<GownModel> allGowns, String categoryName) {
    return allGowns
        .where((g) =>
            g.category.toLowerCase() == categoryName.toLowerCase() &&
            g.status == 'available')
        .toList();
  }

  List<GownModel> _searchResults(List<GownModel> allGowns) {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return [];
    return allGowns.where((g) {
      return g.status == 'available' &&
          (g.name.toLowerCase().contains(query) ||
              g.category.toLowerCase().contains(query) ||
              g.color.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _toggleBookmark(String gownId) async {
    final isCurrentlyBookmarked = _bookmarkedIds.contains(gownId);
    setState(() {
      if (isCurrentlyBookmarked) {
        _bookmarkedIds.remove(gownId);
      } else {
        _bookmarkedIds.add(gownId);
      }
    });
    if (isCurrentlyBookmarked) {
      await UserService.removeBookmark(gownId);
    } else {
      await UserService.addBookmark(gownId);
    }
  }

  void _showLoginPrompt(BuildContext context, String action) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please sign in to $action'),
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildGownCard(BuildContext context, GownModel gown, bool isLoggedIn) {
    return GownCard(
      gown: gown,
      isBookmarked: _bookmarkedIds.contains(gown.id),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClientGownDetailScreen(
            gown: gown,
            isBookmarked: _bookmarkedIds.contains(gown.id),
          ),
        ),
      ),
      onBookmarkTap: isLoggedIn
          ? () => _toggleBookmark(gown.id)
          : () => _showLoginPrompt(context, 'bookmark this gown'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    return StreamBuilder<List<GownModel>>(
      stream: GownService.gownsStream(),
      builder: (context, snapshot) {
        final allGowns = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final isOffline = snapshot.hasError;

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // â”€â”€ Top bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceGrey,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search by name, category, color...',
                              hintStyle: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.textLight,
                                size: 20,
                              ),
                              suffixIcon: _isSearching
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: AppColors.textLight,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          _searchController.clear(),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isLoggedIn)
                        IconButton(
                          onPressed: () {
                            // TODO: navigate to bookmarks tab/page
                          },
                          icon: const Icon(
                            Icons.bookmark_border,
                            color: AppColors.primary,
                            size: 26,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        )
                      else ...[
                        IconButton(
                          onPressed: () =>
                              _showLoginPrompt(context, 'view your bookmarks'),
                          icon: const Icon(
                            Icons.bookmark_border,
                            color: AppColors.textLight,
                            size: 26,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                        const SizedBox(width: 4),
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
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // â”€â”€ Filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              if (!_isSearching)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
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

              // â”€â”€ Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              if (isLoading || _categoriesLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )

              else if (isOffline)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_outlined,
                              size: 52, color: AppColors.border),
                          const SizedBox(height: 16),
                          const Text(
                            'No internet connection',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please check your connection and try again.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMid,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _onRefresh,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text(
                              'Try Again',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.defaultForeground,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              // â”€â”€ Search results â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              else if (_isSearching)
                () {
                  final results = _searchResults(allGowns);
                  return results.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No gowns found for "${_searchController.text}"',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 270,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildGownCard(
                                context, results[index], isLoggedIn),
                              childCount: results.length,
                            ),
                          ),
                        );
                }()

              // â”€â”€ Category sections â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              else if (allGowns.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No gowns available at the moment.',
                      style: TextStyle(fontSize: 14, color: AppColors.textLight),
                    ),
                  ),
                )

              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = _categories[index];
                      final gowns =
                          _gownsForCategory(allGowns, category.name);
                      if (gowns.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 270,
                              ),
                              itemCount: gowns.length,
                              itemBuilder: (context, i) =>
                                  _buildGownCard(context, gowns[i], isLoggedIn),
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
      },
    );
  }
}
