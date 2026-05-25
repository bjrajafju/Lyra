import 'package:flutter/material.dart';
import '../../services/content_service.dart';
import '../../theme/app_theme.dart';
import 'album_reorder_screen.dart';
import 'create_album_screen.dart';
import '../../widgets/safe_network_image.dart';

class ManageAlbumsScreen extends StatefulWidget {
  final int bandId;
  const ManageAlbumsScreen({super.key, required this.bandId});

  @override
  State<ManageAlbumsScreen> createState() => _ManageAlbumsScreenState();
}

class _ManageAlbumsScreenState extends State<ManageAlbumsScreen> {
  List<dynamic> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() => _isLoading = true);
    try {
      final albums = await ContentService.getBandAlbums(
        widget.bandId.toString(),
      );
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
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
        title: const Text('Albums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateAlbumScreen(bandId: widget.bandId),
                ),
              );
              if (result == true) _loadAlbums();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAlbums,
              child: _albums.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: _albums.length,
                      itemBuilder: (context, index) {
                        final album = _albums[index];
                        return _buildAlbumCard(album);
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
          Icon(
            Icons.album_outlined,
            size: 80,
            color: AppTheme.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No albums created yet',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(dynamic album) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AlbumReorderScreen(album: album)),
        );
        if (result == true) _loadAlbums();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.white05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SafeNetworkImage(
                imageUrl: album['cover_image'],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(23),
                ),
                fallbackIcon: Icons.album,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${album['song_count'] ?? 0} tracks',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
