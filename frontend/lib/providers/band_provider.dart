import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/band_model.dart';
import '../services/api_service.dart';

class BandProvider with ChangeNotifier {
  List<Band> _managedBands = [];
  Band? _selectedBand;
  bool _isLoading = false;

  List<Band> get managedBands => _managedBands;
  Band? get selectedBand => _selectedBand;
  bool get isLoading => _isLoading;
  bool get isBandContext => _selectedBand != null;

  Future<void> fetchContext() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.get('/auth/me/context');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List bandsData = data['bands'];
        _managedBands = bandsData.map((b) => Band.fromJson(b)).toList();

        // Try to restore previous selection
        final prefs = await SharedPreferences.getInstance();
        final savedBandId = prefs.getInt('selected_band_id');

        if (savedBandId != null) {
          try {
            _selectedBand = _managedBands.firstWhere((b) => b.id == savedBandId);
          } catch (_) {
            _selectedBand = null;
          }
        } else {
          _selectedBand = null;
        }
      }
    } catch (e) {
      print('Error fetching band context: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectBand(Band? band) async {
    if (_selectedBand?.id == band?.id) return;
    
    _selectedBand = band;
    final prefs = await SharedPreferences.getInstance();
    if (band == null) {
      await prefs.remove('selected_band_id');
    } else {
      await prefs.setInt('selected_band_id', band.id);
    }
    notifyListeners();
  }

  void clearContext() {
    _managedBands = [];
    _selectedBand = null;
    notifyListeners();
  }
}
