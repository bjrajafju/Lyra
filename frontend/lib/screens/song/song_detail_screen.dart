import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/safe_network_image.dart';
import '../../models/song_model.dart';
import '../../models/comment_model.dart';
import '../../services/api_service.dart';
import '../../providers/audio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';

class SongDetailScreen extends StatefulWidget {
  final int songId;
  const SongDetailScreen({super.key, required this.songId});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  Song? song;
  List<Comment> comments = [];
  bool isLoading = true;
  bool liked = false;
  bool favorited = false;
  final commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final songRes = await ApiService.get('/songs/${widget.songId}');
      final commentsRes = await ApiService.get(
        '/comments/song/${widget.songId}',
      );

      if (songRes.statusCode == 200) {
        song = Song.fromJson(jsonDecode(songRes.body));
      }
      if (commentsRes.statusCode == 200) {
        comments = (jsonDecode(commentsRes.body) as List)
            .map((c) => Comment.fromJson(c))
            .toList();
      }

      // Check interaction status
      try {
        final statusRes = await ApiService.get(
          '/interactions/status?song_id=${widget.songId}',
        );
        if (statusRes.statusCode == 200) {
          final status = jsonDecode(statusRes.body);
          liked = status['liked'] ?? false;
          favorited = status['favorited'] ?? false;
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error loading song: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _toggleLike() async {
    try {
      await ApiService.post('/interactions/like', {'song_id': widget.songId});
      setState(() => liked = !liked);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    try {
      await ApiService.post('/interactions/favorite', {
        'song_id': widget.songId,
      });
      setState(() => favorited = !favorited);
    } catch (_) {}
  }

  Future<void> _addComment() async {
    if (commentController.text.trim().isEmpty) return;
    try {
      final res = await ApiService.post('/comments', {
        'song_id': widget.songId,
        'text': commentController.text.trim(),
      });
      if (res.statusCode == 201) {
        commentController.clear();
        _loadData();
      }
    } catch (_) {}
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      await ApiService.delete('/comments/$commentId');
      _loadData();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (song == null) {
      return const Scaffold(body: Center(child: Text('Song not found')));
    }

    final auth = context.read<AuthProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (song!.coverImage != null)
                    SafeNetworkImage(
                      imageUrl: song!.coverImage,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: AppTheme.cardColor,
                      child: const Icon(
                        Icons.music_note,
                        size: 80,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.background.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song!.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    song!.bandName ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (song!.genre != null) ...[
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(song!.genre!),
                      backgroundColor: AppTheme.surfaceLight,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      _ActionButton(
                        icon: liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        label: '${song!.likeCount + (liked ? 1 : 0)}',
                        color: liked
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        onTap: _toggleLike,
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: favorited
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: favorited ? 'Saved' : 'Save',
                        color: favorited
                            ? Colors.redAccent
                            : AppTheme.textSecondary,
                        onTap: _toggleFavorite,
                      ),
                      const Spacer(),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.play_arrow_rounded, size: 32),
                          color: Colors.white,
                          onPressed: () {
                            context.read<AudioProvider>().playSong(song!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stats
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${song!.playCount} plays',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (song!.description != null &&
                      song!.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      song!.description!,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 16),

                  // Comments
                  Text(
                    'Comentários (${comments.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (auth.isAuthenticated)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                            ),
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send, color: AppTheme.primary),
                          onPressed: _addComment,
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final comment = comments[index];
              final canDelete = auth.user?.id == comment.userId;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.surfaceLight,
                  child: Text(
                    comment.username.isNotEmpty
                        ? comment.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: AppTheme.primary),
                  ),
                ),
                title: Text(
                  comment.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  comment.text,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                trailing: canDelete
                    ? IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => _deleteComment(comment.id),
                      )
                    : null,
              );
            }, childCount: comments.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
