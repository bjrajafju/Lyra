import 'dart:convert';
import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

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
  PlatformFile? _newProfilePicture;
  String? _currentProfilePicture;

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
        _currentProfilePicture = data['profile_picture'];
      }
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _pickProfilePicture() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _newProfilePicture = result.files.first;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _save() async {
    setState(() => isSaving = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      if (_newProfilePicture != null && user != null) {
        final fileData = MultipartFileData(
          bytes: _newProfilePicture!.bytes,
          path: kIsWeb ? null : _newProfilePicture!.path,
          filename: _newProfilePicture!.name,
        );

        final streamed = await ApiService.multipartRequest(
          method: 'PUT',
          endpoint: '/users/${user.id}',
          files: {'profile_image': fileData},
        );

        if (streamed.statusCode != 200) {
          throw Exception('Failed to upload profile picture');
        }
      }

      final res = await ApiService.patch('/auth/profile', {
        'username': usernameController.text,
        'bio': bioController.text,
      });
      if (res.statusCode == 200 && mounted) {
        await context.read<AuthProvider>().refreshUser();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
          Navigator.pop(context);
        }
      } else {
        throw Exception('Falha ao atualizar campos de texto do perfil');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao atualizar o perfil: $e')),
        );
      }
    }
    if (mounted) setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 58,
                      backgroundColor: AppTheme.surface,
                      backgroundImage: _newProfilePicture != null
                          ? (kIsWeb
                              ? MemoryImage(_newProfilePicture!.bytes!) as ImageProvider
                              : FileImage(File(_newProfilePicture!.path!)) as ImageProvider)
                          : (_currentProfilePicture != null
                              ? NetworkImage(Constants.imageUrl(_currentProfilePicture)) as ImageProvider
                              : null),
                      child: _newProfilePicture == null && _currentProfilePicture == null
                          ? const Icon(Icons.person, size: 64, color: AppTheme.textMuted)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: AppTheme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _pickProfilePicture,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _pickProfilePicture,
              child: const Text(
                'Alterar Foto de Perfil',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Nome de utilizador'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: 'Biografia'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Guardar Alterações'),
                  ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar Conta'),
                    content: const Text(
                      'Tem a certeza? Esta ação não pode ser revertida.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ApiService.delete('/auth/profile');
                  if (mounted)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text(
                'Delete Account',
                style: TextStyle(color: AppTheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
