import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;

  AuthProvider({User? initialUser}) : _user = initialUser;

  User? get user => _user;

  bool get isAuthenticated => _user != null;

  Future<void> setUser(User user) async {
    _user = user;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> clearAuth() async {
    _user = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
  }
}
