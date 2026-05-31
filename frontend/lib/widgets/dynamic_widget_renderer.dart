import 'package:flutter/material.dart';
import '../models/widget_type.dart';
import '../models/song_model.dart';
import '../models/album_model.dart';
import '../models/band_model.dart';
import '../theme/app_theme.dart';
import 'song_card.dart';
import 'album_card.dart';
import '../screens/album/album_view_screen.dart';

class DynamicWidgetRenderer extends StatelessWidget {
  final Map<String, dynamic> widgetData;
  final List<Song> songs;
  final List<Album> albums;
  final Band? band;
  final bool isPreview;
  final VoidCallback? onDelete;
  final VoidCallback? onSettings;

  const DynamicWidgetRenderer({
    super.key,
    required this.widgetData,
    this.songs = const [],
    this.albums = const [],
    this.band,
    this.isPreview = false,
    this.onDelete,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final typeCode = widgetData['type'] as String;
    final type = WidgetType.fromCode(typeCode);
    final settings = widgetData['settings'] ?? {};
    final title = settings['title'] ?? type.label;

    Widget content;
    switch (type) {
      case WidgetType.latestReleases:
        final latestSongs = List<Song>.from(songs)..sort((a, b) => b.id.compareTo(a.id));
        content = Column(
          children: latestSongs.take(3).map((s) => SongCard(song: s)).toList(),
        );
        break;
      case WidgetType.popularSongs:
        // Assuming songs are already sorted by popularity from API or just take first 5
        content = Column(
          children: songs.take(5).map((s) => SongCard(song: s)).toList(),
        );
        break;
      case WidgetType.albums:
        if (albums.isEmpty) {
          content = const Text('0 Albums Dispoíveis', style: TextStyle(color: AppTheme.textMuted));
        } else {
          content = SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: albums.length,
              itemBuilder: (ctx, i) => AlbumCard(
                album: albums[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AlbumViewScreen(albumId: albums[i].id)),
                ),
              ),
            ),
          );
        }
        break;
      case WidgetType.bio:
        content = Text(
          settings['content'] ?? band?.description ?? 'No biography available.',
          style: const TextStyle(color: AppTheme.textSecondary),
        );
        break;
      case WidgetType.members:
        if (band?.members == null || band!.members!.isEmpty) {
          content = const Text('No members listed', style: TextStyle(color: AppTheme.textMuted));
        } else {
          content = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: band!.members!.map((m) => Chip(
              avatar: CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Text(m.username[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              label: Text('${m.username} • ${m.role ?? "Member"}'),
            )).toList(),
          );
        }
        break;
      case WidgetType.socialLinks:
        content = const Text('Social links widget coming soon...', style: TextStyle(color: AppTheme.textMuted));
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (isPreview)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings, size: 20),
                      onPressed: onSettings,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                      onPressed: onDelete,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}
