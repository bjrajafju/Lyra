import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.music_note,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final absoluteUrl = Constants.imageUrl(imageUrl);

    if (absoluteUrl.isEmpty) {
      return _buildFallback();
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: absoluteUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: AppTheme.surfaceLight,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildFallback(),
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: AppTheme.textMuted,
          size: (width != null && width! < 50) ? 20 : 32,
        ),
      ),
    );
  }

  static ImageProvider getProvider(String? imageUrl, {IconData fallbackIcon = Icons.music_note}) {
    final absoluteUrl = Constants.imageUrl(imageUrl);
    if (absoluteUrl.isEmpty) {
      return const AssetImage('assets/images/default_cover.png'); // fallback asset if exists
    }
    return CachedNetworkImageProvider(absoluteUrl);
  }
}
