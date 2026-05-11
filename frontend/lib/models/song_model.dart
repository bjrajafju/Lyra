class Song {
  final int id;
  final String title;
  final String audioUrl;
  final String? coverImage;
  final String? bandName;
  final int? bandId;
  final int? albumId;
  final String? genre;
  final List<dynamic>? genres;
  final String? description;
  final int playCount;
  final int duration;
  final int likeCount;
  final int playlistAdditions;
  final String? releaseDate;
  final String status;

  Song({
    required this.id,
    required this.title,
    required this.audioUrl,
    this.coverImage,
    this.bandName,
    this.bandId,
    this.albumId,
    this.genre,
    this.genres,
    this.description,
    this.playCount = 0,
    this.duration = 0,
    this.likeCount = 0,
    this.playlistAdditions = 0,
    this.releaseDate,
    this.status = 'published',
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'] ?? '',
      audioUrl: json['audio_url'] ?? '',
      coverImage: json['cover_image'],
      bandName: json['band_name'],
      bandId: json['band_id'],
      albumId: json['album_id'],
      genre: json['genre'],
      genres: json['genres'],
      description: json['description'],
      playCount: json['play_count'] ?? 0,
      duration: json['duration'] ?? 0,
      likeCount: int.tryParse('${json['like_count'] ?? 0}') ?? 0,
      playlistAdditions:
          int.tryParse(
            '${json['playlist_additions'] ?? json['playlist_count'] ?? 0}',
          ) ??
          0,
      releaseDate: json['release_date'],
      status: json['status'] ?? 'published',
    );
  }
}
