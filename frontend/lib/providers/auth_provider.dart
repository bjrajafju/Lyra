import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'band_provider.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _hasCheckedAuth = false;
  BandProvider? _bandProvider;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get hasCheckedAuth => _hasCheckedAuth;

  void updateBandProvider(BandProvider bp) {
    _bandProvider = bp;
  }

  Future<bool> login(String email, String password) async {
    try {
      final res = await ApiService.postWithoutAuth('/auth/login', {
        'email': email,
        'password': password,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _user = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _user!.token);
        if (_bandProvider != null) {
          await _bandProvider!.fetchContext();
        }
        notifyListeners();
        return true;
      } else {
        print('[LOGIN] Status code não é 200');
      }
      return false;
    } catch (e) {
      print('[LOGIN] ERRO: $e');
      return false;
    }
  }

  Future<bool> register(
    String username,
    String email,
    String password,
    String role,
  ) async {
    try {
      final res = await ApiService.postWithoutAuth('/auth/register', {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      });

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _user = User.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _user!.token);

        if (_bandProvider != null) {
          await _bandProvider!.fetchContext();
        }

        notifyListeners();
        return true;
      } else {
        print('[REGISTER] Status code não é 201');
      }
      return false;
    } catch (e) {
      print('[REGISTER] ERRO: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (_bandProvider != null) {
      _bandProvider!.clearContext();
    }
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('token')) {
        _hasCheckedAuth = true;
        notifyListeners();
        return;
      }

      final res = await ApiService.get('/auth/profile');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        data['token'] = prefs.getString('token');

        // inject current token locally
        _user = User.fromJson(data);
        if (_bandProvider != null) {
          await _bandProvider!.fetchContext();
        }
      } else {
        await logout();
      }
    } catch (e) {
      print(e);
    } finally {
      _hasCheckedAuth = true;
      notifyListeners();
    }
  }
}
