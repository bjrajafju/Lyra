import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/song_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../song/edit_song_screen.dart';

class SongManagementScreen extends StatefulWidget {
  final int bandId;
  const SongManagementScreen({super.key, required this.bandId});

  @override
  State<SongManagementScreen> createState() => _SongManagementScreenState();
}

class _SongManagementScreenState extends State<SongManagementScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/songs/mine?band_id=${widget.bandId}');
      if (res.statusCode == 200) {
        final rows = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        _songs = rows.map(Song.fromJson).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteSong(Song song) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete song?'),
            content: Text('This will permanently remove "${song.title}".'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    await ApiService.delete('/songs/${song.id}');
    _loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Song Management')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSongs,
              child: _songs.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        const Center(child: Text('No songs found', style: TextStyle(color: AppTheme.textMuted))),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _songs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.divider),
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        return ListTile(
                          title: Text(song.title),
                          subtitle: Text(
                            'Streams ${song.playCount}  •  Likes ${song.likeCount}  •  In playlists ${song.playlistAdditions}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final updated = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(builder: (_) => EditSongScreen(song: song)),
                                );
                                if (updated == true) _loadSongs();
                              } else if (value == 'delete') {
                                _deleteSong(song);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
