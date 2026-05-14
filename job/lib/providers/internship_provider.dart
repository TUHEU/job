// lib/providers/internship_provider.dart
import 'package:flutter/material.dart';
import '../models/internship.dart';
import '../services/api_service.dart';

class InternshipProvider with ChangeNotifier {
  List<Internship> _internships = [];
  List<Internship> _myInternships = [];
  List<Internship> _matches = [];
  bool _isLoading = false;
  String? _error;

  List<Internship> get internships => _internships;
  List<Internship> get myInternships => _myInternships;
  List<Internship> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInternships({
    String keyword = '',
    String location = '',
    String field = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _internships = await ApiService.getInternships(
        keyword: keyword,
        location: location,
        field: field,
      );
    } catch (e) {
      _error = e.toString();
      _internships = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyInternships() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myInternships = await ApiService.getMyInternships();
    } catch (e) {
      _error = e.toString();
      _myInternships = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMatches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _matches = await ApiService.getMatches();
    } catch (e) {
      _error = e.toString();
      _matches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postInternship(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.postInternship(
        data['title'],
        data['description'],
        data['location'],
        data['field'],
        List<String>.from(data['requirements']),
        data['deadline'],
      );
      if (result.containsKey('error')) {
        _error = result['error'];
        return false;
      }
      await loadMyInternships();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
