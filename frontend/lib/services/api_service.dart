import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return await http.get(
      Uri.parse('${Constants.baseUrl}$endpoint'),
      headers: headers,
    );
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    return await http.post(
      Uri.parse('${Constants.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    return await http.put(
      Uri.parse('${Constants.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    return await http.patch(
      Uri.parse('${Constants.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return await http.delete(
      Uri.parse('${Constants.baseUrl}$endpoint'),
      headers: headers,
    );
  }

  static Future<http.Response> postWithoutAuth(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    return await http.post(
      Uri.parse('${Constants.baseUrl}$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  /// Sends a multipart request with optional fields and files.
  /// [files] is a map of field name -> {path, bytes, filename}
  static Future<http.StreamedResponse> multipartRequest({
    required String method,
    required String endpoint,
    Map<String, String>? fields,
    Map<String, MultipartFileData>? files,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    var request = http.MultipartRequest(
      method,
      Uri.parse('${Constants.baseUrl}$endpoint'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (files != null) {
      for (final entry in files.entries) {
        final fileData = entry.value;
        if (fileData.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            entry.key,
            fileData.bytes!,
            filename: fileData.filename,
          ));
        } else if (fileData.path != null) {
          request.files.add(await http.MultipartFile.fromPath(
            entry.key,
            fileData.path!,
          ));
        }
      }
    }

    return await request.send();
  }
}

class MultipartFileData {
  final String? path;
  final List<int>? bytes;
  final String filename;

  MultipartFileData({this.path, this.bytes, required this.filename});
}
