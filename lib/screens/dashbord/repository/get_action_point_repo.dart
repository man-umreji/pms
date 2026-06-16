import 'dart:convert';
import '../../../service/api_client.dart';
import '../../../network/end_point.dart';
import '../model/get_action_point_model.dart';

class GetActionPointRepository {
  final ApiClient _apiClient = ApiClient();

  Future<GetActionPointResModel> getActionPoints(
      GetActionPointReqModel model) async {
    try {
      final response = await _apiClient.post(
        Endpoint.getActionPoint,
        body: jsonEncode(model.toJson()),
        requiresAuth: true,
      );

      print("========== GET ACTION POINT ==========");
      print("Body: ${model.toJson()}");
      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");
      print("======================================");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return GetActionPointResModel.fromJson(data);
      } else {
        return GetActionPointResModel(success: false, actionPoint: []);
      }
    } catch (e) {
      print("❌ ERROR: $e");

      return GetActionPointResModel(success: false, actionPoint: []);
    }
  }
}