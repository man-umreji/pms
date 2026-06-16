import 'dart:convert';

import '../../../network/end_point.dart';
import '../../../service/api_client.dart';
import '../model/get_all_status_model.dart';

class GetAllStatusRepository {
  final ApiClient _apiClient = ApiClient();

  /// Fetch all available action statuses using POST
  Future<GetAllStatusResModel> getAllStatus() async {
    try {
      final response = await _apiClient.post(
        Endpoint.getAllStatus,
        body: jsonEncode({}),
        requiresAuth: true,
      );
      print("========== GET ALL STATUS REQUEST ==========");
      print("URL: ${Endpoint.getAllStatus}");
      print("Method: POST");
      print("Body: {}");
      print("===========================================");

      print("========== GET ALL STATUS RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("============================================");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return GetAllStatusResModel.fromJson(data);
      } else {
        return GetAllStatusResModel(
          success: false,
          statusList: null,
        );
      }
    } catch (e) {
      print("❌ GET ALL STATUS ERROR: $e");

      return GetAllStatusResModel(
        success: false,
        statusList: null,
      );
    }
  }

// ... rest of the optional methods remain the same
}