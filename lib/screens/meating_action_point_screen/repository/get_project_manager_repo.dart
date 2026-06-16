import 'dart:convert';
import '../../../network/end_point.dart';
import '../../../service/api_client.dart';
import '../model/get_project_manager.dart';

class GetProjectManagerRepository {
  final ApiClient _apiClient = ApiClient();

  Future<GetProjectManagerResModel?> getProjectManager({
    required String projectId,
  }) async {
    try {
      // ✅ Prepare request body
      final requestBody = {
        "project_id": int.parse(projectId),
      };

      print("========== PROJECT MANAGER API ==========");
      print("📤 Sending Body: ${jsonEncode(requestBody)}");

      // ✅ API CALL
      final response = await _apiClient.post(
        Endpoint.getProjectManagerName,
        body: requestBody,
        requiresAuth: true,
      );

      print("📥 Status Code: ${response.statusCode}");
      print("📦 Raw Response: ${response.body}");

      // ✅ STATUS CHECK
      if (response.statusCode != 200) {
        print("❌ API FAILED: ${response.statusCode}");
        return null;
      }

      // ✅ EMPTY CHECK
      if (response.body.isEmpty) {
        print("⚠️ Empty response body");
        return null;
      }

      // ✅ SAFE JSON PARSE
      final decoded = jsonDecode(response.body);

      if (decoded == null) {
        print("⚠️ Decoded response is null");
        return null;
      }

      if (decoded is! Map<String, dynamic>) {
        print("⚠️ Invalid JSON format (not a Map)");
        return null;
      }

      // ✅ MODEL PARSE
      final model = GetProjectManagerResModel.fromJson(decoded);

      print("👤 Parsed PM Name: ${model.projectManagerData?.name}");

      return model;

    } catch (e, stackTrace) {
      print("❌ Error in getProjectManager: $e");
      print("📍 StackTrace: $stackTrace");
      return null;
    }
  }
}