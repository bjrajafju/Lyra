import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/album_model.dart';
import '../../services/api_service.dart';
import '../../providers/audio_provider.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/song_card.dart';

class AlbumViewScreen extends StatefulWidget {
  final int albumId;
  const AlbumViewScreen({super.key, required this.albumId});

  @override
  State<AlbumViewScreen> createState() => _AlbumViewScreenState();
}

class _AlbumViewScreenState extends State<AlbumViewScreen> {
  Album? album;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbum();
  }

  Future<void> _loadAlbum() async {
    try {
      final res = await ApiService.get('/albums/${widget.albumId}');
      if (res.statusCode == 200) {
        album = Album.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (album == null)
      return const Scaffold(body: Center(child: Text('Album not found')));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                album!.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (album!.coverImage != null)
                    CachedNetworkImage(
                      imageUrl: '${Constants.serverUrl}${album!.coverImage}',
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
                        colors: [
                          Colors.transparent,
                          AppTheme.background.withValues(alpha: 0.9),
                        ],
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
                  if (album!.bandName != null)
                    Text(
                      album!.bandName!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  if (album!.releaseDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Released ${album!.releaseDate}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (album!.description != null &&
                      album!.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      album!.description!,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '${album!.songs?.length ?? 0} tracks',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(width: 16),
                      if (album!.songs != null && album!.songs!.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<AudioProvider>().playQueue(
                              album!.songs!,
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text('Play All'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (album!.songs != null)
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final song = album!.songs![index];
                return SongCard(song: song, showDuration: true);
              }, childCount: album!.songs!.length),
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
          colors: [Color(0xFF0D47A1), AppTheme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.album, size: 80, color: AppTheme.textMuted),
    );
  }
}
