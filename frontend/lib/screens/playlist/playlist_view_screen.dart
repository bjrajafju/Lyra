import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/playlist_model.dart';
import '../../services/api_service.dart';
import '../../providers/audio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/song_card.dart';

class PlaylistViewScreen extends StatefulWidget {
  final int playlistId;
  const PlaylistViewScreen({super.key, required this.playlistId});

  @override
  State<PlaylistViewScreen> createState() => _PlaylistViewScreenState();
}

class _PlaylistViewScreenState extends State<PlaylistViewScreen> {
  Playlist? playlist;
  bool isLoading = true;
  bool isEditingOrder = false;
  bool isSavingOrder = false;
  late List<dynamic> _editableSongs;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    if (mounted) {
      setState(() => isLoading = true);
    }
    try {
      final res = await ApiService.get('/playlists/${widget.playlistId}');
      if (res.statusCode == 200) {
        playlist = Playlist.fromJson(jsonDecode(res.body));
        _editableSongs = List<dynamic>.from(playlist?.songs ?? []);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _removeSong(int songId) async {
    try {
      await ApiService.delete('/playlists/${widget.playlistId}/songs/$songId');
      _loadPlaylist();
    } catch (_) {}
  }

  Future<void> _addSongPrompt() async {
    final songIdController = TextEditingController();
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add song to playlist'),
        content: TextField(
          controller: songIdController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Song ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (shouldAdd != true) return;
    await ApiService.post('/playlists/${widget.playlistId}/songs', {
      'song_id': int.tryParse(songIdController.text.trim()),
    });
    _loadPlaylist();
  }

  Future<void> _savePlaylistOrder() async {
    if (playlist?.songs == null) return;
    setState(() => isSavingOrder = true);
    try {
      final songIds = _editableSongs.map((song) => song.id).toList();
      final res = await ApiService.put(
        '/playlists/${widget.playlistId}/songs/reorder',
        {'song_ids': songIds},
      );
      if (res.statusCode == 200 && mounted) {
        setState(() => isEditingOrder = false);
        _loadPlaylist();
      }
    } catch (_) {}
    if (mounted) setState(() => isSavingOrder = false);
  }

  Future<void> _editPlaylistMetadata() async {
    if (playlist == null) return;
    final titleController = TextEditingController(text: playlist!.title);
    final descController = TextEditingController(
      text: playlist!.description ?? '',
    );
    bool isPublic = playlist!.isPublic;
    PlatformFile? cover;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit playlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                SwitchListTile(
                  value: isPublic,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => isPublic = val),
                  title: const Text('Public playlist'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null) {
                      setDialogState(() => cover = result.files.first);
                    }
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: Text(cover?.name ?? 'Change cover image'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave != true) return;
    final fields = {
      'title': titleController.text.trim(),
      'description': descController.text.trim(),
      'is_public': isPublic.toString(),
    };
    final files = cover == null
        ? null
        : {
            'cover_image': MultipartFileData(
              bytes: cover!.bytes,
              path: kIsWeb ? null : cover!.path,
              filename: cover!.name,
            ),
          };

    await ApiService.multipartRequest(
      method: 'PUT',
      endpoint: '/playlists/${widget.playlistId}',
      fields: fields,
      files: files,
    );
    _loadPlaylist();
  }

  Future<void> _deletePlaylist() async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete playlist?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;
    await ApiService.delete('/playlists/${widget.playlistId}');
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (playlist == null)
      return const Scaffold(body: Center(child: Text('Playlist not found')));

    final auth = context.read<AuthProvider>();
    final isOwner = auth.user?.id == playlist!.creatorId;

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist!.title),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editPlaylistMetadata();
                if (value == 'add') _addSongPrompt();
                if (value == 'reorder')
                  setState(() => isEditingOrder = !isEditingOrder);
                if (value == 'share') {
                  Clipboard.setData(
                    ClipboardData(
                      text: '${Constants.serverUrl}/playlists/${playlist!.id}',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist link copied')),
                  );
                }
                if (value == 'delete') _deletePlaylist();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit playlist'),
                ),
                const PopupMenuItem(
                  value: 'add',
                  child: Text('Add song by ID'),
                ),
                PopupMenuItem(
                  value: 'reorder',
                  child: Text(
                    isEditingOrder ? 'Cancel reorder' : 'Reorder songs',
                  ),
                ),
                const PopupMenuItem(value: 'share', child: Text('Share')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete playlist'),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (playlist!.coverImage != null)
                  CachedNetworkImage(
                    imageUrl: '${Constants.serverUrl}${playlist!.coverImage}',
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _defaultBg(),
                  )
                else
                  _defaultBg(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.background.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (playlist!.description != null &&
                    playlist!.description!.isNotEmpty)
                  Text(
                    playlist!.description!,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                const SizedBox(height: 6),
                Text(
                  '${playlist!.songs?.length ?? 0} songs • ${playlist!.creatorName ?? ''}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          playlist!.songs == null || playlist!.songs!.isEmpty
                          ? null
                          : () => context.read<AudioProvider>().playQueue(
                              playlist!.songs!,
                            ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play all'),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      playlist!.isPublic ? Icons.public : Icons.lock,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isEditingOrder && isOwner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: isSavingOrder ? null : _savePlaylistOrder,
                icon: const Icon(Icons.save_outlined),
                label: Text(isSavingOrder ? 'Saving...' : 'Save order'),
              ),
            ),
          const SizedBox(height: 8),
          if (playlist!.songs != null && playlist!.songs!.isNotEmpty)
            if (isEditingOrder && isOwner)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _editableSongs.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final moved = _editableSongs.removeAt(oldIndex);
                    _editableSongs.insert(newIndex, moved);
                  });
                },
                itemBuilder: (context, index) {
                  final song = _editableSongs[index];
                  return ListTile(
                    key: ValueKey('order-${song.id}'),
                    title: Text(song.title),
                    subtitle: Text(song.bandName ?? ''),
                    leading: const Icon(Icons.drag_handle),
                  );
                },
              )
            else
              ...playlist!.songs!.map(
                (song) => Dismissible(
                  key: Key('song-${song.id}'),
                  direction: isOwner
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
                  onDismissed: (_) => _removeSong(song.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: AppTheme.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: SongCard(song: song, showDuration: true),
                ),
              ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _defaultBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), AppTheme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.queue_music, size: 80, color: AppTheme.textMuted),
    );
  }
}
