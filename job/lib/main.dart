import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'screens/camera_screen.dart';
import 'screens/home_screen.dart';
import 'screens/internship_list_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/post_internship_screen.dart';
import 'screens/applications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storedUser = prefs.getString('user');

  User? initialUser;
  if (storedUser != null) {
    initialUser = User.fromJson(jsonDecode(storedUser));
  } else {
    initialUser = User(
      id: 'guest',
      name: 'Guest User',
      email: 'guest@jobmatch.cameroon',
      type: 'intern',
      skills: ['Local hiring', 'Career coaching'],
    );
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(initialUser: initialUser),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goinus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF14563A),
          primary: const Color(0xFF14563A),
          secondary: const Color(0xFF8D1F4A),
        ),
        brightness: Brightness.light,
        cardTheme: const CardThemeData(
          color: Colors.white,
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF14563A),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8D1F4A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7EFE5),
      ),

      home: const LandingScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/internships': (context) => const InternshipListScreen(),
        '/matches': (context) => const MatchesScreen(),
        '/post-internship': (context) => const PostInternshipScreen(),
        '/applications': (context) => const ApplicationsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/camera': (context) => const CameraScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
