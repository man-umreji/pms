import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../service/api_client.dart';
import '../../../network/end_point.dart';
import '../model/meating_model.dart';

class GetMeetingTypeRepository {
  final ApiClient _apiClient = ApiClient();

  /// ✅ MAIN METHOD
  Future<GetMeatingTypeResModel> getMeetingTypes() async {
    try {
      final response = await _apiClient.get(
        Endpoint.getMeeting,
        requiresAuth: true, // 🔥 IMPORTANT (fixes 401)
      );

      print("========== GET MEETING TYPES ==========");
      print("URL: ${Endpoint.getMeeting}");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("=======================================");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return GetMeatingTypeResModel.fromJson(data);
      } else {
        return GetMeatingTypeResModel(
          success: false,
          meetingType: [],
        );
      }
    } catch (e) {
      print("❌ GET MEETING ERROR: $e");

      return GetMeatingTypeResModel(
        success: false,
        meetingType: [],
      );
    }
  }

  /// ✅ OPTIONAL: get only list
  Future<List<MeetingType>> getMeetingTypeList() async {
    final response = await getMeetingTypes();

    if (response.success == true && response.meetingType != null) {
      return response.meetingType!;
    }

    return [];
  }
}