// lib/screens/splash_screen/view/splash_screen_simple.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/auth_service.dart';
import '../../login_screen/model/login_model.dart';
import '../../login_screen/view/login_screen_view.dart';
import '../../login_screen/view_model/login_screen_view_model.dart';
import '../../main_screen/view/main_screen_view.dart';

class SplashScreenSimple extends StatefulWidget {
  const SplashScreenSimple({Key? key}) : super(key: key);

  @override
  State<SplashScreenSimple> createState() => _SplashScreenSimpleState();
}

class _SplashScreenSimpleState extends State<SplashScreenSimple> {
  final AuthService _authService = AuthService();
  String? _errorMessage;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final startTime = DateTime.now();

    try {
      // Load session from storage
      await _authService.loadSession();

      // Load permissions and user data if logged in
      if (_authService.isLoggedIn) {
        await _loadUserPermissions();
      }

      // Ensure minimum splash duration for smooth transition
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < const Duration(seconds: 2)) {
        await Future.delayed(const Duration(seconds: 2) - elapsed);
      }

      if (!mounted) return;

      // Navigate based on login status
      await _navigateToNextScreen();

    } catch (e) {
      print("❌ SplashScreen error: $e");
      _errorMessage = e.toString();

      // Still ensure minimum duration on error
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < const Duration(seconds: 1)) {
        await Future.delayed(const Duration(seconds: 1) - elapsed);
      }

      if (!mounted) return;

      // Navigate to login on error
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreenView(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  /// Load user permissions and data from SharedPreferences
  Future<void> _loadUserPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user data
      final name = prefs.getString('name');
      final email = prefs.getString('email');
      final userId = prefs.getInt('user_id');
      final isFirstLogin = prefs.getInt('is_first_login') ?? 0;

      print("✅ Loaded user data - Name: $name, Email: $email, First Login: $isFirstLogin");

      // Load permissions
      final permissionsString = prefs.getString('permissions');
      if (permissionsString != null && permissionsString.isNotEmpty) {
        try {
          final permissionsJson = jsonDecode(permissionsString);
          final permissions = Permissions.fromJson(permissionsJson);

          print("✅ Loaded permissions - Create: ${permissions.meetingActionPoints?.create}");
          print("✅ Loaded permissions - View: ${permissions.meetingActionPoints?.view}");
          print("✅ Loaded permissions - Update: ${permissions.meetingActionPoints?.update}");
          print("✅ Loaded permissions - Delete: ${permissions.meetingActionPoints?.delete}");

          // Update LoginProvider if available
          if (mounted) {
            try {
              final loginProvider = Provider.of<LoginProvider>(context, listen: false);
              // Use reflection or add a method to update permissions
              // For now, we'll reload from storage in LoginProvider
              await loginProvider.loadUserData();
            } catch (e) {
              print("⚠️ Could not update LoginProvider: $e");
            }
          }
        } catch (e) {
          print("❌ Error parsing permissions: $e");
        }
      } else {
        print("⚠️ No permissions found in storage");
      }

      // Validate token
      final isValidToken = await _validateToken();
      if (!isValidToken && _authService.isLoggedIn) {
        print("⚠️ Token expired or invalid");
        await _authService.logout();
      }

    } catch (e) {
      print("❌ Error loading permissions: $e");
    }
  }

  /// Validate token and refresh if needed
  Future<bool> _validateToken() async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        return false;
      }

      // Check token expiry
      final isExpired = await _authService.isTokenExpired();

      if (isExpired) {
        final rememberMe = await _authService.getRememberMe();

        if (rememberMe) {
          print("🔄 Token expired, attempting to refresh...");
          final refreshed = await _authService.refreshToken();
          return refreshed;
        } else {
          return false;
        }
      }

      return true;
    } catch (e) {
      print("❌ Token validation error: $e");
      return false;
    }
  }

  /// Navigate to appropriate screen based on login status
  Future<void> _navigateToNextScreen() async {
    if (_authService.isLoggedIn) {
      // Check if first login is required
      final prefs = await SharedPreferences.getInstance();
      final isFirstLogin = prefs.getInt('is_first_login') ?? 0;

      if (isFirstLogin == 1) {
        print("🔄 First login detected, redirecting to login for OTP verification");
        // User needs to complete first login (OTP verification)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreenView(),
          ),
        );
      } else {
        print("✅ User logged in, navigating to MainScreen");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreenView(),
          ),
        );
      }
    } else {
      print("❌ User not logged in, navigating to LoginScreen");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreenView(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.lightBlue],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.business_center,
                size: 50,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'PMS System',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Project Management System',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 50),

            // Loading indicator
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),

            const SizedBox(height: 20),

            // Optional: Show error message if any
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 30),

            // Version info
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}