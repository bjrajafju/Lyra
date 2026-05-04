import 'dart:convert';
import 'api_service.dart';

class LayoutService {
  static Future<List<dynamic>> getWidgets(String bandId) async {
    final response = await ApiService.get('/bands/$bandId/widgets');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch widgets');
    }
  }

  static Future<void> createWidget(String bandId, String type, Map<String, dynamic> settings) async {
    final response = await ApiService.post('/bands/$bandId/widgets', {
      'type': type,
      'settings': settings,
    });
    if (response.statusCode != 201) {
      throw Exception('Failed to create widget');
    }
  }

  static Future<void> updateWidget(String bandId, String widgetId, {Map<String, dynamic>? settings, int? position}) async {
    final response = await ApiService.patch('/bands/$bandId/widgets/$widgetId', {
      if (settings != null) 'settings': settings,
      if (position != null) 'position': position,
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to update widget');
    }
  }

  static Future<void> deleteWidget(String bandId, String widgetId) async {
    final response = await ApiService.delete('/bands/$bandId/widgets/$widgetId');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete widget');
    }
  }

  static Future<void> reorderWidgets(String bandId, List<Map<String, dynamic>> widgetOrders) async {
    final response = await ApiService.patch('/bands/$bandId/widgets/reorder', {
      'widgetOrders': widgetOrders,
    });
    if (response.statusCode != 200) {
      throw Exception('Failed to reorder widgets');
    }
  }
}
