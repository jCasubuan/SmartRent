import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/widgets/gown_card.dart';
import 'package:smart_rent/screens/client/gown_detail_screen.dart';
import 'package:smart_rent/services/gown_service.dart';
import 'package:smart_rent/services/user_service.dart';

/// Displays all gowns the user has bookmarked.
/// Tapping the bookmark icon on a card removes it from the list instantly.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<GownModel> _bookmarkedGowns = [];
  Set<String> _bookmarkedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);

    final ids = await UserService.getBookmarks();
    if (ids.isEmpty) {
      if (mounted) {
        setState(() {
          _bookmarkedIds = {};
          _bookmarkedGowns = [];
          _isLoading = false;
        });
      }
      return;
    }

    // Fetch all gowns and filter to bookmarked ones
    final allGowns = await GownService.getGowns();
    final idSet = Set<String>.from(ids);
    final gowns = allGowns.where((g) => idSet.contains(g.id)).toList();

    if (mounted) {
      setState(() {
        _bookmarkedIds = idSet;
        _bookmarkedGowns = gowns;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBookmark(String gownId) async {
    setState(() {
      _bookmarkedIds.remove(gownId);
      _bookmarkedGowns.removeWhere((g) => g.id == gownId);
    });

    await UserService.removeBookmark(gownId);

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Removed from bookmarks'),
          backgroundColor: AppColors.textDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bookmarks',
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
          : _bookmarkedGowns.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark_border,
                            size: 52, color: AppColors.border),
                        const SizedBox(height: 16),
                        const Text(
                          'No bookmarks yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap the bookmark icon on any gown to save it here.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMid,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 270,
                  ),
                  itemCount: _bookmarkedGowns.length,
                  itemBuilder: (context, index) {
                    final gown = _bookmarkedGowns[index];
                    return GownCard(
                      gown: gown,
                      isBookmarked: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientGownDetailScreen(
                            gown: gown,
                            isBookmarked:
                                _bookmarkedIds.contains(gown.id),
                          ),
                        ),
                      ),
                      onBookmarkTap: () => _removeBookmark(gown.id),
                    );
                  },
                ),
    );
  }
}
