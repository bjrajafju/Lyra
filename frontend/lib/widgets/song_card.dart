import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';
import '../screens/song/song_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final bool showDuration;

  const SongCard({super.key, required this.song, this.onTap, this.showDuration = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SongDetailScreen(songId: song.id)),
        );
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 50,
          height: 50,
          child: song.coverImage != null
              ? CachedNetworkImage(
                  imageUrl: '${Constants.serverUrl}${song.coverImage}',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _defaultCover(),
                )
              : _defaultCover(),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        song.bandName ?? '',
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDuration)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _formatDuration(song.duration),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: AppTheme.primary, size: 34),
            onPressed: () {
              context.read<AudioProvider>().playSong(song);
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Widget _defaultCover() {
    return Container(
      color: AppTheme.cardColor,
      child: const Icon(Icons.music_note, color: AppTheme.textMuted),
    );
  }
}
