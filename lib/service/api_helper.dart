import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ApiHeaders {
  static final AuthService _authService = AuthService();

  /// Get headers with valid token (throws exception if no token)
  static Future<Map<String, String>> get() async {
    final token = await _authService.getValidToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception("Token missing or invalid");
    }

    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer ${token.trim()}",
    };
  }

  /// Get fresh headers by forcing token refresh
  static Future<Map<String, String>> getFresh() async {
    await _authService.refreshToken();
    final token = await _authService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception("Token missing or invalid");
    }

    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer ${token.trim()}",
    };
  }

  /// Get headers if available (returns null if no token)
  static Future<Map<String, String>?> getIfAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer ${token.trim()}",
    };
  }

  /// Get headers without authentication
  static Map<String, String> getPublic() {
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
    };
  }
}