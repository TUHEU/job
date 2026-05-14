// lib/providers/application_provider.dart
import 'package:flutter/material.dart';
import '../models/application.dart';
import '../services/api_service.dart';

class ApplicationProvider with ChangeNotifier {
  List<InternshipApplication> _applications = [];
  bool _isLoading = false;
  String? _error;

  List<InternshipApplication> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadApplications({String? internshipId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _applications = await ApiService.getApplications(
        internshipId: internshipId,
      );
    } catch (e) {
      _error = e.toString();
      _applications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> applyForInternship(
    String internshipId, {
    double? gpa,
    String? aboutMe,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.applyForInternship(
        internshipId,
        gpa: gpa,
        aboutMe: aboutMe,
      );
      if (result.containsKey('error')) {
        _error = result['error'];
        return false;
      }
      await loadApplications();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateApplicationStatus(String id, String status) async {
    try {
      final result = await ApiService.updateApplicationStatus(id, status);
      if (!result.containsKey('error')) {
        await loadApplications();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
