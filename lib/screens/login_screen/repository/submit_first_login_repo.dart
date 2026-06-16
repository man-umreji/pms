import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../service/api_client.dart';
import '../model/submit_first_login_model.dart';

class SubmitFirstLoginRepository {
  final ApiClient _apiClient = ApiClient();
  Future<http.Response> submitFirstLogin(
      SubmitFirstLoginReqModel model,
      ) async {
    final requestBody = jsonEncode(model.toJson());

    print("========== SUBMIT FIRST LOGIN REQUEST ==========");
    print("Endpoint: /api/Pms_api/submit_first_login");
    print("Request Body: $requestBody");
    print("================================================");

    try {
      final response = await _apiClient.post(
        "/api/Pms_api/submit_first_login",
        body: requestBody,
        requiresAuth: true,
      );

      print("========== SUBMIT FIRST LOGIN RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("=================================================");

      return response;
    } catch (e) {
      print("========== SUBMIT FIRST LOGIN ERROR ==========");
      print("Error: $e");
      print("==============================================");
      throw Exception("Network error: $e");
    }
  }

  /// ✅ OPTIONAL: CLEAN RESPONSE PARSER
  Future<SubmitFirstLoginResModel> submitFirstLoginParsed(
      SubmitFirstLoginReqModel model,
      ) async {
    try {
      final response = await submitFirstLogin(model);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SubmitFirstLoginResModel.fromJson(data);
      } else {
        return SubmitFirstLoginResModel(
          success: false,
          message: data['message'] ?? "Failed",
        );
      }
    } catch (e) {
      return SubmitFirstLoginResModel(
        success: false,
        message: "Network error",
      );
    }
  }
}