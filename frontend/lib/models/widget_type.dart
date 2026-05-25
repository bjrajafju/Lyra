import 'package:flutter/material.dart';

enum WidgetType {
  latestReleases('latest_releases', 'Latest Releases', Icons.new_releases_outlined),
  popularSongs('popular_songs', 'Popular Songs', Icons.trending_up_rounded),
  albums('albums', 'Albums', Icons.album_outlined),
  bio('bio', 'Biography', Icons.description_outlined),
  members('members', 'Band Members', Icons.people_outline),
  socialLinks('social_links', 'Social Links', Icons.share_outlined);

  final String code;
  final String label;
  final IconData icon;

  const WidgetType(this.code, this.label, this.icon);

  static WidgetType fromCode(String code) {
    return WidgetType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => WidgetType.latestReleases,
    );
  }
}
