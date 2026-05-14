// lib/main.dart - Updated version
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'providers/internship_provider.dart';
import 'providers/application_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/internship_list_screen.dart';
import 'screens/internship_detail_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/applications_screen.dart';
import 'screens/application_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/post_internship_screen.dart';
import 'screens/camera_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  User? restoredUser;
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedJson = prefs.getString('user');
    if (storedJson != null && storedJson.isNotEmpty) {
      restoredUser = User.fromJson(
        jsonDecode(storedJson) as Map<String, dynamic>,
      );
      if (restoredUser.isGuest) restoredUser = null;
    }
  } catch (e) {
    print('Error restoring user: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(initialUser: restoredUser),
        ),
        ChangeNotifierProvider(create: (_) => InternshipProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
      ],
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
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/landing':
        return MaterialPageRoute(builder: (_) => const LandingScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/internships':
        return MaterialPageRoute(builder: (_) => const InternshipListScreen());
      case '/internship-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) =>
              InternshipDetailScreen(internshipId: args?['id'] ?? ''),
        );
      case '/matches':
        return MaterialPageRoute(builder: (_) => const MatchesScreen());
      case '/applications':
        return MaterialPageRoute(builder: (_) => const ApplicationsScreen());
      case '/application-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) =>
              ApplicationDetailScreen(applicationId: args?['id'] ?? ''),
        );
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/post-internship':
        return MaterialPageRoute(builder: (_) => const PostInternshipScreen());
      case '/camera':
        return MaterialPageRoute(builder: (_) => const CameraScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LandingScreen());
    }
  }
}
