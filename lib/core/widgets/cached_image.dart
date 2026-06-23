import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';

/// A drop-in replacement for Image.network that caches images locally.
/// After the first download, images load instantly from disk — zero network calls.
/// Uses zero fade-in duration so cached images appear immediately without flicker.
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // No fade animation — cached images appear instantly
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      // Use a minimal placeholder that doesn't draw attention
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: AppColors.surfaceGrey,
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: AppColors.surfaceGrey,
            child: const Icon(
              Icons.checkroom_outlined,
              color: AppColors.border,
              size: 28,
            ),
          ),
    );
  }
}
