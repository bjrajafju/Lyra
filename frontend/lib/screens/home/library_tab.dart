import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song_model.dart';
import '../../models/playlist_model.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/song_card.dart';
import '../../widgets/playlist_card.dart';
import '../band/band_dashboard.dart';
import '../playlist/playlist_view_screen.dart';
import '../playlist/create_playlist_screen.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Song> favorites = [];
  List<Playlist> playlists = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final isArtist = auth.user?.role == 'artist';
    _tabController = TabController(length: isArtist ? 3 : 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final favRes = await ApiService.get('/interactions/favorites');
      if (favRes.statusCode == 200) {
        favorites = (jsonDecode(favRes.body) as List)
            .map((s) => Song.fromJson(s))
            .toList();
      }
      final playRes = await ApiService.get('/playlists/mine');
      if (playRes.statusCode == 200) {
        playlists = (jsonDecode(playRes.body) as List)
            .map((p) => Playlist.fromJson(p))
            .toList();
      }
    } catch (e) {
      debugPrint('Library error: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isArtist = auth.user?.role == 'artist';

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: [
            const Tab(text: 'Favorites'),
            const Tab(text: 'Playlists'),
            if (isArtist) const Tab(text: 'Dashboard'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Favorites
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : favorites.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 48,
                            color: AppTheme.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No favorites yet',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Save songs you love!',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        itemCount: favorites.length,
                        itemBuilder: (ctx, i) => SongCard(song: favorites[i]),
                      ),
                    ),

              // Playlists
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${playlists.length} playlists',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final created = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CreatePlaylistScreen(),
                                    ),
                                  );
                                  if (created == true) _loadData();
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('New'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: playlists.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.queue_music,
                                        size: 48,
                                        color: AppTheme.textMuted,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No playlists yet',
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadData,
                                  child: ListView.builder(
                                    itemCount: playlists.length,
                                    itemBuilder: (ctx, i) => PlaylistCard(
                                      playlist: playlists[i],
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PlaylistViewScreen(
                                            playlistId: playlists[i].id,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),

              // Dashboard (artist only)
              if (isArtist) const BandDashboard(),
            ],
          ),
        ),
      ],
    );
  }
}
