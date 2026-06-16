class UpdateGetActionViewReqModel {
  int? meetingId;
  String? remark;
  String? meetingDate;

  /// List of action points (supports multiple)
  List<ActionPointItem> actionPoints;

  /// attachments
  List<String> attachments;

  UpdateGetActionViewReqModel({
    this.meetingId,
    this.remark,
    this.meetingDate,
    required this.actionPoints,
    required this.attachments,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};

    data["meeting_id"] = meetingId;
    data["remark"] = remark;
    data["meeting_date"] = meetingDate;

    // Add action points dynamically
    for (int i = 0; i < actionPoints.length; i++) {
      final ap = actionPoints[i];
      if (ap.id != null) {
        data["action_points[$i][id]"] = ap.id;
      }
      data["action_points[$i][description]"] = ap.description;
      data["action_points[$i][target_date]"] = ap.targetDate;
      data["action_points[$i][assigned_to]"] = ap.assignedTo;
    }

    // Add attachments
    if (attachments.isNotEmpty) {
      data["attachments[]"] = attachments;
    }

    return data;
  }
}

class ActionPointItem {
  String? id; // Optional: only for updates, null for new action points
  String? description;
  String? targetDate;
  String? assignedTo;
  String? status; // Optional: for status updates

  ActionPointItem({
    this.id,
    this.description,
    this.targetDate,
    this.assignedTo,
    this.status,
  });
}

class UpdateGetActionViewResModel {
  bool? status;
  String? message;

  UpdateGetActionViewResModel({this.status, this.message});

  UpdateGetActionViewResModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    return data;
  }
}