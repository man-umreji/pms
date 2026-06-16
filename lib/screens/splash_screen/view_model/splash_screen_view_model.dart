// lib/providers/splash_provider.dart (Enhanced version)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/auth_service.dart';
import '../../login_screen/model/login_model.dart';
import '../../login_screen/view/login_screen_view.dart';
import '../../login_screen/view_model/login_screen_view_model.dart';
import '../../main_screen/view/main_screen_view.dart';
import 'package:provider/provider.dart';

class SplashProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;
  Permissions? _permissions;
  bool _isFirstLogin = false;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;
  Permissions? get permissions => _permissions;
  bool get isFirstLogin => _isFirstLogin;

  /// Initialize splash screen and load session
  Future<void> init(BuildContext context) async {
    if (!_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final startTime = DateTime.now();

      // Load session from storage
      await _authService.loadSession();

      // Load user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      if (_authService.isLoggedIn) {
        _isLoggedIn = true;

        // Load user data
        final name = prefs.getString('name') ?? '';
        final email = prefs.getString('email') ?? '';
        final userId = prefs.getInt('user_id') ?? 0;

        _userData = {
          'name': name,
          'email': email,
          'id': userId,
        };

        // Load permissions from storage
        final permissionsString = prefs.getString('permissions');
        if (permissionsString != null && permissionsString.isNotEmpty) {
          try {
            final permissionsJson = jsonDecode(permissionsString);
            _permissions = Permissions.fromJson(permissionsJson);
            print("✅ Loaded permissions in SplashProvider: ${_permissions?.toJson()}");
          } catch (e) {
            print("❌ Error parsing permissions: $e");
          }
        }

        // Check if first login is required
        _isFirstLogin = prefs.getInt('is_first_login') == 1;

        // Validate token
        final isValidToken = await validateAndRefreshToken();

        if (!isValidToken) {
          // Token expired and couldn't refresh
          _isLoggedIn = false;
          _userData = null;
          _permissions = null;
          // await _authService.logout();
        }
      } else {
        _isLoggedIn = false;
        _userData = null;
        _permissions = null;
      }

      // Ensure minimum splash duration (for smooth transition)
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < const Duration(seconds: 2)) {
        await Future.delayed(const Duration(seconds: 2) - elapsed);
      }

      // Navigate after loading
      if (context.mounted) {
        _navigateToNextScreen(context);
      }

    } catch (e) {
      _errorMessage = e.toString();
      print("SplashProvider error: $e");

      // Ensure minimum splash duration on error too
      final startTime = DateTime.now();
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < const Duration(seconds: 1)) {
        await Future.delayed(const Duration(seconds: 1) - elapsed);
      }

      if (context.mounted) {
        // Navigate to login on error
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreenView(),
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Navigate to appropriate screen
  void _navigateToNextScreen(BuildContext context) {
    if (_isLoggedIn && _authService.isLoggedIn) {
      // User is logged in
      if (_isFirstLogin) {
        // First login - go to first login OTP screen
        // You can navigate to FirstLoginVerification screen here
        // But usually it's better to handle this in the main flow
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreenView(),
          ),
        );
      } else {
        // Normal user - go to main screen
        // Update LoginProvider with permissions before navigating
        _updateLoginProvider(context);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreenView(),
          ),
        );
      }
    } else {
      // User not logged in - go to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreenView(),
        ),
      );
    }
  }

  /// Update LoginProvider with loaded permissions and user data
  void _updateLoginProvider(BuildContext context) {
    try {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);

      // Update user data
      if (_userData != null) {
        // Use reflection or set values directly if you have setters
        // For now, we'll just ensure the provider loads from storage
        loginProvider.loadUserData();
      }

      print("✅ LoginProvider updated from SplashProvider");
    } catch (e) {
      print("❌ Error updating LoginProvider: $e");
    }
  }

  /// Check token validity and refresh if needed
  Future<bool> validateAndRefreshToken() async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        return false;
      }

      final isExpired = await _authService.isTokenExpired();

      if (isExpired) {
        final rememberMe = await _authService.getRememberMe();

        if (rememberMe) {
          final refreshed = await _authService.refreshToken();
          return refreshed;
        } else {
          return false;
        }
      }

      return true;
    } catch (e) {
      print("Token validation error: $e");
      return false;
    }
  }

  /// Get permissions for current user
  bool hasPermission(String permissionType) {
    if (_permissions == null) return false;

    switch (permissionType.toLowerCase()) {
      case 'create':
        return _permissions?.meetingActionPoints?.create ?? false;
      case 'view':
        return _permissions?.meetingActionPoints?.view ?? false;
      case 'update':
        return _permissions?.meetingActionPoints?.update ?? false;
      case 'delete':
        return _permissions?.meetingActionPoints?.delete ?? false;
      default:
        return false;
    }
  }

  /// Reset provider state
  void reset() {
    _isLoading = true;
    _isLoggedIn = false;
    _errorMessage = null;
    _userData = null;
    _permissions = null;
    _isFirstLogin = false;
    notifyListeners();
  }
}