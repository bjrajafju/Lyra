import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/safe_network_image.dart';
import '../../models/song_model.dart';
import '../../models/playlist_model.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/band_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/song_card.dart';
import '../../widgets/playlist_card.dart';
import '../playlist/playlist_view_screen.dart';
import 'edit_profile_screen.dart';
import 'invitations_screen.dart';
import '../band/band_profile_screen.dart';
import '../../models/band_model.dart';
import '../band/create_band_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final int? userId;

  // null means own profile
  const UserProfileScreen({super.key, this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? userProfile;
  List<Song> favorites = [];
  List<Playlist> playlists = [];
  List<Band> bands = [];
  bool isLoading = true;
  bool isOwnProfile = false;

  bool _firstLoad = true;
  int? _lastBandId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bandProvider = context.watch<BandProvider>();
    final currentBandId = bandProvider.selectedBand?.id;
    if (_firstLoad || currentBandId != _lastBandId) {
      _firstLoad = false;
      _lastBandId = currentBandId;
      // We load data asynchronously
      Future.microtask(() => _loadData());
    }
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    isOwnProfile = widget.userId == null || widget.userId == auth.user?.id;

    try {
      if (isOwnProfile) {
        final profileRes = await ApiService.get('/auth/profile');
        if (profileRes.statusCode == 200)
          userProfile = jsonDecode(profileRes.body);

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

        final bandsRes = await ApiService.get('/bands/my-bands');
        if (bandsRes.statusCode == 200) {
          bands = (jsonDecode(bandsRes.body) as List)
              .map((b) => Band.fromJson(b))
              .toList();
        }
      } else {
        final profileRes = await ApiService.get('/auth/user/${widget.userId}');
        if (profileRes.statusCode == 200)
          userProfile = jsonDecode(profileRes.body);
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
    if (userProfile == null)
      return const Scaffold(body: Center(child: Text('User not found')));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Perfil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.mail_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvitationsScreen()),
              ),
            ),
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
                _loadData();
              },
            ),
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // Avatar
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.surfaceLight,
              backgroundImage: userProfile!['profile_picture'] != null
                  ? SafeNetworkImage.getProvider(userProfile!['profile_picture'])
                  : null,
              child: userProfile!['profile_picture'] == null
                  ? Text(
                      (userProfile!['username'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              userProfile!['username'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Chip(
              label: Text(
                (userProfile!['role'] ?? 'listener').toString().toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            ),
          ),
          if (userProfile!['bio'] != null &&
              userProfile!['bio'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text(
                userProfile!['bio'],
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          if (!isOwnProfile && userProfile!['follower_count'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${userProfile!['follower_count']} followers',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${userProfile!['following_count']} following',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Favorites
          if (isOwnProfile && favorites.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Músicas Favoritas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            ...favorites.take(5).map((s) => SongCard(song: s)),
            if (favorites.length > 5)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: () {},
                  child: Text('Ver todos os ${favorites.length} favoritos'),
                ),
              ),
          ],

          // Playlists
          if (isOwnProfile && playlists.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'As Tuas Playlists',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            ...playlists.map(
              (p) => PlaylistCard(
                playlist: p,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaylistViewScreen(playlistId: p.id),
                  ),
                ),
              ),
            ),
          ],
          if (isOwnProfile) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'As Tuas Bandas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final created = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateBandScreen(),
                        ),
                      );
                      if (created == true) _loadData();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Criar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (bands.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Ainda não há bandas.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bands.length,
                  itemBuilder: (ctx, i) {
                    final band = bands[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BandProfileScreen(bandId: band.id),
                        ),
                      ),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: SafeNetworkImage(
                                imageUrl: band.profileImage,
                                width: 70,
                                height: 70,
                                fallbackIcon: Icons.groups,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              band.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
