import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'package:smart_rent/core/models/gown_model.dart';
import 'package:smart_rent/core/utils/price_formatter.dart';

/// Universal gown card used in both the admin inventory grid and the
/// client home tab grid.
///
/// Layout:
/// - Image: 160px, [BoxFit.contain] — portrait photos never cropped,
///   letterboxed against [AppColors.surfaceGrey].
/// - Name: up to 2 lines so longer names are not abruptly cut off.
/// - Status badge overlaid on the image bottom-left.
/// - Category and color shown below the price.
/// - No "View Details" button — the entire card is the tap target.
/// - Optional bookmark icon top-right (client only). Pass [onBookmarkTap]
///   to enable it. When null (admin), no bookmark icon is shown.
///
/// Use [mainAxisExtent: 270] in the parent [GridView].
class GownCard extends StatelessWidget {
  final GownModel gown;
  final VoidCallback onTap;

  /// When provided, a bookmark icon is shown top-right of the image.
  /// Pass null for admin inventory where bookmarks are not relevant.
  final VoidCallback? onBookmarkTap;

  /// Whether this gown is currently bookmarked by the user.
  /// Only used when [onBookmarkTap] is non-null.
  final bool isBookmarked;

  const GownCard({
    super.key,
    required this.gown,
    required this.onTap,
    this.onBookmarkTap,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image ───────────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    color: AppColors.surfaceGrey,
                    child: gown.imageUrls.isNotEmpty
                        ? Image.network(
                            gown.imageUrls.first,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),

                // Status badge — bottom-left
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gownStatusColor(gown.status),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppColors.gownStatusLabel(gown.status),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.defaultForeground,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Bookmark icon — top-right (client only)
                if (onBookmarkTap != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onBookmarkTap,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.overlayDark,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: isBookmarked
                              ? AppColors.primary
                              : AppColors.defaultForeground,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Info ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name — up to 2 lines
                  Text(
                    gown.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Price
                  Text(
                    '₱${PriceFormatter.format(gown.rentalPrice)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Category
                  Text(
                    gown.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 1),

                  // Color
                  Text(
                    gown.color,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    return const SizedBox(
      width: double.infinity,
      height: 160,
      child: Icon(
        Icons.checkroom_outlined,
        color: AppColors.border,
        size: 40,
      ),
    );
  }
}
