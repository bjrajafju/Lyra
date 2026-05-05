import 'package:flutter/material.dart';
import '../../services/content_service.dart';
import '../../theme/app_theme.dart';

class AlbumReorderScreen extends StatefulWidget {
  final dynamic album;
  const AlbumReorderScreen({super.key, required this.album});

  @override
  State<AlbumReorderScreen> createState() => _AlbumReorderScreenState();
}

class _AlbumReorderScreenState extends State<AlbumReorderScreen> {
  List<dynamic> _songs = [];
  bool _isLoading = true;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await ContentService.getAlbumSongs(
        widget.album['id'].toString(),
      );
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveOrder() async {
    setState(() => _isLoading = true);
    try {
      final orders = _songs
          .asMap()
          .entries
          .map((e) => {'id': e.value['id'] as int, 'position': e.key + 1})
          .toList();

      await ContentService.reorderAlbumSongs(
        widget.album['id'].toString(),
        orders,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order saved!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album['title'] ?? 'Reorder Songs'),
        actions: [
          if (_hasChanged)
            TextButton(
              onPressed: _isLoading ? null : _saveOrder,
              child: const Text(
                'SAVE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Drag and drop to reorder tracks',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _songs.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _songs.removeAt(oldIndex);
                        _songs.insert(newIndex, item);
                        _hasChanged = true;
                      });
                    },
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      return _buildSongTile(song, index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSongTile(dynamic song, int index) {
    return Container(
      key: ValueKey(song['id']),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.white05),
      ),
      child: ListTile(
        leading: Text(
          '${index + 1}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
          ),
        ),
        title: Text(song['title'] ?? 'Untitled'),
        trailing: const Icon(Icons.drag_indicator, color: AppTheme.textMuted),
      ),
    );
  }
}
