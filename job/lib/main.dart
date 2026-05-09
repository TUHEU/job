// lib/main.dart
// FIXES:
//   1. User.fromJson crash when stored JSON is malformed — wrapped in try/catch
//   2. Missing route for '/' (caused black screen on some navigation pops)
//   3. User model used a required positional constructor; now uses named params

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/user.dart';
import 'providers/auth_provider.dart';

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

  User? initialUser;

  try {
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString('user');
    if (storedUser != null) {
      initialUser = User.fromJson(
        jsonDecode(storedUser) as Map<String, dynamic>,
      );
    }
  } catch (_) {
    // Corrupted prefs — start fresh as guest
    initialUser = null;
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F5132),
          primary: const Color(0xFF0F5132),
          secondary: const Color(0xFF7B1023),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7EFE5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F5132),
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B1023),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF0F5132), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),

      // ── Routes ──────────────────────────────────────────────────────────
      home: const LandingScreen(),
      routes: {
        '/': (_) => const LandingScreen(),
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/internships': (_) => const InternshipListScreen(),
        '/matches': (_) => const MatchesScreen(),
        '/applications': (_) => const ApplicationsScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/post-internship': (_) => const PostInternshipScreen(),
        '/camera': (_) => const CameraScreen(),
      },
    );
  }
}
