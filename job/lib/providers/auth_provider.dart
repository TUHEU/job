// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User _user;

  AuthProvider({User? initialUser}) : _user = initialUser ?? User.guest();

  User get user => _user;
  bool get isLoggedIn => !_user.isGuest;
  bool get isGuest => _user.isGuest;
  bool get isIntern => _user.isIntern;
  bool get isCompany => _user.isCompany;

  Future<void> setUser(User user) async {
    _user = user;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> clearAuth() async {
    _user = User.guest();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
  }
}
