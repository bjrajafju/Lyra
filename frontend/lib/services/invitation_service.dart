import 'dart:convert';
import 'api_service.dart';

class InvitationService {
  static Future<List<dynamic>> searchUsers(String query, {int page = 1, String? excludeBandId}) async {
    String endpoint = '/invitations/search?q=$query&page=$page';
    if (excludeBandId != null) {
      endpoint += '&excludeBandId=$excludeBandId';
    }
    
    final response = await ApiService.get(endpoint);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search users');
    }
  }

  static Future<void> inviteUser(String bandId, String userId, String role) async {
    final response = await ApiService.post('/invitations/band/$bandId', {
      'inviteeId': userId,
      'role': role,
    });
    
    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to invite user');
    }
  }

  static Future<List<dynamic>> getMyInvitations() async {
    final response = await ApiService.get('/invitations/my-invitations');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch invitations');
    }
  }

  static Future<List<dynamic>> getBandInvitations(String bandId) async {
    final response = await ApiService.get('/invitations/band/$bandId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch band invitations');
    }
  }

  static Future<void> respondToInvitation(String invitationId, String status) async {
    final response = await ApiService.post('/invitations/$invitationId/respond', {
      'status': status,
    });
    
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to respond to invitation');
    }
  }
}
