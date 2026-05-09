// lib/services/api_service.dart
// Pattern: Singleton — single HTTP gateway for the whole app

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/internship.dart';
import '../models/application.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // ── Base URL ──────────────────────────────────────────────────────────────
  static String get baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  // ── Token helpers ─────────────────────────────────────────────────────────
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

  // ── Auth ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(
    String name, String email, String password, String type, {
    String? company, List<String>? skills,
    String? major, double? gpa,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name, 'email': email, 'password': password,
        'type': type, 'company': company, 'skills': skills,
        'major': major, 'gpa': gpa,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if ((res.statusCode == 200 || res.statusCode == 201) && data.containsKey('token')) {
      await setToken(data['token'] as String);
    }
    return data;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data.containsKey('token')) {
      await setToken(data['token'] as String);
    }
    return data;
  }

  static Future<Map<String, dynamic>?> getMe() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/me'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    return null;
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/profile'), headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Internships ───────────────────────────────────────────────────────────
  static Future<List<Internship>> getInternships({
    String keyword = '', String location = '', String field = '',
  }) async {
    final uri = Uri.parse('$baseUrl/internships').replace(queryParameters: {
      if (keyword.isNotEmpty)  'q':        keyword,
      if (location.isNotEmpty) 'location': location,
      if (field.isNotEmpty)    'field':    field,
    });
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => Internship.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> postInternship(
    String title, String description, String location,
    String field, List<String> requirements, DateTime deadline,
  ) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return {'error': 'Authentication required to post internships.'};
    }
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/internships'), headers: headers,
      body: jsonEncode({
        'title': title, 'description': description,
        'location': location, 'field': field,
        'requirements': requirements,
        'deadline': deadline.toIso8601String(),
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<Internship>> getMyInternships() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/internships/mine'), headers: headers);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => Internship.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Matches ───────────────────────────────────────────────────────────────
  static Future<List<Internship>> getMatches() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$baseUrl/matches'), headers: headers);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => Internship.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Applications ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> applyForInternship(
    String internshipId, {double? gpa, String? aboutMe, List<String>? documents,}
  ) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/apply'), headers: headers,
      body: jsonEncode({
        'internshipId': internshipId,
        'gpa': gpa, 'aboutMe': aboutMe, 'documents': documents,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<InternshipApplication>> getApplications({String? internshipId}) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return [];
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/applications').replace(queryParameters: {
      if (internshipId != null) 'internshipId': internshipId,
    });
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => InternshipApplication.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> updateApplicationStatus(String id, String status) async {
    final headers = await _authHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/applications/$id'), headers: headers,
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── File uploads ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> uploadCV(File cvFile) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return {'error': 'Authentication required.'};
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-cv'));
    req.headers['Authorization'] = 'Bearer $token';
    final ext = cvFile.path.split('.').last.toLowerCase();
    req.files.add(await http.MultipartFile.fromPath(
      'cv', cvFile.path,
      contentType: MediaType('application', ext == 'pdf' ? 'pdf' : 'octet-stream'),
    ));
    final streamed = await req.send();
    return jsonDecode(await streamed.stream.bytesToString()) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> sendPicture(File imageFile) async {
    final ext = imageFile.path.split('.').last.toLowerCase();
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-photo'));
    final token = await getToken();
    if (token != null && token.isNotEmpty) req.headers['Authorization'] = 'Bearer $token';
    req.files.add(await http.MultipartFile.fromPath(
      'photo', imageFile.path,
      contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
    ));
    final streamed = await req.send();
    return jsonDecode(await streamed.stream.bytesToString()) as Map<String, dynamic>;
  }

  // ── Analytics ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getAnalytics(String internshipId) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/analytics/internship/$internshipId'), headers: headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    return null;
  }
}
