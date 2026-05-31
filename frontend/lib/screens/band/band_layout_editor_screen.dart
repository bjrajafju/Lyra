import 'package:flutter/material.dart';
import '../../models/widget_type.dart';
import '../../services/layout_service.dart';
import '../../theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchWidgets();
  }

  Future<void> _fetchWidgets() async {
    try {
      final widgets = await LayoutService.getWidgets(widget.bandId.toString());
      setState(() {
        _widgets = widgets;
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
          : ReorderableListView.builder(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewWidget,
        icon: const Icon(Icons.add),
        label: const Text('Add Widget'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
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
