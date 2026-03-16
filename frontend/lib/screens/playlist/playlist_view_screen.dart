import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/playlist_model.dart';
import '../../services/api_service.dart';
import '../../providers/audio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/song_card.dart';

class PlaylistViewScreen extends StatefulWidget {
  final int playlistId;
  const PlaylistViewScreen({super.key, required this.playlistId});

  @override
  State<PlaylistViewScreen> createState() => _PlaylistViewScreenState();
}

class _PlaylistViewScreenState extends State<PlaylistViewScreen> {
  Playlist? playlist;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    try {
      final res = await ApiService.get('/playlists/${widget.playlistId}');
      if (res.statusCode == 200) {
        playlist = Playlist.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _removeSong(int songId) async {
    try {
      await ApiService.delete('/playlists/${widget.playlistId}/songs/$songId');
      _loadPlaylist();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (playlist == null) return const Scaffold(body: Center(child: Text('Playlist not found')));

    final auth = context.read<AuthProvider>();
    final isOwner = auth.user?.id == playlist!.creatorId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(playlist!.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (playlist!.coverImage != null)
                    CachedNetworkImage(
                      imageUrl: '${Constants.serverUrl}${playlist!.coverImage}',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _defaultBg(),
                    )
                  else
                    _defaultBg(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.background.withValues(alpha: 0.9)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (playlist!.description != null && playlist!.description!.isNotEmpty)
                    Text(playlist!.description!, style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${playlist!.songs?.length ?? 0} songs • ${playlist!.creatorName ?? ''}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      if (playlist!.isPublic)
                        const Icon(Icons.public, size: 14, color: AppTheme.textMuted)
                      else
                        const Icon(Icons.lock, size: 14, color: AppTheme.textMuted),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (playlist!.songs != null && playlist!.songs!.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AudioProvider>().playQueue(playlist!.songs!);
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play All'),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (playlist!.songs != null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = playlist!.songs![index];
                  return Dismissible(
                    key: Key('song-${song.id}'),
                    direction: isOwner ? DismissDirection.endToStart : DismissDirection.none,
                    onDismissed: (_) => _removeSong(song.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      color: AppTheme.error,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: SongCard(song: song, showDuration: true),
                  );
                },
                childCount: playlist!.songs!.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _defaultBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), AppTheme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.queue_music, size: 80, color: AppTheme.textMuted),
    );
  }
}
