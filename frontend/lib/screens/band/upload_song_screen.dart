import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  PlatformFile? audioFile;
  PlatformFile? coverFile;
  bool isUploading = false;

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

    setState(() => isUploading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest('POST', Uri.parse('${Constants.baseUrl}/songs'));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['band_id'] = '${widget.bandId ?? 1}';
      request.fields['title'] = titleController.text;
      request.fields['genre'] = genreController.text;
      request.fields['description'] = descController.text;
      request.fields['duration'] = '180';

      if (audioFile != null) {
        if (audioFile!.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes('audio', audioFile!.bytes!, filename: audioFile!.name));
        } else if (audioFile!.path != null) {
          request.files.add(await http.MultipartFile.fromPath('audio', audioFile!.path!));
        }
      }

      if (coverFile != null) {
        if (coverFile!.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes('cover_image', coverFile!.bytes!, filename: coverFile!.name));
        } else if (coverFile!.path != null) {
          request.files.add(await http.MultipartFile.fromPath('cover_image', coverFile!.path!));
        }
      }

      var response = await request.send();
      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful!')));
          Navigator.pop(context);
        }
      } else {
        final respStr = await response.stream.bytesToString();
        throw Exception('Upload failed ${response.statusCode}: $respStr');
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
