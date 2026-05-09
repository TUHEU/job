// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'utils/app_theme.dart';

import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/internship_list_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/applications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/post_internship_screen.dart';
import 'screens/camera_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storedUser = prefs.getString('user');

  User? initialUser;
  if (storedUser != null) {
    try {
      initialUser = User.fromJson(jsonDecode(storedUser) as Map<String, dynamic>);
    } catch (_) {
      initialUser = User.guest();
    }
  } else {
    initialUser = User.guest();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(initialUser: initialUser),
      child: const GoinusApp(),
    ),
  );
}

class GoinusApp extends StatelessWidget {
  const GoinusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goinus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LandingScreen(),
      routes: {
        '/home':            (_) => const HomeScreen(),
        '/login':           (_) => const LoginScreen(),
        '/register':        (_) => const RegisterScreen(),
        '/internships':     (_) => const InternshipListScreen(),
        '/matches':         (_) => const MatchesScreen(),
        '/applications':    (_) => const ApplicationsScreen(),
        '/profile':         (_) => const ProfileScreen(),
        '/post-internship': (_) => const PostInternshipScreen(),
        '/camera':          (_) => const CameraScreen(),
      },
    );
  }
}
