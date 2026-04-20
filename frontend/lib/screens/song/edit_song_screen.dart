import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/song_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class EditSongScreen extends StatefulWidget {
  final Song song;
  const EditSongScreen({super.key, required this.song});

  @override
  State<EditSongScreen> createState() => _EditSongScreenState();
}

class _EditSongScreenState extends State<EditSongScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _genreController = TextEditingController();
  final _tagsController = TextEditingController();
  final _releaseDateController = TextEditingController();
  bool _isSaving = false;
  String _visibility = 'public';
  PlatformFile? _coverFile;
  int? _albumId;
  List<Map<String, dynamic>> _albums = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.song.title;
    _descriptionController.text = widget.song.description ?? '';
    _genreController.text = widget.song.genre ?? '';
    _releaseDateController.text = widget.song.releaseDate ?? '';
    _albumId = widget.song.albumId;
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    if (widget.song.bandId == null) return;
    try {
      final res = await ApiService.get('/albums?band_id=${widget.song.bandId}');
      if (res.statusCode == 200) {
        final parsed = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        if (mounted) {
          setState(() => _albums = parsed);
        }
      }
    } catch (_) {}
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && mounted) {
      setState(() => _coverFile = result.files.first);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final fields = <String, String>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'genre': _genreController.text.trim(),
        'visibility': _visibility,
        'release_date': _releaseDateController.text.trim(),
        'album_id': _albumId?.toString() ?? '',
      };
      if (_tagsController.text.trim().isNotEmpty) {
        fields['tags'] = _tagsController.text.trim();
      }

      final files = <String, MultipartFileData>{};
      if (_coverFile != null) {
        files['cover_image'] = MultipartFileData(
          bytes: _coverFile!.bytes,
          path: _coverFile!.path,
          filename: _coverFile!.name,
        );
      }

      final streamed = await ApiService.multipartRequest(
        method: 'PUT',
        endpoint: '/songs/${widget.song.id}',
        fields: fields,
        files: files.isEmpty ? null : files,
      );

      if (streamed.statusCode == 200 && mounted) {
        Navigator.pop(context, true);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update song')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update song')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Song')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _genreController,
            decoration: const InputDecoration(labelText: 'Genre'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _releaseDateController,
            decoration: const InputDecoration(labelText: 'Release date (YYYY-MM-DD)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _albumId,
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('No album')),
              ..._albums.map((album) => DropdownMenuItem<int?>(
                    value: album['id'] as int?,
                    child: Text(album['title'] ?? 'Untitled album'),
                  )),
            ],
            onChanged: (val) => setState(() => _albumId = val),
            decoration: const InputDecoration(labelText: 'Album'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _visibility,
            items: const [
              DropdownMenuItem(value: 'public', child: Text('Public')),
              DropdownMenuItem(value: 'private', child: Text('Private')),
              DropdownMenuItem(value: 'unlisted', child: Text('Unlisted')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _visibility = val);
            },
            decoration: const InputDecoration(labelText: 'Visibility'),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickCover,
            icon: const Icon(Icons.image_outlined, color: AppTheme.textSecondary),
            label: Text(_coverFile?.name ?? 'Change cover image'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}
