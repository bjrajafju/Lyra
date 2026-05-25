import 'package:flutter/material.dart';
import 'safe_network_image.dart';
import '../models/album_model.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;

  const AlbumCard({super.key, required this.album, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeNetworkImage(
              imageUrl: album.coverImage,
              width: 160,
              height: 160,
              borderRadius: BorderRadius.circular(10),
              fallbackIcon: Icons.album,
            ),
            const SizedBox(height: 8),
            Text(
              album.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              album.bandName ?? _formatYear(album.releaseDate),
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatYear(String? date) {
    if (date == null) return '';
    try {
      return DateTime.parse(date).year.toString();
    } catch (_) {
      return date;
    }
  }

  Widget _defaultCover() {
    return Container(
      color: AppTheme.cardColor,
      child: const Icon(Icons.album, size: 50, color: AppTheme.textMuted),
    );
  }
}
