import 'package:flutter/material.dart';
import 'upload_song_screen.dart';

class BandDashboard extends StatelessWidget {
  const BandDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Artist Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadSongScreen()));
          },
          icon: const Icon(Icons.upload),
          label: const Text('Upload New Song'),
        ),
      ],
    );
  }
}
