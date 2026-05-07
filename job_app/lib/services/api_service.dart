import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job.dart';
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
    return jsonDecode(response.body);
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

  static Future<List<Job>> getJobs() async {
    final response = await http.get(Uri.parse('$baseUrl/jobs'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Job.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> postJob(
    String title,
    String description,
    List<String> requirements,
  ) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/jobs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'requirements': requirements,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> applyForJob(String jobId) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/apply'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'jobId': jobId}),
    );
    return jsonDecode(response.body);
  }

  static Future<List<Application>> getApplications() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/applications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Application.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> updateApplicationStatus(
    String id,
    String status,
  ) async {
    final token = await getToken();
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

  static Future<List<Job>> getMatches() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/matches'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Job.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> uploadCV(File cvFile) async {
    final token = await getToken();
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
}
