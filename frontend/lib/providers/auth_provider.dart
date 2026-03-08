import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    try {
      final res = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _user = User.fromJson(data);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _user!.token);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> register(String username, String email, String password, String role) async {
    try {
      final res = await ApiService.post('/auth/register', {
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
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    try {
      final res = await ApiService.get('/auth/profile');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        data['token'] = prefs.getString('token'); // inject current token locally
        _user = User.fromJson(data);
        notifyListeners();
      } else {
        await logout();
      }
    } catch (e) {
      print(e);
    }
  }
}
