// lib/service/auth_service.dart (Complete version)
import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../screens/login_screen/repository/login_repository.dart';
import '../screens/login_screen/model/login_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // SharedPreferences Keys
  static const String keyToken = 'token';
  static const String keyUsername = 'username';
  static const String keyPassword = 'password';
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyLastLoginTime = 'last_login_time';
  static const String keyTokenExpiry = 'token_expiry';
  static const String keyRememberMe = 'remember_me';
  static const String keyIsFirstLogin = 'is_first_login';

  // User Data Keys
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserMobile = 'user_mobile';
  static const String keyUserRole = 'user_role';
  static const String keyUserProject = 'user_project';
  static const String keyUserDistrict = 'user_district';

  // Permissions Keys
  static const String keyPermissions = 'permissions';

  // Private variables
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _isRefreshing = false;
  final List<Completer<bool>> _refreshCompleters = [];

  /// Load session from SharedPreferences
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user is logged in
      _isLoggedIn = prefs.getBool(keyIsLoggedIn) ?? false;

      if (_isLoggedIn) {
        // Check if token is expired
        final isExpired = await isTokenExpired();

        if (isExpired) {
          // Try to refresh token if remember me is enabled
          final rememberMe = prefs.getBool(keyRememberMe) ?? false;

          if (rememberMe) {
            final refreshed = await refreshToken();
            if (!refreshed) {
              // Refresh failed, clear session
              await clearAuthData();
              _isLoggedIn = false;
            }
          } else {
            // No remember me, clear session
            await clearAuthData();
            _isLoggedIn = false;
          }
        }
      }

      print("✅ Session loaded - Logged in: $_isLoggedIn");
    } catch (e) {
      print("❌ Error loading session: $e");
      _isLoggedIn = false;
    }
  }

  /// Get token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }

  /// Save token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
    await prefs.setString(keyLastLoginTime, DateTime.now().toIso8601String());

    // Set token expiry (e.g., 24 hours from now)
    final expiry = DateTime.now().add(const Duration(hours: 24));
    await prefs.setString(keyTokenExpiry, expiry.toIso8601String());

    _isLoggedIn = true;
    log("✅ Token saved with expiry: $expiry");
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();

    final expiryTimeStr = prefs.getString(keyTokenExpiry);
    if (expiryTimeStr != null) {
      try {
        final expiryTime = DateTime.parse(expiryTimeStr);
        // Consider expired if within 5 minutes of expiry
        final isExpired = DateTime.now().isAfter(expiryTime.subtract(const Duration(minutes: 5)));
        if (isExpired) {
          log("⚠️ Token expired at: $expiryTime");
        }
        return isExpired;
      } catch (e) {
        log("⚠️ Error parsing expiry time: $e");
      }
    }

    // Fallback: Check last login time (7 days expiry)
    final lastLoginTimeStr = prefs.getString(keyLastLoginTime);
    if (lastLoginTimeStr != null) {
      try {
        final lastLoginTime = DateTime.parse(lastLoginTimeStr);
        final expiryTime = lastLoginTime.add(const Duration(days: 7));
        final isExpired = DateTime.now().isAfter(expiryTime);
        if (isExpired) {
          log("⚠️ Token expired (7 days) at: $expiryTime");
        }
        return isExpired;
      } catch (e) {
        log("⚠️ Error parsing last login time: $e");
        return true;
      }
    }

    return true;
  }

// In AuthService.dart, update the refreshToken method:

  Future<bool> refreshToken() async {
    if (_isRefreshing) {
      log('⏳ Token refresh already in progress, waiting...');
      final completer = Completer<bool>();
      _refreshCompleters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;
    log('🔄 Starting token refresh process...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(keyRememberMe) ?? false;

      if (!rememberMe) {
        log('⚠️ Cannot refresh token - remember me was not enabled');
        _completeRefresh(false);
        return false;
      }

      String? username = prefs.getString(keyUsername);
      String? password = prefs.getString(keyPassword);

      if (username == null || password == null) {
        log('❌ Cannot refresh token - missing credentials');
        _completeRefresh(false);
        return false;
      }

      // Call login API to get new token
      log('🔄 Refreshing token with stored credentials for user: $username');

      final response = await UserNameLoginRepository().userNameLogin(
        LoginReqModel(userName: username, password: password),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final result = LoginResModel.fromJson(responseData);

        if (result.success == true && result.token != null) {
          // Save new token
          await saveToken(result.token!);

          // Update token expiry
          final expiry = DateTime.now().add(const Duration(hours: 24));
          await prefs.setString(keyTokenExpiry, expiry.toIso8601String());

          // Update is_first_login if needed
          if (result.isFirstLogin != null) {
            await prefs.setInt(keyIsFirstLogin, result.isFirstLogin!);
          }

          log('✅ Token refreshed successfully');
          _completeRefresh(true);
          return true;
        } else {
          log('❌ Token refresh failed - Invalid credentials');
          // Clear auth data on refresh failure
          await clearAuthData();
          _completeRefresh(false);
          return false;
        }
      } else if (response.statusCode == 401) {
        log('❌ Token refresh failed - 401 Unauthorized');
        // Clear auth data on 401
        await clearAuthData();
        _completeRefresh(false);
        return false;
      } else {
        log('❌ Token refresh failed - Status code: ${response.statusCode}');
        _completeRefresh(false);
        return false;
      }

    } catch (e) {
      log('❌ Error refreshing token: $e');
      // Clear auth data on error
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyToken);
      await prefs.remove(keyIsLoggedIn);
      _isLoggedIn = false;
      _completeRefresh(false);
      return false;
    }
  }

  /// Logout - Clear all user data
  Future<void> logout() async {
    log('🚪 Logging out user...');

    final prefs = await SharedPreferences.getInstance();

    // Clear all auth-related data
    await prefs.remove(keyToken);
    await prefs.remove(keyIsLoggedIn);
    await prefs.remove(keyLastLoginTime);
    await prefs.remove(keyTokenExpiry);
    await prefs.remove(keyIsFirstLogin);
    await prefs.remove(keyUserId);
    await prefs.remove(keyUserName);
    await prefs.remove(keyUserEmail);
    await prefs.remove(keyUserMobile);
    await prefs.remove(keyUserRole);
    await prefs.remove(keyUserProject);
    await prefs.remove(keyUserDistrict);
    await prefs.remove(keyPermissions);

    // Clear credentials if remember me is false
    final rememberMe = prefs.getBool(keyRememberMe) ?? false;
    if (!rememberMe) {
      await prefs.remove(keyUsername);
      await prefs.remove(keyPassword);
    }

    _isLoggedIn = false;
    log('✅ Logout successful');
  }

  /// Clear auth data (keep remember me if needed)
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(keyRememberMe) ?? false;
    final username = prefs.getString(keyUsername);

    // Clear all auth data
    await prefs.remove(keyToken);
    await prefs.remove(keyIsLoggedIn);
    await prefs.remove(keyLastLoginTime);
    await prefs.remove(keyTokenExpiry);
    await prefs.remove(keyIsFirstLogin);
    await prefs.remove(keyUserId);
    await prefs.remove(keyUserName);
    await prefs.remove(keyUserEmail);
    await prefs.remove(keyUserMobile);
    await prefs.remove(keyUserRole);
    await prefs.remove(keyUserProject);
    await prefs.remove(keyUserDistrict);
    await prefs.remove(keyPermissions);

    // Restore remember me settings if needed
    if (rememberMe && username != null) {
      await prefs.setBool(keyRememberMe, rememberMe);
      await prefs.setString(keyUsername, username);
    } else {
      await prefs.remove(keyRememberMe);
    }

    _isLoggedIn = false;
    log('🧹 Auth data cleared');
  }

  /// Save login response
  Future<void> saveLoginResponse(Map<String, dynamic> responseData) async {
    final prefs = await SharedPreferences.getInstance();

    // Save token
    if (responseData['token'] != null) {
      final token = responseData['token'];
      await prefs.setString(keyToken, token);
      await prefs.setString(keyLastLoginTime, DateTime.now().toIso8601String());

      // Calculate expiry from JWT if available
      final expiry = _getTokenExpiryFromJWT(token);
      if (expiry != null) {
        await prefs.setString(keyTokenExpiry, expiry.toIso8601String());
      } else {
        // Default expiry 24 hours
        final defaultExpiry = DateTime.now().add(const Duration(hours: 24));
        await prefs.setString(keyTokenExpiry, defaultExpiry.toIso8601String());
      }
    }

    // Save user data
    if (responseData['user'] != null) {
      final user = responseData['user'];
      if (user['id'] != null) await prefs.setInt(keyUserId, user['id']);
      if (user['username'] != null) await prefs.setString(keyUsername, user['username']);
      if (user['name'] != null) await prefs.setString(keyUserName, user['name']);
      if (user['email'] != null) await prefs.setString(keyUserEmail, user['email']);
      if (user['mobile'] != null) await prefs.setString(keyUserMobile, user['mobile']);
      if (user['role'] != null) await prefs.setString(keyUserRole, user['role'].toString());
      if (user['project'] != null) await prefs.setBool(keyUserProject, user['project']);
      if (user['district'] != null) await prefs.setString(keyUserDistrict, user['district']);
    }

    // Save permissions
    if (responseData['permissions'] != null) {
      await prefs.setString(keyPermissions, jsonEncode(responseData['permissions']));
    }

    // Save login status
    await prefs.setBool(keyIsLoggedIn, true);
    if (responseData['is_first_login'] != null) {
      await prefs.setInt(keyIsFirstLogin, responseData['is_first_login']);
    }

    _isLoggedIn = true;
    log('✅ Login response saved successfully');
  }

  /// Save credentials for remember me
  Future<void> saveCredentials(String username, String password, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();

    if (rememberMe) {
      await prefs.setString(keyUsername, username);
      await prefs.setString(keyPassword, password);
    } else {
      await prefs.remove(keyUsername);
      await prefs.remove(keyPassword);
    }

    await prefs.setBool(keyRememberMe, rememberMe);
    log('✅ Credentials saved - Remember me: $rememberMe');
  }

  /// Get remember me status
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyRememberMe) ?? false;
  }

  /// Get username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUsername);
  }

  /// Get password
  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyPassword);
  }

  /// Get user data
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt(keyUserId),
      'username': prefs.getString(keyUsername),
      'name': prefs.getString(keyUserName),
      'email': prefs.getString(keyUserEmail),
      'mobile': prefs.getString(keyUserMobile),
      'role': prefs.getString(keyUserRole),
      'project': prefs.getBool(keyUserProject),
      'district': prefs.getString(keyUserDistrict),
    };
  }
  Future<Map<String, dynamic>?> getPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionsString = prefs.getString(keyPermissions);

    if (permissionsString != null && permissionsString.isNotEmpty) {
      try {
        return jsonDecode(permissionsString);
      } catch (e) {
        log('❌ Error parsing permissions: $e');
        return null;
      }
    }
    return null;
  }

  /// Get valid token (checks expiry and refreshes if needed)
  Future<String?> getValidToken() async {
    bool expired = await isTokenExpired();

    if (!expired) {
      return await getToken();
    }

    log('🔄 Token expired, attempting refresh...');
    bool refreshed = await refreshToken();

    if (refreshed) {
      return await getToken();
    }

    log('❌ Could not get valid token');
    return null;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getValidToken();
    return token != null && token.isNotEmpty;
  }

  /// Parse JWT token expiry
  DateTime? _getTokenExpiryFromJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payloadData = json.decode(payload);

      if (payloadData.containsKey('exp')) {
        final expSeconds = payloadData['exp'];
        if (expSeconds is int) {
          return DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000);
        }
      }
    } catch (e) {
      log('⚠️ Error parsing JWT token: $e');
    }
    return null;
  }

  void _completeRefresh(bool success) {
    _isRefreshing = false;

    for (final completer in _refreshCompleters) {
      if (!completer.isCompleted) {
        completer.complete(success);
      }
    }
    _refreshCompleters.clear();
  }
}