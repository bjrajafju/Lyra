class Song {
  final int id;
  final String title;
  final String audioUrl;
  final String? coverImage;
  final String? bandName;

  Song({
    required this.id,
    required this.title,
    required this.audioUrl,
    this.coverImage,
    this.bandName,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      audioUrl: json['audio_url'],
      coverImage: json['cover_image'],
      bandName: json['band_name'],
    );
  }
}
