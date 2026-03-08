import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/audio_provider.dart';
import '../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SongCard extends StatelessWidget {
  final Song song;

  const SongCard({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: song.coverImage != null
          ? CachedNetworkImage(
              imageUrl: '${Constants.serverUrl}${song.coverImage}',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const Icon(Icons.music_note),
            )
          : Container(
              width: 50,
              height: 50,
              color: Colors.grey[800],
              child: const Icon(Icons.music_note),
            ),
      title: Text(song.title),
      subtitle: song.bandName != null ? Text(song.bandName!) : null,
      trailing: IconButton(
        icon: const Icon(Icons.play_circle_fill, color: Color(0xFF1DB954)),
        onPressed: () {
          context.read<AudioProvider>().playSong(song);
        },
      ),
    );
  }
}
