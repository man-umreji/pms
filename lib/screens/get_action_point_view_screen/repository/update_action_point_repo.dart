import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../service/api_client.dart';
import '../../../network/end_point.dart';
import '../model/update_action_point_model.dart';

class UpdateActionPointRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UpdateGetActionViewResModel> updateActionPoint(
      UpdateGetActionViewReqModel model,
      ) async {
    try {
      /// ✅ Prepare multipart files
      List<http.MultipartFile> files = [];

      for (String path in model.attachments) {
        if (path.isNotEmpty) {
          final file = File(path);
          if (await file.exists()) {
            files.add(
              await http.MultipartFile.fromPath(
                'attachments[]',
                path,
              ),
            );
          } else {
            print("⚠️ File not found: $path");
          }
        }
      }

      /// ✅ Prepare body with multiple action points support
      final Map<String, dynamic> body = {};

      // Add meeting details
      body["meeting_id"] = model.meetingId?.toString() ?? "";
      body["remark"] = model.remark ?? "";
      body["meeting_date"] = model.meetingDate ?? "";

      // Add action points dynamically (support multiple)
      for (int i = 0; i < model.actionPoints.length; i++) {
        final ap = model.actionPoints[i];

        // Add ID only if it exists (for updates)
        if (ap.id != null && ap.id!.isNotEmpty) {
          body["action_points[$i][id]"] = ap.id;
        }

        // Add required fields
        body["action_points[$i][description]"] = ap.description ?? "";
        body["action_points[$i][target_date]"] = ap.targetDate ?? "";
        body["action_points[$i][assigned_to]"] = ap.assignedTo ?? "";

        // Add status if provided
        if (ap.status != null && ap.status!.isNotEmpty) {
          body["action_points[$i][status]"] = ap.status;
        }
      }

      // Add attachments if any
      if (files.isNotEmpty) {
        body["attachments[]"] = files;
      }

      final response = await _apiClient.post(
        Endpoint.updateActionPointView,
        body: body,
        requiresAuth: true,
        isFormData: true, // 🔥 VERY IMPORTANT for file uploads
      );

      print("========== UPDATE ACTION POINT REQUEST ==========");
      print("URL: ${Endpoint.updateActionPointView}");
      print("Meeting ID: ${model.meetingId}");
      print("Remark: ${model.remark}");
      print("Meeting Date: ${model.meetingDate}");
      print("Action Points Count: ${model.actionPoints.length}");
      for (int i = 0; i < model.actionPoints.length; i++) {
        final ap = model.actionPoints[i];
        print("Action Point $i:");
        print("  - ID: ${ap.id ?? 'NEW'}");
        print("  - Description: ${ap.description}");
        print("  - Target Date: ${ap.targetDate}");
        print("  - Assigned To: ${ap.assignedTo}");
        print("  - Status: ${ap.status ?? 'NOT SET'}");
      }
      print("Attachments Count: ${files.length}");
      print("=================================================");

      print("========== RESPONSE ==========");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("================================");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return UpdateGetActionViewResModel.fromJson(data);
      } else {
        return UpdateGetActionViewResModel(
          status: false,
          message: data['message'] ?? "Update failed",
        );
      }
    } catch (e) {
      print("❌ UPDATE ACTION POINT ERROR: $e");
      print("Stack trace: ${StackTrace.current}");

      return UpdateGetActionViewResModel(
        status: false,
        message: e.toString(),
      );
    }
  }

  /// ✅ Helper method for single action point update (backward compatibility)
  Future<UpdateGetActionViewResModel> updateSingleActionPoint({
    required int meetingId,
    required String remark,
    required String meetingDate,
    required String actionPointId,
    required String description,
    required String targetDate,
    required String assignedTo,
    String? status,
    List<String> attachments = const [],
  }) async {
    final model = UpdateGetActionViewReqModel(
      meetingId: meetingId,
      remark: remark,
      meetingDate: meetingDate,
      actionPoints: [
        ActionPointItem(
          id: actionPointId,
          description: description,
          targetDate: targetDate,
          assignedTo: assignedTo,
          status: status,
        ),
      ],
      attachments: attachments,
    );

    return await updateActionPoint(model);
  }

  /// ✅ Helper method for creating new action point
  Future<UpdateGetActionViewResModel> createActionPoint({
    required int meetingId,
    required String remark,
    required String meetingDate,
    required String description,
    required String targetDate,
    required String assignedTo,
    List<String> attachments = const [],
  }) async {
    final model = UpdateGetActionViewReqModel(
      meetingId: meetingId,
      remark: remark,
      meetingDate: meetingDate,
      actionPoints: [
        ActionPointItem(
          id: null, // No ID for new action point
          description: description,
          targetDate: targetDate,
          assignedTo: assignedTo,
        ),
      ],
      attachments: attachments,
    );

    return await updateActionPoint(model);
  }

  /// ✅ Helper method for bulk update (multiple action points)
  Future<UpdateGetActionViewResModel> bulkUpdateActionPoints({
    required int meetingId,
    required String remark,
    required String meetingDate,
    required List<ActionPointItem> actionPoints,
    List<String> attachments = const [],
  }) async {
    final model = UpdateGetActionViewReqModel(
      meetingId: meetingId,
      remark: remark,
      meetingDate: meetingDate,
      actionPoints: actionPoints,
      attachments: attachments,
    );

    return await updateActionPoint(model);
  }

  /// ✅ Helper method for updating only status
  Future<UpdateGetActionViewResModel> updateActionPointStatus({
    required int meetingId,
    required String remark,
    required String meetingDate,
    required String actionPointId,
    required String status,
    String? description,
    String? targetDate,
    String? assignedTo,
  }) async {
    // If description, targetDate, or assignedTo are not provided,
    // we need to fetch existing data. This should be handled by the ViewModel.
    final model = UpdateGetActionViewReqModel(
      meetingId: meetingId,
      remark: remark,
      meetingDate: meetingDate,
      actionPoints: [
        ActionPointItem(
          id: actionPointId,
          description: description, // Should be provided by ViewModel
          targetDate: targetDate,   // Should be provided by ViewModel
          assignedTo: assignedTo,   // Should be provided by ViewModel
          status: status,
        ),
      ],
      attachments: [],
    );

    return await updateActionPoint(model);
  }
}