import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../theme/app_theme.dart';

class CreateBandScreen extends StatefulWidget {
  const CreateBandScreen({super.key});

  @override
  State<CreateBandScreen> createState() => _CreateBandScreenState();
}

class _CreateBandScreenState extends State<CreateBandScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  PlatformFile? _profileImage;
  PlatformFile? _bannerImage;
  bool _isCreating = false;

  Future<void> _pickImage(bool isProfile) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null) {
      setState(() {
        if (isProfile) {
          _profileImage = result.files.first;
        } else {
          _bannerImage = result.files.first;
        }
      });
    }
  }

  Future<void> _createBand() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Band name is required')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest('POST', Uri.parse('${Constants.baseUrl}/bands'));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = _nameController.text.trim();
      request.fields['description'] = _descController.text.trim();

      if (_profileImage != null) {
        if (_profileImage!.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes('profile_image', _profileImage!.bytes!, filename: _profileImage!.name));
        } else if (_profileImage!.path != null) {
          request.files.add(await http.MultipartFile.fromPath('profile_image', _profileImage!.path!));
        }
      }

      if (_bannerImage != null) {
        if (_bannerImage!.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes('banner_image', _bannerImage!.bytes!, filename: _bannerImage!.name));
        } else if (_bannerImage!.path != null) {
          request.files.add(await http.MultipartFile.fromPath('banner_image', _bannerImage!.path!));
        }
      }

      var response = await request.send();
      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Band created successfully!')));
          Navigator.pop(context, true);
        }
      } else {
        final respStr = await response.stream.bytesToString();
        throw Exception('Creation failed ${response.statusCode}: $respStr');
      }
    } catch (e) {
      debugPrint('$e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create band')));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Band')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Band Name*', prefixIcon: Icon(Icons.group)),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.description)),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Profile image picker
            _ImagePicker(
              label: _profileImage == null ? 'Pick Profile Image (Optional)' : _profileImage!.name,
              icon: Icons.person_add_alt_1,
              onTap: () => _pickImage(true),
              isSelected: _profileImage != null,
            ),
            const SizedBox(height: 12),
            
            // Banner image picker
            _ImagePicker(
              label: _bannerImage == null ? 'Pick Banner Image (Optional)' : _bannerImage!.name,
              icon: Icons.image,
              onTap: () => _pickImage(false),
              isSelected: _bannerImage != null,
            ),
            
            const SizedBox(height: 40),
            _isCreating
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _createBand,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Band'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const _ImagePicker({
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
                style: TextStyle(color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
