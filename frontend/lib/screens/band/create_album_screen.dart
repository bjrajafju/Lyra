import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/content_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CreateAlbumScreen extends StatefulWidget {
  final int bandId;
  const CreateAlbumScreen({super.key, required this.bandId});

  @override
  State<CreateAlbumScreen> createState() => _CreateAlbumScreenState();
}

class _CreateAlbumScreenState extends State<CreateAlbumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  PlatformFile? _coverFile;
  bool _isSaving = false;

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      setState(() => _coverFile = result.files.first);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ContentService.createAlbum(
        bandId: widget.bandId.toString(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        coverImage: _coverFile == null
            ? null
            : MultipartFileData(
                bytes: _coverFile!.bytes,
                path: kIsWeb ? null : _coverFile!.path,
                filename: _coverFile!.name,
              ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Album created successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Album')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Album Title*',
                  hintText: 'Enter album name',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What is this album about?',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              const Text(
                'Album Cover',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickCover,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.white05),
                    image: _coverFile != null && _coverFile!.bytes != null
                        ? DecorationImage(
                            image: MemoryImage(_coverFile!.bytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _coverFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 40,
                              color: AppTheme.textMuted,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Select Image',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              if (_coverFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _coverFile!.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              const SizedBox(height: 48),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: const Text('Create Album'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
