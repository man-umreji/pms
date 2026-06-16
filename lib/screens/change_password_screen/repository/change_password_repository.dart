import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../service/api_client.dart';
import '../model/change_password_model.dart';

class ChangePasswordRepository {
  final ApiClient _apiClient = ApiClient();

  /// ✅ MAIN METHOD (use this everywhere)
  Future<http.Response> changePassword(
      ChangePasswordReqModel model,
      ) async {
    final requestBody = jsonEncode(model.toJson());

    print("========== CHANGE PASSWORD REQUEST ==========");
    print("Endpoint: /api/Pms_api/change_password"); // 🔁 update if different
    print("Request Body: $requestBody");
    print("=============================================");

    try {
      final response = await _apiClient.post(
        "/api/Pms_api/change_password", // 🔁 confirm endpoint
        body: requestBody,
        requiresAuth: true, // ✅ token auto attached
      );

      print("========== CHANGE PASSWORD RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("==============================================");

      return response;
    } catch (e) {
      print("========== CHANGE PASSWORD ERROR ==========");
      print("Error: $e");
      print("==========================================");
      throw Exception("Network error: $e");
    }
  }

  /// ✅ OPTIONAL: parsed response
  Future<ChangePasswordResModel> changePasswordParsed(
      ChangePasswordReqModel model,
      ) async {
    try {
      final response = await changePassword(model);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ChangePasswordResModel.fromJson(data);
      } else {
        return ChangePasswordResModel(
          success: false,
          message: data['message'] ?? "Failed to change password",
        );
      }
    } catch (e) {
      return ChangePasswordResModel(
        success: false,
        message: "Network error",
      );
    }
  }
}