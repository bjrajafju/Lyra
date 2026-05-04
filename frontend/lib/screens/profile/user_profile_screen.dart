import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/song_model.dart';
import '../../models/playlist_model.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/song_card.dart';
import '../../widgets/playlist_card.dart';
import '../playlist/playlist_view_screen.dart';
import 'edit_profile_screen.dart';
import 'invitations_screen.dart';

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
  bool isLoading = true;
  bool isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _loadData();
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
        title: const Text('Profile'),
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
                  ? CachedNetworkImageProvider(
                      '${Constants.serverUrl}${userProfile!['profile_picture']}',
                    )
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
                'Favourite Songs',
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
                  child: Text('See all ${favorites.length} favorites'),
                ),
              ),
          ],

          // Playlists
          if (isOwnProfile && playlists.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Your Playlists',
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
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
