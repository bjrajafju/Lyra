import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;

  AudioProvider() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });
    _player.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      notifyListeners();
    });
    _player.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });
  }

  Future<void> playSong(Song song) async {
    if (_currentSong?.id == song.id) {
      await _player.resume();
      return;
    }

    _currentSong = song;
    final url = '${Constants.serverUrl}${song.audioUrl}';
    await _player.play(UrlSource(url));
    
    // Ping API to record stream
    try {
      await ApiService.get('/songs/${song.id}/play');
    } catch (e) {
      print('Failed to record stream: $e');
    }
    
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
  }
  
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
