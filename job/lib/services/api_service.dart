// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/internship.dart';
import '../models/application.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    if (Platform.isIOS) return 'http://localhost:3000';
    return 'http://192.168.1.100:3000';
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Auth
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String type, {
    String? company,
    List<String>? skills,
    String? major,
    double? gpa,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'type': type,
          'company': company,
          'skills': skills,
          'major': major,
          'gpa': gpa,
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          data.containsKey('token'))
        await setToken(data['token'] as String);
      return data;
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data.containsKey('token'))
        await setToken(data['token'] as String);
      return data;
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _authHeaders();
      final res = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  // Internships
  static Future<List<Internship>> getInternships({
    String keyword = '',
    String location = '',
    String field = '',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/internships').replace(
        queryParameters: {
          if (keyword.isNotEmpty) 'q': keyword,
          if (location.isNotEmpty) 'location': location,
          if (field.isNotEmpty) 'field': field,
        },
      );
      final res = await http.get(uri);
      if (res.statusCode == 200)
        return (jsonDecode(res.body) as List)
            .map((e) => Internship.fromJson(e))
            .toList();
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Internship?> getInternshipById(String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/internships/$id'));
      if (res.statusCode == 200)
        return Internship.fromJson(jsonDecode(res.body));
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> postInternship(
    String title,
    String description,
    String location,
    String field,
    List<String> requirements,
    DateTime deadline,
  ) async {
    try {
      final headers = await _authHeaders();
      final res = await http.post(
        Uri.parse('$baseUrl/internships'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'location': location,
          'field': field,
          'requirements': requirements,
          'deadline': deadline.toIso8601String(),
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  static Future<List<Internship>> getMyInternships() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/internships/mine'),
        headers: headers,
      );
      if (res.statusCode == 200)
        return (jsonDecode(res.body) as List)
            .map((e) => Internship.fromJson(e))
            .toList();
      return [];
    } catch (e) {
      return [];
    }
  }

  // Matches
  static Future<List<Internship>> getMatches() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/matches'),
        headers: headers,
      );
      if (res.statusCode == 200)
        return (jsonDecode(res.body) as List)
            .map((e) => Internship.fromJson(e))
            .toList();
      return [];
    } catch (e) {
      return [];
    }
  }

  // Applications
  static Future<Map<String, dynamic>> applyForInternship(
    String internshipId, {
    double? gpa,
    String? aboutMe,
  }) async {
    try {
      final headers = await _authHeaders();
      final res = await http.post(
        Uri.parse('$baseUrl/apply'),
        headers: headers,
        body: jsonEncode({
          'internshipId': internshipId,
          if (gpa != null) 'gpa': gpa,
          if (aboutMe != null) 'aboutMe': aboutMe,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  static Future<List<InternshipApplication>> getApplications({
    String? internshipId,
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final headers = await _authHeaders();
      final uri = Uri.parse('$baseUrl/applications').replace(
        queryParameters: {
          if (internshipId != null) 'internshipId': internshipId,
        },
      );
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200)
        return (jsonDecode(res.body) as List)
            .map((e) => InternshipApplication.fromJson(e))
            .toList();
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateApplicationStatus(
    String id,
    String status,
  ) async {
    try {
      final headers = await _authHeaders();
      final res = await http.put(
        Uri.parse('$baseUrl/applications/$id'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  // File uploads
  static Future<Map<String, dynamic>> uploadCV(File cvFile) async {
    try {
      final token = await getToken();
      if (token == null) return {'error': 'Not logged in'};
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-cv'),
      );
      req.headers['Authorization'] = 'Bearer $token';
      req.files.add(await http.MultipartFile.fromPath('cv', cvFile.path));
      final res = await req.send();
      final body = await res.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'error': 'Upload failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendPicture(File imageFile) async {
    try {
      final token = await getToken();
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-photo'),
      );
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      req.files.add(await http.MultipartFile.fromPath('photo', imageFile.path));
      final res = await req.send();
      final body = await res.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'error': 'Upload failed: $e'};
    }
  }
}
