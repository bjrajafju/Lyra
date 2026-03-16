import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/audio_provider.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AudioProvider>(
        builder: (context, audio, _) {
          final song = audio.currentSong;
          if (song == null) {
            return const Center(child: Text('No song playing'));
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.3),
                  AppTheme.background,
                  AppTheme.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Column(
                          children: [
                            const Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            if (song.bandName != null)
                              Text(
                                song.bandName!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  // Album art
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: Hero(
                        tag: 'album-art-${song.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: song.coverImage != null
                                ? CachedNetworkImage(
                                    imageUrl: '${Constants.serverUrl}${song.coverImage}',
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _defaultArt(),
                                  )
                                : _defaultArt(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Song info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.bandName ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_border, color: AppTheme.primary),
                          iconSize: 28,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Seek bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.primary,
                            inactiveTrackColor: AppTheme.textMuted.withValues(alpha: 0.3),
                            thumbColor: AppTheme.primary,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            min: 0,
                            max: audio.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                            value: audio.position.inMilliseconds.toDouble().clamp(0, audio.duration.inMilliseconds.toDouble().clamp(1, double.infinity)),
                            onChanged: (value) {
                              audio.seek(Duration(milliseconds: value.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(audio.position),
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                              Text(
                                _formatDuration(audio.duration),
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: audio.shuffle ? AppTheme.primary : AppTheme.textSecondary,
                          ),
                          onPressed: () => audio.toggleShuffle(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, size: 38),
                          color: AppTheme.textPrimary,
                          onPressed: () => audio.skipPrevious(),
                        ),
                        Container(
                          width: 66,
                          height: 66,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.textPrimary,
                          ),
                          child: IconButton(
                            icon: Icon(
                              audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 38,
                              color: AppTheme.background,
                            ),
                            onPressed: () {
                              if (audio.isPlaying) {
                                audio.pause();
                              } else {
                                audio.playSong(song);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 38),
                          color: AppTheme.textPrimary,
                          onPressed: () => audio.skipNext(),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.repeat_rounded,
                            color: audio.repeat ? AppTheme.primary : AppTheme.textSecondary,
                          ),
                          onPressed: () => audio.toggleRepeat(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _defaultArt() {
    return Container(
      color: AppTheme.cardColor,
      child: const Icon(Icons.music_note, size: 80, color: AppTheme.textMuted),
    );
  }
}
