import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../../service/api_client.dart';
import '../../../network/end_point.dart';
import '../model/get_action_point_model.dart';

class GetActionPointViewRepository {
  final ApiClient _apiClient = ApiClient();
  Future<GetActionViewResModel> getActionPointView(
      GetActionPointViewReqModel model,
      ) async {
    try {
      final response = await _apiClient.post(
        Endpoint.getActionPointView,
        body: jsonEncode(model.toJson()),
        requiresAuth: true,
      );
      // drop down ahno

      print("========== GET ACTION POINT VIEW REQUEST ==========");
      print("URL: ${Endpoint.getActionPointView}");
      print("Body: ${model.toJson()}");
      print("==================================================");

      print("========== GET ACTION POINT VIEW RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      log("Response: ${response.body}");
      print("===================================================");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return GetActionViewResModel.fromJson(data);
      } else {
        return GetActionViewResModel(
          success: false,
          data: null,
        );
      }
    } catch (e) {
      print("❌ GET ACTION POINT VIEW ERROR: $e");

      return GetActionViewResModel(
        success: false,
        data: null,
      );
    }
  }

  /// ✅ OPTIONAL: GET DETAILS LIST ONLY
  Future<List<Details>> getDetailsList(
      GetActionPointViewReqModel model,
      ) async {
    final res = await getActionPointView(model);

    if (res.success == true && res.data?.details != null) {
      return res.data!.details!;
    }

    return [];
  }

  /// ✅ OPTIONAL: GET ATTACHMENTS ONLY
  Future<List<Attachments>> getAttachments(
      GetActionPointViewReqModel model,
      ) async {
    final res = await getActionPointView(model);

    if (res.success == true && res.data?.attachments != null) {
      return res.data!.attachments!;
    }

    return [];
  }
}