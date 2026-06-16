import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../service/api_client.dart';
import '../../../network/end_point.dart';
import '../model/generate_action_point_ai_model.dart';

class GenerateActionPointAiRepository {
  final ApiClient _apiClient = ApiClient();

  /// 🔥 GENERATE AI ACTION POINTS
  Future<GenerateActionPointAiResModel> generateActionPoints(
      GenerateActionPointAiReqModel model,
      ) async {
    try {
      final response = await _apiClient.post(
        Endpoint.generateActionPointAi,
        body: jsonEncode(model.toJson()),
        requiresAuth: true,
      );

      print("========== GENERATE AI REQUEST ==========");
      print("URL: ${Endpoint.generateActionPointAi}");
      print("Body: ${model.toJson()}");
      print("=========================================");

      print("========== GENERATE AI RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("==========================================");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return GenerateActionPointAiResModel.fromJson(data);
      } else {
        return GenerateActionPointAiResModel(
          success: false,
          actionPoints: [],
        );
      }
    } catch (e) {
      print("❌ AI GENERATE ERROR: $e");

      return GenerateActionPointAiResModel(
        success: false,
        actionPoints: [],
      );
    }
  }

  /// ✅ OPTIONAL: GET ONLY LIST
  Future<List<ActionPoints>> getActionPointsList(
      GenerateActionPointAiReqModel model,
      ) async {
    final res = await generateActionPoints(model);

    if (res.success == true && res.actionPoints != null) {
      return res.actionPoints!;
    }

    return [];
  }
}