import 'dart:convert';
import 'api_service.dart';

class ContentService {
  // Songs
  static Future<List<dynamic>> getBandSongs(String bandId) async {
    final response = await ApiService.get('/songs/mine?bandId=$bandId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch songs');
    }
  }

  static Future<void> toggleSongStatus(String songId) async {
    final response = await ApiService.patch('/songs/$songId/status', {});
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to toggle status');
    }
  }

  static Future<void> deleteSong(String songId) async {
    final response = await ApiService.delete('/songs/$songId');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete song');
    }
  }

  // Albums
  static Future<List<dynamic>> getBandAlbums(String bandId) async {
    final response = await ApiService.get('/albums?bandId=$bandId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch albums');
    }
  }

  static Future<List<dynamic>> getAlbumSongs(String albumId) async {
    final response = await ApiService.get('/albums/$albumId');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['songs'] ?? [];
    } else {
      throw Exception('Failed to fetch album songs');
    }
  }

  static Future<void> reorderAlbumSongs(String albumId, List<Map<String, int>> orders) async {
    final response = await ApiService.patch('/albums/$albumId/reorder', {
      'orders': orders,
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to reorder songs');
    }
  }

  // Upload (Multipart)
  static Future<void> uploadSong({
    required String bandId,
    required String title,
    required String? albumId,
    required List<int> genreIds,
    required MultipartFileData audio,
    MultipartFileData? coverImage,
  }) async {
    final fields = {
      'band_id': bandId,
      'title': title,
      if (albumId != null) 'album_id': albumId,
      'genre_ids': jsonEncode(genreIds),
    };

    final files = {
      'audio': audio,
      if (coverImage != null) 'cover_image': coverImage,
    };

    final response = await ApiService.multipartRequest(
      method: 'POST',
      endpoint: '/songs?bandId=$bandId',
      fields: fields,
      files: files,
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to upload song');
    }
  }

  // Genres
  static Future<List<dynamic>> getGenres() async {
    final response = await ApiService.get('/search/genres');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch genres');
    }
  }
}
