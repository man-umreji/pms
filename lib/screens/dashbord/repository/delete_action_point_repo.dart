import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../network/end_point.dart';
import '../../../service/auth_service.dart';
import '../model/delete_action_point_model.dart';

class DeleteActionPointRepository {
  Future<DeleteActionPointResModel> deleteActionPoint(
      DeleteActionPointReqModel model) async {
    try {
      final token = await AuthService().getValidToken();

      print("🗑 DELETE REQUEST BODY: ${model.toJson()}");
      print("🔑 TOKEN: $token");

      final response = await http.post(
        Uri.parse(Endpoint.deleteActionPoint),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(model.toJson()),
      );

      print("🗑 DELETE STATUS: ${response.statusCode}");
      print("🗑 DELETE RESPONSE: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return DeleteActionPointResModel.fromJson(data);
      } else {
        return DeleteActionPointResModel(
          success: false,
          message: data['message'] ?? 'Delete failed',
        );
      }
    } catch (e) {
      print("❌ DELETE ERROR: $e");
      return DeleteActionPointResModel(
        success: false,
        message: e.toString(),
      );
    }
  }
}