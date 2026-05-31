import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/content_service.dart';
import '../../services/api_service.dart';

class UploadSongScreen extends StatefulWidget {
  final int? bandId;
  const UploadSongScreen({super.key, this.bandId});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final tagsController = TextEditingController();

  List<dynamic> _genres = [];
  List<int> _selectedGenreIds = [];
  List<dynamic> _albums = [];
  int? _selectedAlbumId;

  PlatformFile? audioFile;
  PlatformFile? coverFile;
  bool isUploading = false;
  bool _isLoadingGenres = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final genres = await ContentService.getGenres();
      if (widget.bandId != null) {
        final albums = await ContentService.getBandAlbums(
          widget.bandId.toString(),
        );
        setState(() => _albums = albums);
      }
      setState(() {
        _genres = genres;
        _isLoadingGenres = false;
      });
    } catch (e) {
      setState(() => _isLoadingGenres = false);
    }
  }

  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result != null) setState(() => audioFile = result.files.first);
  }

  Future<void> pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null) setState(() => coverFile = result.files.first);
  }

  Future<void> upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an audio file')),
      );
      return;
    }
    if (_selectedGenreIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one genre')),
      );
      return;
    }

    setState(() => isUploading = true);
    try {
      await ContentService.uploadSong(
        bandId: widget.bandId.toString(),
        title: titleController.text.trim(),
        albumId: _selectedAlbumId?.toString(),
        genreIds: _selectedGenreIds,
        tags: tagsController.text.trim(),
        audio: MultipartFileData(
          bytes: audioFile!.bytes,
          path: kIsWeb ? null : audioFile!.path,
          filename: audioFile!.name,
        ),
        coverImage: coverFile != null
            ? MultipartFileData(
                bytes: coverFile!.bytes,
                path: kIsWeb ? null : coverFile!.path,
                filename: coverFile!.name,
              )
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song uploaded as Draft!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lançar Nova Música')),
      body: _isLoadingGenres
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informação Geral',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título da Música',
                        prefixIcon: Icon(Icons.music_note_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (separar por vírgula)',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Genres',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _genres.map((g) {
                        final isSelected = _selectedGenreIds.contains(g['id']);
                        return FilterChip(
                          label: Text(g['name']),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected)
                                _selectedGenreIds.add(g['id']);
                              else
                                _selectedGenreIds.remove(g['id']);
                            });
                          },
                          showCheckmark: false,
                          backgroundColor: AppTheme.surface,
                          selectedColor: AppTheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.primary
                                : Colors.white10,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Album (Opcional)',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: (_selectedAlbumId == null || !_albums.any((a) => a['id'] == _selectedAlbumId)) ? null : _selectedAlbumId,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sem Album'),
                        ),
                        ..._albums.map(
                          (a) => DropdownMenuItem<int?>(
                            value: a['id'] as int?,
                            child: Text(a['title']),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedAlbumId = v),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.album_outlined),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'Files',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FileSelector(
                      label: audioFile == null
                          ? 'Selecionar Audio (MP3/WAV)'
                          : audioFile!.name,
                      subtitle: audioFile == null
                          ? 'Até 50MB'
                          : '${(audioFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                      icon: Icons.audiotrack_rounded,
                      onTap: pickAudio,
                      isSelected: audioFile != null,
                    ),
                    const SizedBox(height: 12),
                    _FileSelector(
                      label: coverFile == null
                          ? 'Imagem (Opcional)'
                          : coverFile!.name,
                      subtitle: coverFile == null
                          ? 'JPEG ou PNG'
                          : 'Pronto Para Lançamento',
                      icon: Icons.image_outlined,
                      onTap: pickCover,
                      isSelected: coverFile != null,
                    ),
                    const SizedBox(height: 48),

                    isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: upload,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(60),
                            ),
                            child: const Text('LANÇAR FAIXA'),
                          ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

class _FileSelector extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const _FileSelector({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.white05,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isSelected ? AppTheme.primary : AppTheme.textMuted)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
