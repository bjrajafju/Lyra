class Band {
  final int id;
  final String name;
  final String? description;
  final String? profileImage;
  final String? bannerImage;
  final int totalStreams;
  final int followerCount;
  final int? songCount;
  final String? roleInBand;
  final List<BandMember>? members;

  Band({
    required this.id,
    required this.name,
    this.description,
    this.profileImage,
    this.bannerImage,
    this.totalStreams = 0,
    this.followerCount = 0,
    this.songCount,
    this.roleInBand,
    this.members,
  });

  factory Band.fromJson(Map<String, dynamic> json) {
    List<BandMember>? members;
    if (json['members'] != null && json['members'] is List) {
      members = (json['members'] as List)
          .map((m) => BandMember.fromJson(m))
          .toList();
    }

    return Band(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      profileImage: json['profile_image'],
      bannerImage: json['banner_image'],
      totalStreams: json['total_streams'] ?? 0,
      followerCount: int.tryParse('${json['follower_count'] ?? 0}') ?? 0,
      songCount: json['song_count'] != null
          ? int.tryParse('${json['song_count']}')
          : null,
      roleInBand: json['role_in_band'],
      members: members,
    );
  }
}

class BandMember {
  final int userId;
  final String username;
  final String? role;
  final String? profilePicture;

  BandMember({
    required this.userId,
    required this.username,
    this.role,
    this.profilePicture,
  });

  factory BandMember.fromJson(Map<String, dynamic> json) {
    return BandMember(
      userId: json['user_id'],
      username: json['username'] ?? '',
      role: json['role'],
      profilePicture: json['profile_picture'],
    );
  }
}
