import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/band_model.dart';
import '../../providers/band_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../home/main_screen.dart';
import 'upload_song_screen.dart';
import 'create_band_screen.dart';
import 'song_management_screen.dart';
import 'manage_members_screen.dart';
import 'manage_albums_screen.dart';
import 'band_layout_editor_screen.dart';

class BandDashboard extends StatefulWidget {
  const BandDashboard({super.key});

  @override
  State<BandDashboard> createState() => _BandDashboardState();
}

class _BandDashboardState extends State<BandDashboard> {
  Map<String, dynamic>? analytics;
  bool isLoading = true;
  int? _lastBandId;

  @override
  void initState() {
    super.initState();
    // We'll load data in didChangeDependencies to handle the initial band
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bandProvider = context.watch<BandProvider>();
    final currentBandId = bandProvider.selectedBand?.id;
    
    if (currentBandId != _lastBandId) {
      _lastBandId = currentBandId;
      // Use microtask or Future.delayed to avoid calling setState during build/dependencies change
      Future.microtask(() => _loadData());
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final bandProvider = context.read<BandProvider>();
    final bandId = bandProvider.selectedBand?.id;

    if (bandId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);
    try {
      await _loadAnalytics(bandId);
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _loadAnalytics(int bandId) async {
    try {
      final res = await ApiService.get('/analytics/$bandId');
      if (res.statusCode == 200) {
        analytics = jsonDecode(res.body);
      }
    } catch (_) {
      analytics = null;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bandProvider = context.watch<BandProvider>();
    final selectedBand = bandProvider.selectedBand;

    if (isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Band Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                onPressed: () async {
                  final created = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateBandScreen(),
                    ),
                  );
                  if (created == true) {
                    final bandProvider = context.read<BandProvider>();
                    await bandProvider.fetchContext();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                onPressed: _loadData,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (selectedBand == null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    size: 48,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No band context selected',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a band from the switcher above',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Analytics grid
            if (analytics != null) ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _MetricCard(
                    label: 'Monthly Listeners',
                    value: '${analytics!['monthly_listeners'] ?? 0}',
                    icon: Icons.people_outline,
                    color: AppTheme.primary,
                  ),
                  _MetricCard(
                    label: 'Total Streams',
                    value: '${analytics!['total_streams'] ?? 0}',
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFF4FC3F7),
                  ),
                  _MetricCard(
                    label: 'Total Likes',
                    value: '${analytics!['total_likes'] ?? 0}',
                    icon: Icons.thumb_up_outlined,
                    color: const Color(0xFFFF7043),
                  ),
                  _MetricCard(
                    label: 'Followers',
                    value: '${analytics!['total_followers'] ?? 0}',
                    icon: Icons.favorite_border,
                    color: const Color(0xFFBA68C8),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SmallMetric(
                      label: 'Playlist Adds',
                      value: '${analytics!['playlist_additions'] ?? 0}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SmallMetric(
                      label: 'New Followers (30d)',
                      value: '${analytics!['new_followers_30d'] ?? 0}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (analytics!['streams_over_time'] is List &&
                  (analytics!['streams_over_time'] as List).isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Streams (30d points): ${(analytics!['streams_over_time'] as List).length}  •  Monthly listener points: ${((analytics!['listeners_per_month'] as List?) ?? []).length}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],

            // Top Songs
            if (analytics?['top_songs'] != null &&
                (analytics!['top_songs'] as List).isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Top Songs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(analytics!['top_songs'] as List).asMap().entries.map((entry) {
                final i = entry.key;
                final song = entry.value;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.surfaceLight,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    song['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${song['play_count'] ?? 0} streams',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                );
              }),
            ],
            if (analytics?['recent_activity'] != null &&
                (analytics!['recent_activity'] as List).isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(analytics!['recent_activity'] as List)
                  .take(6)
                  .map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.bolt,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                      title: Text(
                        '${item['type']} • ${item['song_title'] ?? ''}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
            ],

            const SizedBox(height: 24),
            // Primary Actions Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedBand == null
                        ? null
                        : () {
                            MainScreen.globalBandIndex = 1; // Go to Songs tab
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    UploadSongScreen(bandId: selectedBand.id),
                              ),
                            );
                          },
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectedBand == null
                        ? null
                        : () {
                            MainScreen.globalBandIndex = 4; // Go to Members tab
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ManageMembersScreen(
                                  bandId: selectedBand.id,
                                  currentUserRole: selectedBand.roleInBand ?? 'member',
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.people_outline),
                    label: const Text('Members'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Secondary Actions Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectedBand == null
                        ? null
                        : () {
                            MainScreen.globalBandIndex = 2; // Go to Albums tab
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ManageAlbumsScreen(bandId: selectedBand.id),
                              ),
                            );
                          },
                    icon: const Icon(Icons.album_outlined),
                    label: const Text('Albums'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectedBand == null
                        ? null
                        : () {
                            MainScreen.globalBandIndex = 1; // Go to Songs tab
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SongManagementScreen(bandId: selectedBand.id),
                              ),
                            );
                          },
                    icon: const Icon(Icons.library_music_outlined),
                    label: const Text('Songs'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
    // Layout Row
            OutlinedButton.icon(
              onPressed: selectedBand == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BandProfileScreen(bandId: selectedBand.id),
                      ),
                    ),
              icon: const Icon(Icons.remove_red_eye_outlined),
              label: const Text('View Public Profile'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
            // Layout Editor
            OutlinedButton.icon(
              onPressed: selectedBand == null
                  ? null
                  : () {
                      MainScreen.globalBandIndex = 3; // Go to Layout tab
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BandLayoutEditorScreen(bandId: selectedBand.id),
                        ),
                      );
                    },
              icon: const Icon(Icons.dashboard_customize_outlined),
              label: const Text('Edit Profile Layout'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final String label;
  final String value;
  const _SmallMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
