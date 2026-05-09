// lib/services/api_service.dart
// Pattern: Singleton — single HTTP gateway for the whole app
// Backend: http://192.168.1.191:3000

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

  // ── Base URL ───────────────────────────────────────────────────────────────
  // Your PC local IP — works for Android emulator, real phone, and iOS
  // simulator as long as your phone/emulator is on the same Wi-Fi network.
  static const String baseUrl = 'http://192.168.1.191:3000';

  // ── Token helpers ──────────────────────────────────────────────────────────
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

  // ── Health check ───────────────────────────────────────────────────────────
  static Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Auth ───────────────────────────────────────────────────────────────────
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
          data.containsKey('token')) {
        await setToken(data['token'] as String);
      }
      return data;
    } on SocketException {
      return {'error': 'Cannot reach server at $baseUrl — is Flask running?'};
    } catch (e) {
      return {'error': 'Unexpected error: $e'};
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
      if (res.statusCode == 200 && data.containsKey('token')) {
        await setToken(data['token'] as String);
      }
      return data;
    } on SocketException {
      return {'error': 'Cannot reach server at $baseUrl — is Flask running?'};
    } catch (e) {
      return {'error': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(Uri.parse('$baseUrl/me'), headers: headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
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
    } on SocketException {
      return {'error': 'Cannot reach server at $baseUrl'};
    } catch (e) {
      return {'error': 'Unexpected error: $e'};
    }
  }

  // ── Internships ────────────────────────────────────────────────────────────
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
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List)
            .map((e) => Internship.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
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
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return {'error': 'You must be logged in as a company to post.'};
      }
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
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on SocketException {
      return {'error': 'Cannot reach server at $baseUrl'};
    } catch (e) {
      return {'error': 'Unexpected error: $e'};
    }
  }

  static Future<List<Internship>> getMyInternships() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/internships/mine'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List)
            .map((e) => Internship.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Matches ────────────────────────────────────────────────────────────────
  static Future<List<Internship>> getMatches() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/matches'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List)
            .map((e) => Internship.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Applications ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> applyForInternship(
    String internshipId, {
    double? gpa,
    String? aboutMe,
    List<String>? documents,
  }) async {
    try {
      final headers = await _authHeaders();
      final res = await http.post(
        Uri.parse('$baseUrl/apply'),
        headers: headers,
        body: jsonEncode({
          'internshipId': internshipId,
          'gpa': gpa,
          'aboutMe': aboutMe,
          'documents': documents,
        }),
      );
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on SocketException {
      return {'error': 'Cannot reach server at $baseUrl'};
    } catch (e) {
      return {'error': 'Unexpected error: $e'};
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
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List)
            .map(
              (e) => InternshipApplication.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (_) {
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
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on SocketException {
      return {'error': 'Cannot reach server at $baseUrl'};
    } catch (e) {
      return {'error': 'Unexpected error: $e'};
    }
  }

  // ── File uploads ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> uploadCV(File cvFile) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return {'error': 'You must be logged in to upload a CV.'};
      }
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-cv'),
      );
      req.headers['Authorization'] = 'Bearer $token';
      final ext = cvFile.path.split('.').last.toLowerCase();
      req.files.add(
        await http.MultipartFile.fromPath(
          'cv',
          cvFile.path,
          contentType: MediaType(
            'application',
            ext == 'pdf' ? 'pdf' : 'octet-stream',
          ),
        ),
      );
      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      return jsonDecode(body) as Map<String, dynamic>;
    } on SocketException {
      return {'error': 'Cannot reach server at $baseUrl'};
    } catch (e) {
      return {'error': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendPicture(File imageFile) async {
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-photo'),
      );
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      req.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
          contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
        ),
      );
      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      return jsonDecode(body) as Map<String, dynamic>;
    } on SocketException {
      return {'error': 'Cannot reach server at $baseUrl'};
    } catch (e) {
      return {'error': 'Unexpected error: $e'};
    }
  }

  // ── Analytics ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getAnalytics(String internshipId) async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/analytics/internship/$internshipId'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Candidate search (company only) ───────────────────────────────────────
  static Future<List<Map<String, dynamic>>> searchCandidates({
    String skills = '',
    String major = '',
    double? minGpa,
  }) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('$baseUrl/candidates').replace(
        queryParameters: {
          if (skills.isNotEmpty) 'skills': skills,
          if (major.isNotEmpty) 'major': major,
          if (minGpa != null) 'min_gpa': minGpa.toString(),
        },
      );
      final res = await http.get(uri, headers: headers);
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
