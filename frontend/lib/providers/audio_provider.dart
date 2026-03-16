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
  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _shuffle = false;
  bool _repeat = false;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get shuffle => _shuffle;
  bool get repeat => _repeat;

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
    _player.onPlayerComplete.listen((_) {
      if (_repeat) {
        _player.seek(Duration.zero);
        _player.resume();
      } else {
        skipNext();
      }
    });
  }

  Future<void> playSong(Song song) async {
    if (_currentSong?.id == song.id && _isPlaying) {
      return;
    }
    if (_currentSong?.id == song.id && !_isPlaying) {
      await _player.resume();
      return;
    }

    _currentSong = song;
    _position = Duration.zero;
    _duration = Duration.zero;
    final url = '${Constants.serverUrl}${song.audioUrl}';
    await _player.play(UrlSource(url));

    // Add to queue if not already in it
    if (!_queue.any((s) => s.id == song.id)) {
      _queue.add(song);
    }
    _currentIndex = _queue.indexWhere((s) => s.id == song.id);

    // Record stream
    try {
      await ApiService.get('/songs/${song.id}/play');
    } catch (e) {
      debugPrint('Failed to record stream: $e');
    }

    notifyListeners();
  }

  Future<void> playQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = List.from(songs);
    if (startIndex >= 0 && startIndex < songs.length) {
      _currentIndex = startIndex;
      await playSong(songs[startIndex]);
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await playSong(_queue[_currentIndex]);
    } else if (_repeat) {
      _currentIndex = 0;
      await playSong(_queue[_currentIndex]);
    }
  }

  Future<void> skipPrevious() async {
    if (_queue.isEmpty) return;
    if (_position.inSeconds > 3) {
      // If more than 3 seconds in, restart current song
      await seek(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      await playSong(_queue[_currentIndex]);
    }
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    if (_shuffle) {
      final current = _currentSong;
      _queue.shuffle();
      if (current != null) {
        _queue.remove(current);
        _queue.insert(0, current);
        _currentIndex = 0;
      }
    }
    notifyListeners();
  }

  void toggleRepeat() {
    _repeat = !_repeat;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
