import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/utils/responsive_helper.dart';
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
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceGrey,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppColors.textDark, size: r.s(20)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bookmarks',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: r.sp(18),
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
                    padding: EdgeInsets.symmetric(horizontal: r.s(32)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border,
                            size: r.s(52), color: AppColors.border),
                        SizedBox(height: r.s(16)),
                        Text(
                          'No bookmarks yet',
                          style: TextStyle(
                            fontSize: r.sp(16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: r.s(8)),
                        Text(
                          'Tap the bookmark icon on any gown to save it here.',
                          style: TextStyle(
                            fontSize: r.sp(13),
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
                  padding: EdgeInsets.all(r.s(16)),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: r.s(12),
                    mainAxisSpacing: r.s(12),
                    mainAxisExtent: r.s(270),
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
