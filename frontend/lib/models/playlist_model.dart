import 'song_model.dart';

class Playlist {
  final int id;
  final String title;
  final String? description;
  final String? coverImage;
  final bool isPublic;
  final int creatorId;
  final String? creatorName;
  final int songCount;
  final List<Song>? songs;

  Playlist({
    required this.id,
    required this.title,
    this.description,
    this.coverImage,
    this.isPublic = false,
    required this.creatorId,
    this.creatorName,
    this.songCount = 0,
    this.songs,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    List<Song>? songs;
    if (json['songs'] != null && json['songs'] is List) {
      songs = (json['songs'] as List).map((s) => Song.fromJson(s)).toList();
    }

    return Playlist(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      coverImage: json['cover_image'],
      isPublic: json['is_public'] ?? false,
      creatorId: json['creator_id'],
      creatorName: json['creator_name'],
      songCount: int.tryParse('${json['song_count'] ?? 0}') ?? 0,
      songs: songs,
    );
  }
}
