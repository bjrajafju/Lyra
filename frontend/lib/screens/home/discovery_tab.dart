import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/song_model.dart';
import '../../models/band_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/song_card.dart';
import '../../widgets/band_card.dart';
import '../band/band_profile_screen.dart';

class DiscoveryTab extends StatefulWidget {
  const DiscoveryTab({super.key});

  @override
  State<DiscoveryTab> createState() => _DiscoveryTabState();
}

class _DiscoveryTabState extends State<DiscoveryTab> {
  List<Song> trending = [];
  List<Song> newReleases = [];
  List<Band> bands = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDiscovery();
  }

  void fetchDiscovery() async {
    try {
      final res = await ApiService.get('/search/discovery');
      final bandsRes = await ApiService.get('/bands');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        trending = (data['trending'] as List)
            .map((e) => Song.fromJson(e))
            .toList();
        newReleases = (data['newReleases'] as List)
            .map((e) => Song.fromJson(e))
            .toList();
      }
      if (bandsRes.statusCode == 200) {
        bands = (jsonDecode(bandsRes.body) as List)
            .map((b) => Band.fromJson(b))
            .toList();
      }
    } catch (e) {
      debugPrint('Discovery error: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => isLoading = true);
        fetchDiscovery();
      },
      child: ListView(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Descobrir',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Trending section
          if (trending.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                '🔥 Em destaque',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ...trending.map((song) => SongCard(song: song)),
          ],

          // Artists section
          if (bands.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Artistas para ti',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20),
                itemCount: bands.length,
                itemBuilder: (ctx, i) => BandCard(
                  band: bands[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BandProfileScreen(bandId: bands[i].id),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // New releases section
          if (newReleases.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                '✨ Novos lançamentos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ...newReleases.map((song) => SongCard(song: song)),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
