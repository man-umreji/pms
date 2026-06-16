// lib/providers/login_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pms/screens/login_screen/model/login_first_otp_email_model.dart';
import 'package:pms/screens/login_screen/model/login_model.dart';
import 'package:pms/screens/login_screen/view/login_otp_view.dart';
import 'package:pms/screens/main_screen/view/main_screen_view.dart';
import 'package:pms/widget/global_widgets/global_loding_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/auth_service.dart';
import '../../../widget/global_widgets/global_utils_snack_bar.dart';
import '../../dashbord/view_model/dashbord_view_model.dart';
import '../../meating_action_point_screen/view_mode/meating_action_point_view_model.dart';
import '../../meating_screen/view_model/meating_view_model.dart';
import '../model/submit_first_login_model.dart';
import '../repository/login_first_otp_email_repository.dart';
import '../repository/login_repository.dart';
import '../repository/submit_first_login_repo.dart';
import '../view/login_screen_view.dart';
import 'package:provider/provider.dart';
import '../view/submit_first_login.dart';

class LoginProvider extends ChangeNotifier {
  Timer? _timer;
  Timer? _otpTimer;
  String? _name;

  String? _email;
  String? _role;
  String? get role => _role;
  Permissions? _permissions;

  Permissions? get permissions => _permissions;

  String? get name => _name;
  String? get email => _email;
  bool _canCreate = false;
  bool get canCreate => _canCreate;

  // Permission helper methods
  bool hasCreatePermission() {
    final hasPermission = _permissions?.meetingActionPoints?.create ?? false;
    log("🔐 hasCreatePermission: $hasPermission");
    return hasPermission;
  }

  bool hasViewPermission() {
    final hasPermission = _permissions?.meetingActionPoints?.view ?? false;
    log("🔐 hasViewPermission: $hasPermission");
    return hasPermission;
  }

  bool hasUpdatePermission() {
    final hasPermission = _permissions?.meetingActionPoints?.update ?? false;
    log("🔐 hasUpdatePermission: $hasPermission");
    return hasPermission;
  }

  bool hasDeletePermission() {
    final hasPermission = _permissions?.meetingActionPoints?.delete ?? false;
    log("🔐 hasDeletePermission: $hasPermission");
    return hasPermission;
  }

  MeetingActionPoints? meetingActionPoints;

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserNameLoginRepository _nameLoginRepository = UserNameLoginRepository();
  LoginOtpEmailRepository _loginOtpEmailRepository = LoginOtpEmailRepository();
  SubmitFirstLoginRepository _submitFirstLoginRepository = SubmitFirstLoginRepository();

  // Controllers for FirstLoginVerification screen
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  // Timer for OTP
  int _remainingSeconds = 600;
  bool _isResendEnabled = false;

  // Store user data for OTP verification
  String? _currentToken;
  String? _currentUsername;
  String? _currentEmail;
  String? _currentUserId;

  // Getters
  GlobalKey<FormState> get formKey => _formKey;
  TextEditingController get userNameController => _emailController;
  TextEditingController get passwordController => _passwordController;

  bool get isLoading => _isLoading;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get obscureNewPassword => _obscureNewPassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  String? get error => _error;
  int get remainingSeconds => _remainingSeconds;
  bool get isResendEnabled => _isResendEnabled;

  String get formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Validation methods
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter User Name";
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your password";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  // Validate OTP for first login
  String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter OTP';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  // Validate New Password
  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, number & special character';
    }
    return null;
  }

  // Validate Confirm Password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleNewPasswordVisibility() {
    _obscureNewPassword = !_obscureNewPassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  // Start OTP Timer
  void startOtpTimer() {
    _otpTimer?.cancel();
    _remainingSeconds = 600;
    _isResendEnabled = false;

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        if (_remainingSeconds == 0) {
          _isResendEnabled = true;
          _otpTimer?.cancel();
        }
        notifyListeners();
      }
    });
    notifyListeners();
  }

  // Stop OTP Timer
  void stopOtpTimer() {
    _otpTimer?.cancel();
    _otpTimer = null;
  }

  // Load permissions from storage (call this on app start)
  Future<void> loadPermissionsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _name = prefs.getString("name");
      _email = prefs.getString("email");
      _canCreate = prefs.getBool("canCreate") ?? false;

      // Load full permissions object
      final permissionsString = prefs.getString("permissions");
      if (permissionsString != null && permissionsString.isNotEmpty) {
        final permissionsJson = jsonDecode(permissionsString);
        _permissions = Permissions.fromJson(permissionsJson);
        log("✅ Loaded permissions from storage: ${_permissions?.toJson()}");
      }

      notifyListeners();
    } catch (e) {
      log("❌ Error loading permissions: $e");
    }
  }

  // Login function
  Future<void> login(BuildContext context) async {
    final String username = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty) {
      _showSnackBar(context, "Please enter User Name", isError: true);
      return;
    }

    if (password.isEmpty) {
      _showSnackBar(context, "Please enter Password", isError: true);
      return;
    }

    DialogLoader.show(context, message: "Logging in...");

    try {
      final response = await _nameLoginRepository.userNameLogin(
        LoginReqModel(userName: username, password: password),
      );

      DialogLoader.hide(context);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final result = LoginResModel.fromJson(responseData);

        if (result.success == true) {
          log("✅ Login success");
          log("📦 Permissions from API: ${result.permissions?.toJson()}");

          // ✅ SHOW SUCCESS SNACKBAR
          _showSnackBar(
            context,
            "Login successful! Welcome back${result.user?.name != null ? ' ${result.user?.name}' : ''}",
            isError: false,
          );

          // ✅ SAVE FULL PERMISSIONS OBJECT
          _permissions = result.permissions;

          // Save individual permissions
          _canCreate = result.permissions?.meetingActionPoints?.create ?? false;
          _canCreate = result.permissions?.meetingActionPoints?.create ?? false;

          _currentUsername = result.user?.username;
          _currentEmail = result.user?.email;
          _currentUserId = result.user?.id?.toString();
          _name = result.user?.name;
          _role = result.user?.role;
          _email = result.user?.email;

          log("🔐 Create permission: $_canCreate");
          log("🔐 View permission: ${result.permissions?.meetingActionPoints?.view}");
          log("🔐 Update permission: ${result.permissions?.meetingActionPoints?.update}");
          log("🔐 Delete permission: ${result.permissions?.meetingActionPoints?.delete}");
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("name", _name ?? "");
          await prefs.setString("email", _email ?? "");
          await prefs.setString("role", _role ?? "");
          await prefs.setBool("canCreate", _canCreate);
          if (_permissions != null) {
            final permissionsJson = _permissions!.toJson();
            await prefs.setString("permissions", jsonEncode(permissionsJson));
            log("✅ Saved permissions to storage");
          }
          await AuthService().saveLoginResponse(responseData);
          await AuthService().saveCredentials(username, password, true);

          notifyListeners();

          if (result.isFirstLogin == 1) {
            await _sendOtpToEmail(context);
          } else {
            await Future.delayed(const Duration(milliseconds: 500));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreenView()),
            );
          }
        } else {
          _showSnackBar(
            context,
            responseData['message'] ?? "Login failed",
            isError: true,
          );
        }
      } else {
        _showSnackBar(
          context,
          responseData['message'] ?? "Server error",
          isError: true,
        );
      }
    } catch (error) {
      log("❌ Login Error: $error");
      DialogLoader.hide(context);
      _showSnackBar(
        context,
        "Network error. Please check your connection.",
        isError: true,
      );
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _canCreate = prefs.getBool("canCreate") ?? false;
    _name = prefs.getString("name");
    _email = prefs.getString("email");
    final permissionsString = prefs.getString("permissions");
    if (permissionsString != null && permissionsString.isNotEmpty) {
      final permissionsJson = jsonDecode(permissionsString);
      _permissions = Permissions.fromJson(permissionsJson);
    }

    notifyListeners();
  }

  Future<void> _sendOtpToEmail(BuildContext context) async {
    DialogLoader.show(context, message: "Sending OTP...");

    try {
      final token = await AuthService().getToken();

      final response = await _loginOtpEmailRepository.loginOtpEmail(
        FirstEmailOtpReqModel(
          userName: _currentUsername ?? _emailController.text.trim(),
        ),
        token: token,
      );

      DialogLoader.hide(context);

      final responseData = jsonDecode(response.body);
      final result = FirstEmailOtpResModel.fromJson(responseData);

      if (response.statusCode == 200 && result.success == true) {
        _currentUserId = result.userId;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "OTP sent successfully"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FirstLoginVerification(
              userId: _currentUserId,
              username: _currentUsername,
              email: _currentEmail,
            ),
          ),
        );
      } else {
        // Show error snackbar for 2 seconds
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Failed to send OTP"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      DialogLoader.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network error"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> resendOtp(BuildContext context) async {
    if (!_isResendEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Wait $formattedTime"),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    DialogLoader.show(context, message: "Resending OTP...");

    try {
      final token = await AuthService().getToken();

      final response = await _loginOtpEmailRepository.loginOtpEmail(
        FirstEmailOtpReqModel(
          userName: _currentUsername ?? _emailController.text.trim(),
        ),
        token: token,
      );

      DialogLoader.hide(context);

      final result = FirstEmailOtpResModel.fromJson(jsonDecode(response.body));

      if (response.statusCode == 200 && result.success == true) {
        startOtpTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "OTP resent"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Failed"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      DialogLoader.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network error"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Submit First Login Verification (Verify & Continue)
  Future<void> submitFirstLogin(BuildContext context) async {
    final otp = otpController.text.trim();
    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    final otpError = validateOtp(otp);
    if (otpError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final passwordError = validateNewPassword(newPassword);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passwordError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final confirmError = validateConfirmPassword(confirmPassword);
    if (confirmError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    DialogLoader.show(context, message: "Verifying...");

    try {
      final token = await AuthService().getValidToken();
      log("✅ Using Token: $token");

      final requestModel = SubmitFirstLoginReqModel(
        otp: otp,
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      final response = await _submitFirstLoginRepository.submitFirstLogin(
        requestModel,
      );

      DialogLoader.hide(context);

      final result = SubmitFirstLoginResModel.fromJson(jsonDecode(response.body));

      if (response.statusCode == 200 && result.success == true) {
        _clearFirstLoginForm();
        stopOtpTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password changed successfully"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainScreenView()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Failed to verify"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      DialogLoader.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network error"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    /// 🔥 SHOW MESSAGE FIRST
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully'),
        backgroundColor: Colors.green,
      ),
    );

    /// 🔥 CLEAR ALL TEXT CONTROLLERS
    _emailController.clear();
    _passwordController.clear();
    otpController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    oldPasswordController.clear();

    /// 🔥 CLEAR STORAGE DATA
    await prefs.clear();

    /// 🔥 CLEAR VIEW MODELS
    context.read<DashbordViewModel>().clearSummary();
    context.read<MeatingActionPointViewModel>().clearActionPoints();

    /// 🔥 RESET STATE VARIABLES
    _permissions = null;
    _canCreate = false;
    _name = null;
    _email = null;
    _currentToken = null;
    _currentUsername = null;
    _currentEmail = null;
    _currentUserId = null;
    _role=null;
    _isLoading = false;
    _isPasswordVisible = false;
    _obscureNewPassword = true;
    _obscureConfirmPassword = true;
    _error = null;

    /// 🔥 STOP TIMERS
    stopOtpTimer();
    _timer?.cancel();

    notifyListeners();

    /// 🔥 NAVIGATE (ROOT NAVIGATOR)
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreenView()),
          (route) => false,
    );
  }

  // Clear first login form
  void _clearFirstLoginForm() {
    otpController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    oldPasswordController.clear();
    _remainingSeconds = 600;
    _isResendEnabled = false;
    _obscureNewPassword = true;
    _obscureConfirmPassword = true;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    oldPasswordController.dispose();
    _timer?.cancel();
    _otpTimer?.cancel();
    super.dispose();
  }
}