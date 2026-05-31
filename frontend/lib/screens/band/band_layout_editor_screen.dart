import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/band_model.dart';
import '../../models/widget_type.dart';
import '../../providers/band_provider.dart';
import '../../services/api_service.dart';
import '../../services/layout_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import 'band_profile_screen.dart';

class BandLayoutEditorScreen extends StatefulWidget {
  final int bandId;
  const BandLayoutEditorScreen({super.key, required this.bandId});

  @override
  State<BandLayoutEditorScreen> createState() => _BandLayoutEditorScreenState();
}

class _BandLayoutEditorScreenState extends State<BandLayoutEditorScreen> {
  List<dynamic> _widgets = [];
  bool _isLoading = true;
  bool _hasChanged = false;
  Band? _band;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _fetchWidgets();
  }

  Future<void> _fetchWidgets() async {
    try {
      final widgets = await LayoutService.getWidgets(widget.bandId.toString());
      final bandRes = await ApiService.get('/bands/${widget.bandId}');
      Band? fetchedBand;
      if (bandRes.statusCode == 200) {
        fetchedBand = Band.fromJson(jsonDecode(bandRes.body));
      }
      setState(() {
        _widgets = widgets;
        _band = fetchedBand;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLayout() async {
    setState(() => _isLoading = true);
    try {
      final widgetOrders = _widgets
          .asMap()
          .entries
          .map((e) => {'id': e.value['id'], 'position': e.key + 1})
          .toList();

      await LayoutService.reorderWidgets(widget.bandId.toString(), widgetOrders);
      setState(() => _hasChanged = false);
      _fetchWidgets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layout saved!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addNewWidget() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Add Widget',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...WidgetType.values.map((type) => _widgetTypeTile(
                type.code,
                type.label,
                type.icon,
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _widgetTypeTile(String type, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        _createWidget(type);
      },
    );
  }

  Future<void> _createWidget(String type) async {
    try {
      await LayoutService.createWidget(widget.bandId.toString(), type, {});
      _fetchWidgets();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteWidget(String widgetId) async {
    try {
      await LayoutService.deleteWidget(widget.bandId.toString(), widgetId);
      _fetchWidgets();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _configureWidget(dynamic widgetData) {
    final typeCode = widgetData['type'] as String;
    final type = WidgetType.fromCode(typeCode);
    final settings = Map<String, dynamic>.from(widgetData['settings'] ?? {});
    final titleController = TextEditingController(text: settings['title'] ?? '');
    final contentController = TextEditingController(text: settings['content'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configure ${type.label}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Custom Title (optional)',
                  hintText: 'Leave empty for default',
                ),
              ),
              const SizedBox(height: 16),
              if (type == WidgetType.bio)
                TextField(
                  controller: contentController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Biography Content',
                    hintText: 'Enter band biography...',
                  ),
                ),
              if (type == WidgetType.socialLinks)
                const Text(
                  'Social links will use profile data automatically.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                settings['title'] = titleController.text.trim();
              } else {
                settings.remove('title');
              }
              
              if (type == WidgetType.bio) {
                settings['content'] = contentController.text.trim();
              }

              try {
                await LayoutService.updateWidget(
                  widget.bandId.toString(),
                  widgetData['id'].toString(),
                  settings: settings,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  _fetchWidgets();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined, color: AppTheme.primary),
            tooltip: 'View Public Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BandProfileScreen(bandId: widget.bandId),
                ),
              );
            },
          ),
          if (_hasChanged)
            TextButton(
              onPressed: _isLoading ? null : _saveLayout,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBandIdentitySection(),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _widgets.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _widgets.removeAt(oldIndex);
                        _widgets.insert(newIndex, item);
                        _hasChanged = true;
                      });
                    },
                    itemBuilder: (context, index) {
                      final widgetData = _widgets[index];
                      return _buildWidgetTile(widgetData, index);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewWidget,
        icon: const Icon(Icons.add),
        label: const Text('Add Widget'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildBandIdentitySection() {
    if (_band == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner Container
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  image: _band!.bannerImage != null
                      ? DecorationImage(
                          image: NetworkImage(Constants.imageUrl(_band!.bannerImage)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _band!.bannerImage == null
                    ? const Center(
                        child: Icon(Icons.image, size: 48, color: AppTheme.textMuted),
                      )
                    : null,
              ),
              // Banner Change Button
              Positioned(
                top: 12,
                right: 12,
                child: ElevatedButton.icon(
                  onPressed: _isUploadingImage ? null : _pickBandBannerImage,
                  icon: const Icon(Icons.photo_library, size: 16, color: Colors.black),
                  label: const Text('Change Banner', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              // Avatar positioned at bottom-left overlap
              Positioned(
                bottom: 0,
                left: 20,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surface, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 41,
                        backgroundColor: AppTheme.surface,
                        backgroundImage: _band!.profileImage != null
                          ? NetworkImage(Constants.imageUrl(_band!.profileImage))
                          : null,
                        child: _band!.profileImage == null
                          ? const Icon(Icons.groups, size: 40, color: AppTheme.textMuted)
                          : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primary,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                          onPressed: _isUploadingImage ? null : _pickBandProfileImage,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10), // Spacing for avatar overlap
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _band!.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppTheme.primary, size: 20),
                onPressed: _editBandName,
                tooltip: 'Edit Band Name',
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.white05, height: 32, thickness: 1),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'PROFILE WIDGETS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickBandProfileImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _isUploadingImage = true);
        final file = result.files.first;
        final fileData = MultipartFileData(
          bytes: file.bytes,
          path: kIsWeb ? null : file.path,
          filename: file.name,
        );

        final response = await ApiService.multipartRequest(
          method: 'PUT',
          endpoint: '/bands/${widget.bandId}',
          files: {'profile_image': fileData},
        );

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated successfully!'), backgroundColor: AppTheme.success),
            );
          }
          await _fetchWidgets();
          if (mounted) {
            await context.read<BandProvider>().fetchContext();
          }
        } else {
          throw Exception('Upload failed with status code ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _pickBandBannerImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _isUploadingImage = true);
        final file = result.files.first;
        final fileData = MultipartFileData(
          bytes: file.bytes,
          path: kIsWeb ? null : file.path,
          filename: file.name,
        );

        final response = await ApiService.multipartRequest(
          method: 'PUT',
          endpoint: '/bands/${widget.bandId}',
          files: {'banner_image': fileData},
        );

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Banner image updated successfully!'), backgroundColor: AppTheme.success),
            );
          }
          await _fetchWidgets();
          if (mounted) {
            await context.read<BandProvider>().fetchContext();
          }
        } else {
          throw Exception('Upload failed with status code ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating banner image: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _editBandName() {
    if (_band == null) return;
    final nameController = TextEditingController(text: _band!.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Band Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Band Name',
            hintText: 'Enter band name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;

              try {
                final response = await ApiService.put(
                  '/bands/${widget.bandId}',
                  {'name': newName},
                );

                if (response.statusCode == 200) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Band name updated!'), backgroundColor: AppTheme.success),
                    );
                  }
                  await _fetchWidgets();
                  if (context.mounted) {
                    await context.read<BandProvider>().fetchContext();
                  }
                } else {
                  throw Exception('Failed to update band name');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetTile(dynamic widgetData, int index) {
    return Container(
      key: ValueKey(widgetData['id']),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.white05),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.drag_indicator, color: AppTheme.textMuted),
        title: Text(
          widgetData['type'].toString().toUpperCase().replaceAll('_', ' '),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Text(
          _getWidgetSubtitle(widgetData),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 20),
              onPressed: () => _configureWidget(widgetData),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.error,
                size: 20,
              ),
              onPressed: () => _deleteWidget(widgetData['id'].toString()),
            ),
          ],
        ),
      ),
    );
  }

  String _getWidgetSubtitle(dynamic widgetData) {
    final type = widgetData['type'];
    final settings = widgetData['settings'] ?? {};
    switch (type) {
      case 'bio':
        return settings['content'] ?? 'No biography set';
      case 'latest_release':
        return 'Automatically shows your latest track';
      case 'social_links':
        return 'Displays links from your profile';
      case 'featured_video':
        return settings['content'] ?? 'No video URL set';
      default:
        return 'Dynamic Widget';
    }
  }
}
