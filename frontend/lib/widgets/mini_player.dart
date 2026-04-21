import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';
import '../screens/player/full_player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, child) {
        if (audio.currentSong == null) return const SizedBox.shrink();

        final song = audio.currentSong!;
        final progress = audio.duration.inMilliseconds > 0
            ? audio.position.inMilliseconds / audio.duration.inMilliseconds
            : 0.0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(
                top: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: AppTheme.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primary,
                  ),
                  minHeight: 2,
                ),
                SizedBox(
                  height: 58,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: song.coverImage != null
                              ? CachedNetworkImage(
                                  imageUrl:
                                      '${Constants.serverUrl}${song.coverImage}',
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => _defaultArt(),
                                )
                              : _defaultArt(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (song.bandName != null)
                              Text(
                                song.bandName!,
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
                      IconButton(
                        icon: Icon(
                          audio.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppTheme.textPrimary,
                          size: 30,
                        ),
                        onPressed: () {
                          if (audio.isPlaying) {
                            audio.pause();
                          } else {
                            audio.playSong(song);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: AppTheme.textPrimary,
                          size: 26,
                        ),
                        onPressed: () => audio.skipNext(),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _defaultArt() {
    return Container(
      color: AppTheme.cardColor,
      child: const Icon(Icons.music_note, color: AppTheme.textMuted, size: 22),
    );
  }
}
