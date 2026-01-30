import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSelectionProvider extends ChangeNotifier {
  String? _departmentId;
  String? _yearId;
  String? _sectionId;

  String? get departmentId => _departmentId;
  String? get yearId => _yearId;
  String? get sectionId => _sectionId;

  bool get hasSelection => _departmentId != null && _yearId != null && _sectionId != null;

  UserSelectionProvider() {
    loadSelection();
  }

  Future<void> loadSelection() async {
    final prefs = await SharedPreferences.getInstance();
    _departmentId = prefs.getString('departmentId');
    _yearId = prefs.getString('yearId');
    _sectionId = prefs.getString('sectionId');
    notifyListeners();
  }

  Future<void> saveSelection({
    required String departmentId,
    required String yearId,
    required String sectionId,
  }) async {
    _departmentId = departmentId;
    _yearId = yearId;
    _sectionId = sectionId;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('departmentId', departmentId);
    await prefs.setString('yearId', yearId);
    await prefs.setString('sectionId', sectionId);
    
    notifyListeners();
  }

  Future<void> clearSelection() async {
    _departmentId = null;
    _yearId = null;
    _sectionId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('departmentId');
    await prefs.remove('yearId');
    await prefs.remove('sectionId');

    notifyListeners();
  }
}
