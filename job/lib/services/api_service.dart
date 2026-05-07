import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/internship.dart';
import '../models/application.dart';

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; // Android emulator
    }
    return 'http://localhost:3000';
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
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String type, {
    String? company,
    List<String>? skills,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'type': type,
        'company': company,
        'skills': skills,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data.containsKey('token')) {
        await setToken(data['token']);
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    }
    return jsonDecode(response.body);
  }

  static Future<List<Internship>> getInternships() async {
    final response = await http.get(Uri.parse('$baseUrl/internships'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Internship.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> postInternship(
    String title,
    String description,
    String location,
    String field,
    List<String> requirements,
    DateTime deadline,
  ) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message':
            'Guest mode is active. Posting an internship requires authentication.',
      };
    }

    final response = await http.post(
      Uri.parse('$baseUrl/internships'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'location': location,
        'field': field,
        'requirements': requirements,
        'deadline': deadline.toIso8601String(),
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> applyForInternship(
    String internshipId, {
    double? gpa,
    String? aboutMe,
    List<String>? documents,
  }) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('$baseUrl/apply'),
      headers: headers,
      body: jsonEncode({
        'internshipId': internshipId,
        'gpa': gpa,
        'aboutMe': aboutMe,
        'documents': documents,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<List<InternshipApplication>> getApplications() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return [];
    }
    final response = await http.get(
      Uri.parse('$baseUrl/applications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => InternshipApplication.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> updateApplicationStatus(
    String id,
    String status,
  ) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message':
            'Guest mode is active. Updating application status requires authentication.',
      };
    }

    final response = await http.put(
      Uri.parse('$baseUrl/applications/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(response.body);
  }

  static Future<List<Internship>> getMatches() async {
    final token = await getToken();
    final headers = {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(
      Uri.parse('$baseUrl/matches'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Internship.fromJson(e)).toList();
    }
    return [];
  }

  // For CV upload, need multipart, but for simplicity, assume text CV or use file_picker
  static Future<Map<String, dynamic>> uploadCV(File cvFile) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return {
        'success': true,
        'message':
            'CV upload is disabled in guest mode, but your file is ready to share locally.',
      };
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload-cv'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'cv',
        cvFile.path,
        contentType: MediaType(
          'application',
          'pdf',
        ), // Adjust based on file type
      ),
    );
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    return jsonDecode(responseBody);
  }

  static Future<Map<String, dynamic>> sendPicture(File imageFile) async {
    final extension = imageFile.path.split('.').last.toLowerCase();
    final imageType = extension == 'png' ? 'png' : 'jpeg';
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload-photo'),
    );

    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        contentType: MediaType('image', imageType),
      ),
    );
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    return jsonDecode(responseBody);
  }
}
