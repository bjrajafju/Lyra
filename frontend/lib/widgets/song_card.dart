import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';
import '../screens/song/song_detail_screen.dart';
import 'safe_network_image.dart';
import '../services/api_service.dart';
import '../models/playlist_model.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final bool showDuration;

  const SongCard({super.key, required this.song, this.onTap, this.showDuration = false});

  Future<void> _addToPlaylist(BuildContext context) async {
    try {
      final playlistsRes = await ApiService.get('/playlists/mine');
      if (!context.mounted) return;
      if (playlistsRes.statusCode != 200) return;
      final playlists = (jsonDecode(playlistsRes.body) as List).map((p) => Playlist.fromJson(p)).toList();
      if (playlists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a playlist first')));
        return;
      }
      final selectedId = await showModalBottomSheet<int>(
        context: context,
        builder: (_) => ListView(
          children: playlists
              .map((playlist) => ListTile(
                    title: Text(playlist.title),
                    subtitle: Text('${playlist.songCount} songs'),
                    onTap: () => Navigator.pop(context, playlist.id),
                  ))
              .toList(),
        ),
      );
      if (!context.mounted) return;
      if (selectedId == null) return;
      final addRes = await ApiService.post('/playlists/$selectedId/songs', {'song_id': song.id});
      if (addRes.statusCode == 201 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to playlist')));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SongDetailScreen(songId: song.id)),
        );
      },
      leading: SafeNetworkImage(
        imageUrl: song.coverImage,
        width: 50,
        height: 50,
        borderRadius: BorderRadius.circular(6),
        fallbackIcon: Icons.music_note,
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textMuted),
            onSelected: (value) async {
              if (value == 'add_to_playlist') {
                _addToPlaylist(context);
              } else if (value == 'share') {
                await Clipboard.setData(ClipboardData(text: '${Constants.serverUrl}/songs/${song.id}'));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Song link copied')));
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'add_to_playlist', child: Text('Add to playlist')),
              PopupMenuItem(value: 'share', child: Text('Share')),
            ],
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
