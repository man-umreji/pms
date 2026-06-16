import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../service/api_client.dart';
import '../../../network/end_point.dart';
import '../model/action_point_summary_point_model.dart';

class ActionPointSummaryRepository {
  final ApiClient _apiClient = ApiClient();

  /// 🔥 FETCH SUMMARY
  Future<ActionPointSummaryPointsResModel> getSummary(
      ActionPointSummaryPointsReqModel model,
      ) async {
    try {
      final response = await _apiClient.post(
        Endpoint.actionPointSummaryPoints, // ✅ only path
        body: jsonEncode(model.toJson()),
        requiresAuth: true,
      );

      print("========== SUMMARY REQUEST ==========");
      print("Body: ${model.toJson()}");
      print("=====================================");

      print("========== SUMMARY RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("======================================");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ActionPointSummaryPointsResModel.fromJson(data);
      } else {
        return ActionPointSummaryPointsResModel(
          success: false,
          actionSummary: null,
        );
      }
    } catch (e) {
      print("❌ SUMMARY ERROR: $e");

      return ActionPointSummaryPointsResModel(
        success: false,
        actionSummary: null,
      );
    }
  }

  /// ✅ OPTIONAL: DIRECT SUMMARY OBJECT
  Future<ActionSummary?> getSummaryData(
      ActionPointSummaryPointsReqModel model,
      ) async {
    final res = await getSummary(model);

    if (res.success == true && res.actionSummary != null) {
      return res.actionSummary;
    }

    return null;
  }
}