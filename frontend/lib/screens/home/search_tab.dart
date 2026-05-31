import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/song_model.dart';
import '../../models/band_model.dart';
import '../../models/playlist_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/song_card.dart';
import '../../widgets/band_card.dart';
import '../../widgets/playlist_card.dart';
import '../band/band_profile_screen.dart';
import '../playlist/playlist_view_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Song> songResults = [];
  List<Band> bandResults = [];
  List<Playlist> playlistResults = [];
  bool isLoading = false;
  bool hasSearched = false;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          songResults = [];
          bandResults = [];
          playlistResults = [];
          hasSearched = false;
        });
        return;
      }

      setState(() => isLoading = true);
      try {
        final res = await ApiService.get('/search?q=$query');
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            songResults = (data['songs'] as List)
                .map((s) => Song.fromJson(s))
                .toList();
            bandResults = (data['bands'] as List)
                .map((b) => Band.fromJson(b))
                .toList();
            playlistResults = (data['playlists'] as List)
                .map((p) => Playlist.fromJson(p))
                .toList();
            hasSearched = true;
          });
        }
      } catch (e) {
        debugPrint('Search error: $e');
      } finally {
        setState(() => isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Procurar músicas, artistas, playlists...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        if (isLoading)
          const LinearProgressIndicator(color: AppTheme.primary, minHeight: 2),
        Expanded(
          child: !hasSearched
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: AppTheme.textMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Procurar música',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    // Bands results
                    if (bandResults.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          'Artistas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 16),
                          itemCount: bandResults.length,
                          itemBuilder: (ctx, i) => BandCard(
                            band: bandResults[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BandProfileScreen(
                                  bandId: bandResults[i].id,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Songs results
                    if (songResults.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          'Músicas (${songResults.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...songResults.map((song) => SongCard(song: song)),
                    ],

                    // Playlists results
                    if (playlistResults.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          'Listas de reprodução',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...playlistResults.map(
                        (p) => PlaylistCard(
                          playlist: p,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlaylistViewScreen(playlistId: p.id),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // No results
                    if (songResults.isEmpty &&
                        bandResults.isEmpty &&
                        playlistResults.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: AppTheme.textMuted,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Nenhum resultado encontrado',
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
        ),
      ],
    );
  }
}
