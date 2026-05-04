import 'dart:convert';
import 'api_service.dart';

class BandMemberService {
  static Future<List<dynamic>> getMembers(String bandId) async {
    final response = await ApiService.get('/bands/$bandId/members');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch members');
    }
  }

  static Future<void> updateMemberRole(String bandId, String userId, String role) async {
    final response = await ApiService.patch('/bands/$bandId/members/$userId/role', {
      'role': role,
    });
    
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update role');
    }
  }

  static Future<void> removeMember(String bandId, String userId) async {
    final response = await ApiService.delete('/bands/$bandId/members/$userId');
    
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to remove member');
    }
  }

  static Future<void> leaveBand(String bandId) async {
    final response = await ApiService.delete('/bands/$bandId/members/leave');
    
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to leave band');
    }
  }
}
