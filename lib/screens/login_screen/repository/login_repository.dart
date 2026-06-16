// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:pms/network/end_point.dart';
// import '../model/login_model.dart';
//
// class UserNameLoginRepository {
//   Future<http.Response> userNameLogin(LoginReqModel reqModel) async {
//     final url = Uri.parse(Endpoint.employeeLogin);
//     final requestBody = jsonEncode(reqModel.toJson());
//
//     print("========== LOGIN REQUEST ==========");
//     print("URL: $url");
//     print("Request Body: $requestBody");
//     print("===================================");
//
//     try {
//       final response = await http.post(
//         url,
//         body: requestBody,
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       ).timeout(const Duration(seconds: 30));
//
//       print("========== LOGIN RESPONSE ==========");
//       print("Status Code: ${response.statusCode}");
//       print("Response Body: ${response.body}");
//       print("=====================================");
//
//       return response;
//     } catch (e) {
//       print("========== LOGIN ERROR ==========");
//       print("Error: $e");
//       print("=================================");
//       throw Exception("Network error: $e");
//     }
//   }
// }

// lib/screens/login_screen/repository/user_name_login_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pms/network/end_point.dart';
import '../../../service/api_client.dart';
import '../../../service/auth_service.dart';
import '../model/login_model.dart';

class UserNameLoginRepository {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  /// Method 1: Using direct HTTP client (Original way)
  Future<http.Response> userNameLogin(LoginReqModel reqModel) async {
    final url = Uri.parse(Endpoint.employeeLogin);
    final requestBody = jsonEncode(reqModel.toJson());

    print("========== LOGIN REQUEST ==========");
    print("URL: $url");
    print("Request Body: $requestBody");
    print("===================================");

    try {
      final response = await http.post(
        url,
        body: requestBody,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print("========== LOGIN RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("=====================================");

      return response;
    } catch (e) {
      print("========== LOGIN ERROR ==========");
      print("Error: $e");
      print("=================================");
      throw Exception("Network error: $e");
    }
  }

  /// Method 2: Using ApiClient (Recommended)
  Future<http.Response> userNameLoginWithApiClient(LoginReqModel reqModel) async {
    final requestBody = jsonEncode(reqModel.toJson());

    print("========== LOGIN REQUEST (ApiClient) ==========");
    print("URL: ${Endpoint.employeeLogin}");
    print("Request Body: $requestBody");
    print("================================================");

    try {
      final response = await _apiClient.post(
        Endpoint.employeeLogin,
        body: requestBody,
        requiresAuth: false, // Login doesn't require authentication
      );

      print("========== LOGIN RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("=====================================");

      return response;
    } catch (e) {
      print("========== LOGIN ERROR ==========");
      print("Error: $e");
      print("=================================");
      throw Exception("Network error: $e");
    }
  }

  /// Method 3: Using ApiHelper with full response handling
  Future<LoginResponse> userNameLoginWithHelper(
      LoginReqModel reqModel, {
        bool rememberMe = false,
      }) async {
    try {
      final response = await _apiClient.post(
        Endpoint.employeeLogin,
        body: jsonEncode(reqModel.toJson()),
        requiresAuth: false,
      );

      print("========== LOGIN HELPER RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("===========================================");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Parse response
        final loginResponse = LoginResponse.fromJson(data);

        // Save login data to AuthService if login successful
        if (loginResponse.success && loginResponse.token != null) {
          await _authService.saveLoginResponse(data);

          // Save credentials if remember me is enabled
          if (rememberMe && reqModel.userName != null && reqModel.password != null) {
            await _authService.saveCredentials(
              reqModel.userName!,
              reqModel.password!,
              rememberMe,
            );
          }
        }

        return loginResponse;
      } else {
        // Handle error response
        Map<String, dynamic> errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (e) {
          errorData = {'message': 'Login failed with status ${response.statusCode}'};
        }

        return LoginResponse(
          success: false,
          message: errorData['message'] ?? errorData['error'] ?? 'Login failed',
          token: null,
          user: null,
          permissions: null,
          isFirstLogin: 0,
        );
      }
    } catch (e) {
      print("========== LOGIN HELPER ERROR ==========");
      print("Error: $e");
      print("========================================");

      return LoginResponse(
        success: false,
        message: 'Network error: $e',
        token: null,
        user: null,
        permissions: null,
        isFirstLogin: 0,
      );
    }
  }

  /// Method 4: Enhanced version with token refresh support
  Future<LoginResponse> userNameLoginEnhanced(
      LoginReqModel reqModel, {
        bool rememberMe = false,
        Function(String? otpReference)? onOtpRequired,
      }) async {
    try {
      final response = await _apiClient.post(
        Endpoint.employeeLogin,
        body: jsonEncode(reqModel.toJson()),
        requiresAuth: false,
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      // Handle different response scenarios
      switch (response.statusCode) {
        case 200:
          final loginResponse = LoginResponse.fromJson(data);

          if (loginResponse.success && loginResponse.token != null) {
            // Successful login
            await _authService.saveLoginResponse(data);

            if (rememberMe && reqModel.userName != null && reqModel.password != null) {
              await _authService.saveCredentials(
                reqModel.userName!,
                reqModel.password!,
                rememberMe,
              );
            }

            return loginResponse;
          } else if (loginResponse.requiresOtp == true) {
            // OTP required
            onOtpRequired?.call(loginResponse.otpReference);
            return loginResponse;
          } else {
            // Login failed
            return loginResponse;
          }

        case 401:
          return LoginResponse(
            success: false,
            message: 'Invalid username or password',
          );

        case 403:
          return LoginResponse(
            success: false,
            message: 'Account is locked or inactive',
          );

        case 429:
          return LoginResponse(
            success: false,
            message: 'Too many attempts. Please try again later.',
          );

        default:
          return LoginResponse(
            success: false,
            message: data['message'] ?? 'Login failed. Please try again.',
          );
      }
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Network error: Unable to connect to server',
      );
    }
  }
}

/// Enhanced Login Response Model
class LoginResponse {
  final bool success;
  final String? message;
  final String? token;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? permissions;
  final int? isFirstLogin;
  final bool? requiresOtp;
  final String? otpReference;
  final String? email;

  LoginResponse({
    required this.success,
    this.message,
    this.token,
    this.user,
    this.permissions,
    this.isFirstLogin,
    this.requiresOtp,
    this.otpReference,
    this.email,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? json['error'],
      token: json['token'],
      user: json['user'],
      permissions: json['permissions'],
      isFirstLogin: json['is_first_login'],
      requiresOtp: json['requires_otp'] ?? json['otp_required'],
      otpReference: json['otp_reference'] ?? json['ref_no'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'user': user,
      'permissions': permissions,
      'is_first_login': isFirstLogin,
      'requires_otp': requiresOtp,
      'otp_reference': otpReference,
      'email': email,
    };
  }
}