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
    // Use microtask to avoid build phase issues
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
      final internships = await ApiService.getInternships(
        keyword: keyword,
        location: location,
        field: field,
      );
      _internships = internships;
    } catch (e) {
      _error = e.toString();
      _internships = [];
    } finally {
      await Future.microtask(() {
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> loadMyInternships() async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
      final internships = await ApiService.getMyInternships();
      _myInternships = internships;
    } catch (e) {
      _error = e.toString();
      _myInternships = [];
    } finally {
      await Future.microtask(() {
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<void> loadMatches() async {
    // Use addPostFrameCallback to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });

    try {
      final matches = await ApiService.getMatches();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _matches = matches;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _error = e.toString();
        _matches = [];
        _isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<bool> postInternship(Map<String, dynamic> data) async {
    await Future.microtask(() {
      _isLoading = true;
      _error = null;
      notifyListeners();
    });

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
        await Future.microtask(() {
          _isLoading = false;
          notifyListeners();
        });
        return false;
      }
      await loadMyInternships();
      return true;
    } catch (e) {
      _error = e.toString();
      await Future.microtask(() {
        _isLoading = false;
        notifyListeners();
      });
      return false;
    }
  }

  Future<bool> deleteInternship(String id) async {
    try {
      final result = await ApiService.deleteInternship(id);
      if (!result.containsKey('error')) {
        await loadMyInternships();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
