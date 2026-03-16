import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final usernameController = TextEditingController();
  final bioController = TextEditingController();
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await ApiService.get('/auth/profile');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        usernameController.text = data['username'] ?? '';
        bioController.text = data['bio'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _save() async {
    setState(() => isSaving = true);
    try {
      final res = await ApiService.patch('/auth/profile', {
        'username': usernameController.text,
        'bio': bioController.text,
      });
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    }
    if (mounted) setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    child: const Text('Save Changes'),
                  ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text('Are you sure? This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ApiService.delete('/auth/profile');
                  if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text('Delete Account', style: TextStyle(color: AppTheme.error)),
            ),
          ],
        ),
      ),
    );
  }
}
