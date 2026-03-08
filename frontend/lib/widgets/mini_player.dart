import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, child) {
        if (audio.currentSong == null) return const SizedBox.shrink();

        final song = audio.currentSong!;
        
        return Container(
          color: Colors.grey[900],
          height: 60,
          child: Row(
            children: [
              if (song.coverImage != null)
                CachedNetworkImage(
                  imageUrl: '${Constants.serverUrl}${song.coverImage}',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(Icons.music_note),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                    if (song.bandName != null) 
                      Text(song.bandName!, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(audio.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  if (audio.isPlaying) {
                    audio.pause();
                  } else {
                    audio.playSong(song);
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}
