import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/safe_network_image.dart';
import '../../models/band_model.dart';
import '../../models/song_model.dart';
import '../../models/album_model.dart';
import '../../services/api_service.dart';
import '../../providers/audio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/song_card.dart';
import '../../widgets/album_card.dart';
import '../../widgets/dynamic_widget_renderer.dart';
import '../album/album_view_screen.dart';

class BandProfileScreen extends StatefulWidget {
  final int bandId;
  const BandProfileScreen({super.key, required this.bandId});

  @override
  State<BandProfileScreen> createState() => _BandProfileScreenState();
}

class _BandProfileScreenState extends State<BandProfileScreen> {
  Band? band;
  List<Song> songs = [];
  List<Album> albums = [];
  List<dynamic> widgets = [];
  bool isLoading = true;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final bandRes = await ApiService.get('/bands/${widget.bandId}');
      final songsRes = await ApiService.get('/songs?band_id=${widget.bandId}');
      final albumsRes = await ApiService.get(
        '/albums?band_id=${widget.bandId}',
      );
      final layoutRes = await ApiService.get('/bands/${widget.bandId}/widgets');

      if (bandRes.statusCode == 200) {
        band = Band.fromJson(jsonDecode(bandRes.body));
      }
      if (songsRes.statusCode == 200) {
        songs = (jsonDecode(songsRes.body) as List)
            .map((s) => Song.fromJson(s))
            .toList();
      }
      if (albumsRes.statusCode == 200) {
        albums = (jsonDecode(albumsRes.body) as List)
            .map((a) => Album.fromJson(a))
            .toList();
      }
      if (layoutRes.statusCode == 200) {
        widgets = jsonDecode(layoutRes.body);
      }

      // Check follow status
      try {
        final statusRes = await ApiService.get(
          '/interactions/status?band_id=${widget.bandId}',
        );
        if (statusRes.statusCode == 200) {
          isFollowing = jsonDecode(statusRes.body)['following_band'] ?? false;
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error loading band: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _toggleFollow() async {
    try {
      await ApiService.post('/interactions/follow', {
        'followed_id': widget.bandId,
        'followed_type': 'band',
      });
      setState(() => isFollowing = !isFollowing);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (band == null)
      return const Scaffold(body: Center(child: Text('Band not found')));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                band!.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (band!.bannerImage != null)
                    SafeNetworkImage(
                      imageUrl: band!.bannerImage,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.image,
                    )
                  else
                    _gradientBg(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileInfo(),
                    const SizedBox(height: 16),
                    _buildHeaderActions(),
                    const SizedBox(height: 24),
                    ..._buildWidgets(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: AppTheme.surfaceLight,
          backgroundImage: band!.profileImage != null
              ? SafeNetworkImage.getProvider(band!.profileImage)
              : null,
          child: band!.profileImage == null
              ? const Icon(
                  Icons.group,
                  size: 30,
                  color: AppTheme.textMuted,
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatItem(
                    '${band!.followerCount}',
                    'Followers',
                  ),
                  const SizedBox(width: 24),
                  _StatItem('${band!.totalStreams}', 'Streams'),
                  const SizedBox(width: 24),
                  _StatItem('${songs.length}', 'Songs'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        if (context.read<AuthProvider>().isAuthenticated)
          OutlinedButton(
            onPressed: _toggleFollow,
            style: OutlinedButton.styleFrom(
              backgroundColor: isFollowing
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : null,
              side: BorderSide(
                color: isFollowing
                    ? AppTheme.primary
                    : AppTheme.textSecondary,
              ),
            ),
            child: Text(isFollowing ? 'Following' : 'Follow'),
          ),
        const SizedBox(width: 12),
        if (songs.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () {
              context.read<AudioProvider>().playQueue(songs);
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Play All'),
          ),
      ],
    );
  }

  List<Widget> _buildWidgets() {
    if (widgets.isEmpty) {
      // Fallback to default layout if no widgets configured
      return [
        if (band!.description != null && band!.description!.isNotEmpty)
          DynamicWidgetRenderer(
            widgetData: const {'type': 'bio', 'settings': {'title': 'About'}},
            band: band,
          ),
        DynamicWidgetRenderer(
          widgetData: const {'type': 'popular_songs'},
          songs: songs,
        ),
        if (albums.isNotEmpty)
          DynamicWidgetRenderer(
            widgetData: const {'type': 'albums'},
            albums: albums,
          ),
      ];
    }

    return widgets
        .map((w) => DynamicWidgetRenderer(
              widgetData: w,
              songs: songs,
              albums: albums,
              band: band,
            ))
        .toList();
  }

  Widget _gradientBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
