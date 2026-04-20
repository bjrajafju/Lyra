import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class UploadSongScreen extends StatefulWidget {
  final int? bandId;
  const UploadSongScreen({super.key, this.bandId});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  final titleController = TextEditingController();
  final genreController = TextEditingController();
  final descController = TextEditingController();
  final tagsController = TextEditingController();
  final releaseDateController = TextEditingController();
  PlatformFile? audioFile;
  PlatformFile? coverFile;
  bool isUploading = false;
  String visibility = 'public';

  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
    if (result != null) setState(() => audioFile = result.files.first);
  }

  Future<void> pickCover() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null) setState(() => coverFile = result.files.first);
  }

  Future<void> upload() async {
    if (audioFile == null || titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio and Title are required')));
      return;
    }
    if (widget.bandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a band first')));
      return;
    }

    setState(() => isUploading = true);
    try {
      final response = await ApiService.multipartRequest(
        method: 'POST',
        endpoint: '/songs',
        fields: {
          'band_id': '${widget.bandId}',
          'title': titleController.text.trim(),
          'genre': genreController.text.trim(),
          'description': descController.text.trim(),
          'duration': '180',
          'visibility': visibility,
          if (releaseDateController.text.trim().isNotEmpty) 'release_date': releaseDateController.text.trim(),
          if (tagsController.text.trim().isNotEmpty) 'tags': tagsController.text.trim(),
        },
        files: {
          if (audioFile != null)
            'audio': MultipartFileData(
              bytes: audioFile!.bytes,
              path: audioFile!.path,
              filename: audioFile!.name,
            ),
          if (coverFile != null)
            'cover_image': MultipartFileData(
              bytes: coverFile!.bytes,
              path: coverFile!.path,
              filename: coverFile!.name,
            ),
        },
      );
      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful!')));
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Upload failed ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('$e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload New Song')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Song Title', prefixIcon: Icon(Icons.music_note)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: genreController,
              decoration: const InputDecoration(labelText: 'Genre', prefixIcon: Icon(Icons.category)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.description)),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(labelText: 'Tags (comma separated)', prefixIcon: Icon(Icons.tag)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: releaseDateController,
              decoration: const InputDecoration(labelText: 'Release date (YYYY-MM-DD)', prefixIcon: Icon(Icons.date_range)),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: visibility,
              onChanged: (value) {
                if (value != null) setState(() => visibility = value);
              },
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'private', child: Text('Private')),
                DropdownMenuItem(value: 'unlisted', child: Text('Unlisted')),
              ],
              decoration: const InputDecoration(labelText: 'Visibility'),
            ),
            const SizedBox(height: 24),
            // Audio picker
            _FilePicker(
              label: audioFile == null ? 'Pick Audio File' : audioFile!.name,
              icon: Icons.audiotrack_rounded,
              onTap: pickAudio,
              isSelected: audioFile != null,
            ),
            const SizedBox(height: 12),
            _FilePicker(
              label: coverFile == null ? 'Pick Cover Image (Optional)' : coverFile!.name,
              icon: Icons.image_rounded,
              onTap: pickCover,
              isSelected: coverFile != null,
            ),
            const SizedBox(height: 40),
            isUploading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: upload,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text('Upload Song'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
          ],
        ),
      ),
    );
  }
}

class _FilePicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const _FilePicker({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
