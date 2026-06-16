import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../network/end_point.dart';
import '../../../service/api_client.dart';
import '../../../service/auth_service.dart';
import '../model/create_meating_action_point_res_model.dart';
import '../model/get_user_list_model.dart';


class CreateMeetingActionRepository {
  final ApiClient _apiClient = ApiClient();

  /// 🔥 CREATE ACTION POINT
  /// Server expects **form fields** (same as Postman form-data), not a JSON body.
  /// Optional [attachmentPaths]: files sent as multipart `attachments[]` (same as update flow).
  Future<CreateMeatingActionResModel> createActionPoint(
      Map<String, dynamic> body, {
        List<String> attachmentPaths = const [],
        required List<UserListData> selectedUsers,
      }) async {
    try {
      final uri = Uri.parse(Endpoint.createActionPoint);

      final request = http.MultipartRequest("POST", uri);

      // ✅ USE EXISTING AUTH SYSTEM
      final token = await AuthService().getToken();

      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      // ✅ NORMAL FIELDS
      body.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // 🔥 MULTI CC MAIL (CORRECT WAY)
      for (var user in selectedUsers) {
        if (user.email != null && user.email!.isNotEmpty) {
          request.files.add(
            http.MultipartFile.fromString("cc_mailid[]", user.email!),
          );
        }
      }

      // ✅ ATTACHMENTS
      for (final path in attachmentPaths) {
        if (path.isEmpty) continue;

        final file = File(path);
        if (await file.exists()) {
          final sizeInMB = await file.length() / (1024 * 1024);

          if (sizeInMB > 3) {
            throw Exception("File must be less than 3MB");
          }

          request.files.add(
            await http.MultipartFile.fromPath("attachments[]", path),
          );
        }
      }

      // 🔍 DEBUG
      print("========= FINAL MULTIPART REQUEST =========");
      request.fields.forEach((k, v) => print("$k : $v"));
      print("Files: ${request.files.length}");

      // ✅ SEND
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("========= RESPONSE =========");
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return CreateMeatingActionResModel.fromJson(data);
      } else {
        return CreateMeatingActionResModel(
          status: false,
          message: data['message'] ?? "Failed",
        );
      }
    } catch (e) {
      print("❌ ERROR: $e");
      return CreateMeatingActionResModel(
        status: false,
        message: "Something went wrong: $e",
      );
    }
  }

  // Future<bool> createActionPointStatus(
  //     CreateMeatingActionReqModel model,
  //     ) async {
  //   final res = await createActionPoint(model);
  //   return res.status == true;
  // }
}