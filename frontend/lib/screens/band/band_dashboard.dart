import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/band_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'upload_song_screen.dart';
import 'create_band_screen.dart';

class BandDashboard extends StatefulWidget {
  const BandDashboard({super.key});

  @override
  State<BandDashboard> createState() => _BandDashboardState();
}

class _BandDashboardState extends State<BandDashboard> {
  List<Band> bands = [];
  Map<String, dynamic>? analytics;
  bool isLoading = true;
  int? selectedBandId;

  @override
  void initState() {
    super.initState();
    _loadBands();
  }

  Future<void> _loadBands() async {
    try {
      final res = await ApiService.get('/bands/my-bands');
      if (res.statusCode == 200) {
        bands = (jsonDecode(res.body) as List).map((b) => Band.fromJson(b)).toList();
        if (bands.isNotEmpty) {
          selectedBandId = bands.first.id;
          await _loadAnalytics(bands.first.id);
        }
      }
    } catch (e) {
      debugPrint('Error loading bands: $e');
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
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadBands,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Artist Dashboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                onPressed: _loadBands,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Band selector
          if (bands.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.group_add, size: 48, color: AppTheme.primary),
                  const SizedBox(height: 12),
                  const Text('No bands yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Create a band to start uploading music', style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final created = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateBandScreen()),
                      );
                      if (created == true) {
                        setState(() => isLoading = true);
                        _loadBands();
                      }
                    },
                    child: const Text('Create Band'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Band tabs
            if (bands.length > 1)
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: bands.length,
                  itemBuilder: (ctx, i) {
                    final band = bands[i];
                    final isSelected = band.id == selectedBandId;
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedBandId = band.id);
                        _loadAnalytics(band.id);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          band.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

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
            ],

            // Top Songs
            if (analytics?['top_songs'] != null && (analytics!['top_songs'] as List).isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Top Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(analytics!['top_songs'] as List).asMap().entries.map((entry) {
                final i = entry.key;
                final song = entry.value;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.surfaceLight,
                    child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ),
                  title: Text(song['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    '${song['play_count'] ?? 0} streams',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),
            // Upload button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadSongScreen(bandId: selectedBandId),
                  ),
                );
              },
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Upload New Song'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
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
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
