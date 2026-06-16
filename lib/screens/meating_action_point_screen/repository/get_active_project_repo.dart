import 'dart:convert';
import '../../../network/end_point.dart';
import '../../../service/api_client.dart';
import '../model/get_active_project_model.dart';

class ProjectRepository {

  final ApiClient _apiClient = ApiClient();

  Future<GetActiveProjectApiResModel?> getActiveProjects() async {
    try {
      final response = await _apiClient.get(
        Endpoint.getActiveProject,
        requiresAuth: true,
      );

      print("========== GET ACTIVE PROJECTS ==========");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return GetActiveProjectApiResModel.fromJson(decoded);
      } else {
        throw Exception("Failed: ${response.statusCode}");
      }

    } catch (e) {
      print("❌ Error in getActiveProjects: $e");
      return null;
    }
  }
}