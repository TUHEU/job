// lib/providers/auth_provider.dart
// FIXES:
//   1. clearAuth() set _user to null which caused null crashes in screens
//      that call user.name etc — now resets to guest instead
//   2. Added isLoggedIn / isGuest / isIntern / isCompany helpers so
//      screens don't have to repeat the null + id checks everywhere

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User _user;

  AuthProvider({User? initialUser}) : _user = initialUser ?? _guestUser();

  static User _guestUser() => User(
    id: 'guest',
    name: 'Guest User',
    email: 'guest@goinus.cm',
    type: 'intern',
    skills: [],
  );

  // ── Getters ────────────────────────────────────────────────────────────────
  User get user => _user;
  bool get isLoggedIn => _user.id != 'guest';
  bool get isGuest => _user.id == 'guest';
  bool get isIntern =>
      _user.type == 'intern' ||
      _user.type == 'jobseeker' ||
      _user.type == 'student';
  bool get isCompany => _user.type == 'company' || _user.type == 'employer';

  // ── Mutators ───────────────────────────────────────────────────────────────
  Future<void> setUser(User user) async {
    _user = user;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> clearAuth() async {
    // FIX: reset to guest, not null — prevents null crashes in screens
    _user = _guestUser();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
  }
}
