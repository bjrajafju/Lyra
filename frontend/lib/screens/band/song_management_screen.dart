import 'package:flutter/material.dart';
import '../../models/song_model.dart';
import '../../services/content_service.dart';
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
      final rows = await ContentService.getBandSongs(widget.bandId.toString());
      setState(() {
        _songs = rows.map((s) => Song.fromJson(s)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleStatus(Song song) async {
    try {
      await ContentService.toggleSongStatus(song.id.toString());
      _loadSongs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete song?'),
        content: Text('This will permanently remove "${song.title}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;
    try {
      await ContentService.deleteSong(song.id.toString());
      _loadSongs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Music')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSongs,
              child: _songs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        return _buildSongCard(song);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off_outlined, size: 80, color: AppTheme.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('No songs uploaded yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildSongCard(Song song) {
    final isPublished = song.status == 'published';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white05),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: song.coverImage != null
                    ? DecorationImage(image: NetworkImage(song.coverImage!), fit: BoxFit.cover)
                    : null,
                color: AppTheme.surfaceLight,
              ),
              child: song.coverImage == null ? const Icon(Icons.music_note) : null,
            ),
            title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${song.playCount} streams • ${song.likeCount} likes',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
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
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Info')),
                const PopupMenuItem(value: 'delete', child: Text('Delete Song', style: TextStyle(color: AppTheme.error))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPublished ? AppTheme.success : Colors.orange).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (isPublished ? AppTheme.success : Colors.orange).withValues(alpha: 0.3)),
                ),
                child: Text(
                  isPublished ? 'PUBLISHED' : 'DRAFT',
                  style: TextStyle(
                    color: isPublished ? AppTheme.success : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    isPublished ? 'Unpublish' : 'Publish',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: isPublished,
                    onChanged: (_) => _toggleStatus(song),
                    activeColor: AppTheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
