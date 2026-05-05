import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  bool isPublic = false;
  bool isCreating = false;

  Future<void> _create() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    setState(() => isCreating = true);
    try {
      final res = await ApiService.post('/playlists', {
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'is_public': isPublic,
      });
      if (res.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Playlist created!')));
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create playlist')),
        );
      }
    }
    if (mounted) setState(() => isCreating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Playlist')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Playlist Name'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Public Playlist'),
              subtitle: const Text(
                'Anyone can see this playlist',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              value: isPublic,
              onChanged: (val) => setState(() => isPublic = val),
              activeColor: AppTheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            isCreating
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _create,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Create Playlist'),
                  ),
          ],
        ),
      ),
    );
  }
}
