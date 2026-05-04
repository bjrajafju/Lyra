import 'package:flutter/material.dart';
import '../../services/layout_service.dart';
import '../../theme/app_theme.dart';

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
      final orders = _widgets.asMap().entries.map((e) => {
        'id': e.value['id'],
        'position': e.key + 1,
      }).toList();

      await LayoutService.reorderWidgets(widget.bandId.toString(), orders);
      setState(() => _hasChanged = false);
      _fetchWidgets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layout saved!'), backgroundColor: AppTheme.success));
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addNewWidget() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Add Widget', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _widgetTypeTile('latest_release', 'Latest Release', Icons.new_releases_outlined),
          _widgetTypeTile('bio', 'Band Biography', Icons.description_outlined),
          _widgetTypeTile('social_links', 'Social Links', Icons.share_outlined),
          _widgetTypeTile('featured_video', 'Featured Video', Icons.videocam_outlined),
          _widgetTypeTile('merch', 'Merch Preview', Icons.shopping_bag_outlined),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteWidget(String widgetId) async {
    try {
      await LayoutService.deleteWidget(widget.bandId.toString(), widgetId);
      _fetchWidgets();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _configureWidget(dynamic widgetData) {
    final type = widgetData['type'];
    final settings = Map<String, dynamic>.from(widgetData['settings'] ?? {});
    final controller = TextEditingController(text: settings['content'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configure ${type.toString().replaceAll('_', ' ').toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == 'bio')
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Enter band biography...'),
              ),
            if (type == 'featured_video')
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'YouTube/Vimeo URL'),
              ),
            if (type == 'social_links')
              const Text('Social links will use profile data automatically.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              settings['content'] = controller.text.trim();
              await LayoutService.updateWidget(widget.bandId.toString(), widgetData['id'].toString(), settings: settings);
              Navigator.pop(context);
              _fetchWidgets();
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
          if (_hasChanged)
            TextButton(
              onPressed: _isLoading ? null : _saveLayout,
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
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
        border: Border.all(color: Colors.white05),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.drag_indicator, color: AppTheme.textMuted),
        title: Text(
          widgetData['type'].toString().toUpperCase().replaceAll('_', ' '),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
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
              icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
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
      case 'bio': return settings['content'] ?? 'No biography set';
      case 'latest_release': return 'Automatically shows your latest track';
      case 'social_links': return 'Displays links from your profile';
      case 'featured_video': return settings['content'] ?? 'No video URL set';
      default: return 'Dynamic Widget';
    }
  }
}
