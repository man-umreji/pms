import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../service/api_client.dart';
import '../../../network/end_point.dart';
import '../model/meating_action_point_model.dart';

class SelectEmployeeRepository {
  final ApiClient _apiClient = ApiClient();
  Future<SelectEmployeeResModel> getEmployees(
      SelectEmployeeReqModel model,
      ) async {
    try {
      final response = await _apiClient.post(
        Endpoint.getMeetingEmployees,
        body: jsonEncode(model.toJson()),
        requiresAuth: true,
      );

      print("========== GET EMPLOYEES ==========");
      print(Endpoint.getMeetingEmployees);
      print("Request: ${model.toJson()}");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("===================================");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SelectEmployeeResModel.fromJson(data);
      } else {
        return SelectEmployeeResModel(
          status: false,
          message: data['message'] ?? "Failed",
          data: [],
        );
      }
    } catch (e) {
      print("❌ SELECT EMPLOYEE ERROR: $e");

      return SelectEmployeeResModel(
        status: false,
        message: "Network error",
        data: [],
      );
    }
  }

  /// ✅ OPTIONAL: return only employee list
  Future<List<Data>> getEmployeeList(
      SelectEmployeeReqModel model,
      ) async {
    final res = await getEmployees(model);

    if (res.status == true && res.data != null) {
      return res.data!;
    }

    return [];
  }
}