// // lib/screens/login_screen/repository/login_first_otp_email_repository.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:pms/network/end_point.dart';
// import '../model/login_first_otp_email_model.dart';
//
// class LoginOtpEmailRepository {
//   Future<http.Response> loginOtpEmail(
//       FirstEmailOtpReqModel reqModel, {
//         String? token,
//       }) async {
//     final url = Uri.parse(Endpoint.employeeLoginFirstOtp);
//     final requestBody = jsonEncode(reqModel.toJson());
//
//     print("========== LOGIN OTP REQUEST ==========");
//     print("URL: $url");
//     print("Request Body: $requestBody");
//     print("Token: $token");
//     print("Authorization Header: Bearer ${token ?? 'No Token'}");
//     print("=======================================");
//
//     try {
//       final response = await http.post(
//         url,
//         body: requestBody,
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token', // Add Bearer token
//         },
//       ).timeout(const Duration(seconds: 30));
//
//       print("========== LOGIN OTP RESPONSE ==========");
//       print("Status Code: ${response.statusCode}");
//       print("Response Body: ${response.body}");
//       print("========================================");
//
//       return response;
//     } catch (e) {
//       print("========== LOGIN OTP ERROR ==========");
//       print("Error: $e");
//       print("=====================================");
//       throw Exception("Network error: $e");
//     }
//   }
// }

// lib/screens/login_screen/repository/login_first_otp_email_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pms/network/end_point.dart';
import '../../../service/api_client.dart';
import '../../../service/auth_service.dart';
import '../model/login_first_otp_email_model.dart';

class LoginOtpEmailRepository {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();
  Future<http.Response> loginOtpEmail(
      FirstEmailOtpReqModel reqModel, {
        String? token,
      }) async {
    final url = Uri.parse(Endpoint.employeeLoginFirstOtp);
    final requestBody = jsonEncode(reqModel.toJson());
    String? authToken = token;
    if (authToken == null) {
      authToken = await _authService.getValidToken();
    }

    print("========== LOGIN OTP REQUEST ==========");
    print("URL: $url");
    print("Request Body: $requestBody");
    print("Token: $authToken");
    print("Authorization Header: Bearer ${authToken ?? 'No Token'}");
    print("=======================================");

    try {
      final response = await http.post(
        url,
        body: requestBody,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 30));

      print("========== LOGIN OTP RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("========================================");

      return response;
    } catch (e) {
      print("========== LOGIN OTP ERROR ==========");
      print("Error: $e");
      print("=====================================");
      throw Exception("Network error: $e");
    }
  }

  /// Method 2: Using ApiClient (Recommended)
  Future<http.Response> loginOtpEmailWithApiClient(
      FirstEmailOtpReqModel reqModel, {
        bool requiresAuth = true,
      }) async {
    final requestBody = jsonEncode(reqModel.toJson());

    print("========== LOGIN OTP REQUEST (ApiClient) ==========");
    print("URL: ${Endpoint.employeeLoginFirstOtp}");
    print("Request Body: $requestBody");
    print("Requires Auth: $requiresAuth");
    print("===================================================");

    try {
      final response = await _apiClient.post(
        Endpoint.employeeLoginFirstOtp,
        body: requestBody,
        requiresAuth: requiresAuth,
      );

      print("========== LOGIN OTP RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("========================================");

      return response;
    } catch (e) {
      print("========== LOGIN OTP ERROR ==========");
      print("Error: $e");
      print("=====================================");
      throw Exception("Network error: $e");
    }
  }


  Future<FirstEmailOtpResModel> loginOtpEmailWithHelper(
      FirstEmailOtpReqModel reqModel) async {
    try {
      final response = await _apiClient.post(
        Endpoint.employeeLoginFirstOtp,
        body: jsonEncode(reqModel.toJson()),
        requiresAuth: false, // Login endpoints typically don't require auth
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Save login response data to AuthService
        if (data['success'] == true && data['token'] != null) {
          await _authService.saveLoginResponse(data);
        }

        return FirstEmailOtpResModel.fromJson(data);
      } else {
        throw Exception('Failed to send OTP: ${response.statusCode}');
      }
    } catch (e) {
      print("Login OTP Error: $e");
      throw Exception("Failed to send OTP: $e");
    }
  }
}

