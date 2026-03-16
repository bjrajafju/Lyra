import 'song_model.dart';

class Album {
  final int id;
  final String title;
  final String? description;
  final String? coverImage;
  final String? releaseDate;
  final int? bandId;
  final String? bandName;
  final int songCount;
  final List<Song>? songs;

  Album({
    required this.id,
    required this.title,
    this.description,
    this.coverImage,
    this.releaseDate,
    this.bandId,
    this.bandName,
    this.songCount = 0,
    this.songs,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    List<Song>? songs;
    if (json['songs'] != null && json['songs'] is List) {
      songs = (json['songs'] as List).map((s) => Song.fromJson(s)).toList();
    }

    return Album(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      coverImage: json['cover_image'],
      releaseDate: json['release_date'],
      bandId: json['band_id'],
      bandName: json['band_name'],
      songCount: int.tryParse('${json['song_count'] ?? 0}') ?? 0,
      songs: songs,
    );
  }
}
