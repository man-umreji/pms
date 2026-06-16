import 'dart:convert';
import '../../../network/end_point.dart';
import '../../../service/api_client.dart';
import '../model/get_user_list_model.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient();

  Future<GetUserListResModel?> getUserList() async {
    try {
      final response = await _apiClient.get(
        Endpoint.getUserList,
        requiresAuth: true,
      );

      print("========== GET USER LIST ==========");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return GetUserListResModel.fromJson(decoded);
      } else {
        throw Exception("Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error in getUserList: $e");
      return null;
    }
  }
}