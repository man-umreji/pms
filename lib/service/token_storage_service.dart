// lib/services/token_storage_service.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../screens/login_screen/model/login_model.dart';

class TokenStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _permissionsKey = 'user_permissions';

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // Save token
  Future<void> saveToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(_tokenKey, token);
  }

  // Get token
  Future<String?> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_tokenKey);
  }

  // Save user data
  Future<void> saveUserData(User? user) async {
    if (user == null) return;
    final prefs = await _getPrefs();
    await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
  }

  // Get user data
  Future<User?> getUserData() async {
    final prefs = await _getPrefs();
    final userJson = prefs.getString(_userDataKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    return null;
  }

  // Save permissions
  Future<void> savePermissions(Permissions? permissions) async {
    if (permissions == null) return;
    final prefs = await _getPrefs();
    await prefs.setString(_permissionsKey, jsonEncode(permissions.toJson()));
  }

  // Get permissions
  Future<Permissions?> getPermissions() async {
    final prefs = await _getPrefs();
    final permissionsJson = prefs.getString(_permissionsKey);
    if (permissionsJson != null) {
      return Permissions.fromJson(jsonDecode(permissionsJson) as Map<String, dynamic>);
    }
    return null;
  }

  // Clear all data
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_permissionsKey);
  }
}