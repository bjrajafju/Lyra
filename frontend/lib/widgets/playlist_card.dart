import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/playlist_model.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;

  const PlaylistCard({super.key, required this.playlist, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 70,
                height: 70,
                child: playlist.coverImage != null
                    ? CachedNetworkImage(
                        imageUrl: '${Constants.serverUrl}${playlist.coverImage}',
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _defaultCover(),
                      )
                    : _defaultCover(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.songCount} songs${playlist.creatorName != null ? ' • ${playlist.creatorName}' : ''}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultCover() {
    return Container(
      color: AppTheme.cardColor,
      child: const Icon(Icons.queue_music, size: 30, color: AppTheme.textMuted),
    );
  }
}
