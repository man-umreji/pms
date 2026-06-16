import 'dart:convert';
import '../../../service/api_client.dart';
import '../../../network/end_point.dart';
import '../model/delete_attachments_model.dart';

class DeleteAttachmentsRepository {
  final ApiClient _apiClient = ApiClient();

  /// 🔥 DELETE ATTACHMENT
  Future<DeleteAttachmentsResModel> deleteAttachment(
      DeleteAttachmentsReqModel model,
      ) async {
    try {
      final response = await _apiClient.post(
        Endpoint.deleteAttachments,
        body: jsonEncode(model.toJson()),
        requiresAuth: true,
      );

      print("========== DELETE ATTACHMENT REQUEST ==========");
      print("URL: ${Endpoint.deleteAttachments}");
      print("Body: ${model.toJson()}");
      print("===============================================");

      print("========== DELETE ATTACHMENT RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("===============================================");

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return DeleteAttachmentsResModel.fromJson(data);
      } else {
        return DeleteAttachmentsResModel(
          success: false,
          message: data['message'] ?? "Failed to delete attachment",
        );
      }
    } catch (e) {
      print("❌ DELETE ATTACHMENT ERROR: $e");

      return DeleteAttachmentsResModel(
        success: false,
        message: "Something went wrong: $e",
      );
    }
  }
}