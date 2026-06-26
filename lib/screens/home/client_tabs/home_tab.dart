import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/category_model.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
import 'package:smart_rent/core/widgets/gown_card.dart';
import 'package:smart_rent/screens/auth/landing_page.dart';
import 'package:smart_rent/screens/client/bookmarks_screen.dart';
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

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

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
        // Reset filter if selected category no longer exists
        if (_selectedFilter != 'All' &&
            !cats.any((c) => c.name == _selectedFilter)) {
          _selectedFilter = 'All';
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    _searchController.clear();
    await _loadCategories();
  }

  /// Lightweight refresh — only reloads bookmark IDs without touching categories.
  Future<void> _refreshBookmarks() async {
    final bookmarks = await UserService.getBookmarks();
    if (mounted) {
      setState(() => _bookmarkedIds = Set<String>.from(bookmarks));
    }
  }

  List<GownModel> _gownsForCategory(List<GownModel> allGowns, String categoryName) {
    return allGowns
        .where((g) =>
            g.category.toLowerCase() == categoryName.toLowerCase())
        .toList();
  }

  List<GownModel> _searchResults(List<GownModel> allGowns) {
    final raw = _searchController.text.trim();
    // Sanitize: strip non-alphanumeric except spaces, hyphens, apostrophes
    final sanitized = raw.replaceAll(RegExp(r"[^\w\s\-']"), '');
    final query = sanitized.toLowerCase().trim();
    if (query.isEmpty) return [];
    return allGowns.where((g) {
      return g.name.toLowerCase().contains(query) ||
          g.category.toLowerCase().contains(query) ||
          g.color.toLowerCase().contains(query);
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

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyBookmarked
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
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientGownDetailScreen(
              gown: gown,
              isBookmarked: _bookmarkedIds.contains(gown.id),
            ),
          ),
        );
        _refreshBookmarks();
      },
      onBookmarkTap: isLoggedIn
          ? () => _toggleBookmark(gown.id)
          : () => _showLoginPrompt(context, 'bookmark this gown'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
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
                  padding: EdgeInsets.fromLTRB(r.s(16), r.s(16), r.s(16), r.s(8)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: r.s(44),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceGrey,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TextField(
                            controller: _searchController,
                            maxLength: 50,
                            style: TextStyle(
                              fontSize: r.sp(14),
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search by name, category, color...',
                              hintStyle: TextStyle(
                                color: AppColors.textLight,
                                fontSize: r.sp(13),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.textLight,
                                size: r.s(20),
                              ),
                              suffixIcon: _isSearching
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: AppColors.textLight,
                                        size: r.s(18),
                                      ),
                                      onPressed: () =>
                                          _searchController.clear(),
                                    )
                                  : null,
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: r.s(12)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: r.s(10)),
                      if (isLoggedIn)
                        IconButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BookmarksScreen(),
                              ),
                            );
                            _refreshBookmarks();
                          },
                          icon: Icon(
                            Icons.bookmark_border,
                            color: AppColors.primary,
                            size: r.s(26),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: r.s(36),
                            minHeight: r.s(36),
                          ),
                        )
                      else ...[
                        IconButton(
                          onPressed: () =>
                              _showLoginPrompt(context, 'view your bookmarks'),
                          icon: Icon(
                            Icons.bookmark_border,
                            color: AppColors.textLight,
                            size: r.s(26),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: r.s(36),
                            minHeight: r.s(36),
                          ),
                        ),
                        SizedBox(width: r.s(4)),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: r.s(14),
                              vertical: r.s(10),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: r.sp(13),
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
                    height: r.s(40),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: r.s(16)),
                      itemCount: _categories.length + 1,
                      separatorBuilder: (_, _) => SizedBox(width: r.s(8)),
                      itemBuilder: (context, index) {
                        final filter = index == 0
                            ? 'All'
                            : _categories[index - 1].name;
                        final isSelected = _selectedFilter == filter;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFilter = filter),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: r.s(16),
                              vertical: r.s(8),
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
                                fontSize: r.sp(13),
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
                      padding: EdgeInsets.symmetric(horizontal: r.s(32)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_outlined,
                              size: r.s(52), color: AppColors.border),
                          SizedBox(height: r.s(16)),
                          Text(
                            'No internet connection',
                            style: TextStyle(
                              fontSize: r.sp(16),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: r.s(8)),
                          Text(
                            'Please check your connection and try again.',
                            style: TextStyle(
                              fontSize: r.sp(13),
                              color: AppColors.textMid,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: r.s(24)),
                          ElevatedButton.icon(
                            onPressed: _onRefresh,
                            icon: Icon(Icons.refresh, size: r.s(18)),
                            label: Text(
                              'Try Again',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: r.sp(14)),
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
                              style: TextStyle(
                                fontSize: r.sp(14),
                                color: AppColors.textLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: r.s(16)),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: r.s(12),
                              mainAxisSpacing: r.s(12),
                              mainAxisExtent: r.s(270),
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
                      'No gowns to display at the moment.',
                      style: TextStyle(fontSize: 14, color: AppColors.textLight),
                    ),
                  ),
                )

              // Specific category selected — flat grid
              else if (_selectedFilter != 'All')
                () {
                  final filtered = _gownsForCategory(allGowns, _selectedFilter);
                  if (filtered.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No gowns in this category yet.',
                          style: TextStyle(fontSize: 14, color: AppColors.textLight),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: r.s(16)),
                    sliver: SliverGrid(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: r.s(12),
                        mainAxisSpacing: r.s(12),
                        mainAxisExtent: r.s(270),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildGownCard(
                            context, filtered[index], isLoggedIn),
                        childCount: filtered.length,
                      ),
                    ),
                  );
                }()

              // "All" selected — grouped by category with headers
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
                                EdgeInsets.fromLTRB(r.s(16), 0, r.s(16), r.s(12)),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: r.sp(16),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.primary,
                                  size: r.s(20),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: r.s(16)),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: r.s(12),
                                mainAxisSpacing: r.s(12),
                                mainAxisExtent: r.s(270),
                              ),
                              itemCount: gowns.length,
                              itemBuilder: (context, i) =>
                                  _buildGownCard(context, gowns[i], isLoggedIn),
                            ),
                          ),
                          SizedBox(height: r.s(24)),
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
