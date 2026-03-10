import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadSongScreen extends StatefulWidget {
  const UploadSongScreen({super.key});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  final titleController = TextEditingController();
  final genreController = TextEditingController();
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
      
      // Normally, band_id comes from artist context. Hardcoding 1 for prototype simplicity
      request.fields['band_id'] = '1';
      request.fields['title'] = titleController.text;
      request.fields['genre'] = genreController.text;
      request.fields['duration'] = '180'; // Mock duration
      
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful')));
          Navigator.pop(context);
        }
      } else {
        final respStr = await response.stream.bytesToString();
        throw Exception('Upload failed ${response.statusCode}: $respStr');
      }
    } catch (e) {
      print(e);
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Song Title')),
            const SizedBox(height: 16),
            TextField(controller: genreController, decoration: const InputDecoration(labelText: 'Genre')),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: pickAudio, icon: const Icon(Icons.audiotrack), label: Text(audioFile == null ? 'Pick Audio' : audioFile!.name))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: pickCover, icon: const Icon(Icons.image), label: Text(coverFile == null ? 'Pick Cover (Optional)' : coverFile!.name))),
              ],
            ),
            const SizedBox(height: 40),
            isUploading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: upload, style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)), child: const Text('Upload Song')),
          ],
        ),
      ),
    );
  }
}
