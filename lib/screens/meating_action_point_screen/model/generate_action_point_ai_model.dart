class GenerateActionPointAiReqModel {
  String? meatingNotes;
  String? meatingDate;
  String? projectId;
  String? meatingTypeId;

  GenerateActionPointAiReqModel({
    this.meatingNotes,
    this.meatingDate,
    this.projectId,
    this.meatingTypeId,
  });

  Map<String, dynamic> toJson() => {
    "meeting_notes": meatingNotes,
    "meeting_date": meatingDate,
    "project_id": projectId,
    "meeting_type_id": meatingTypeId,
  };
}

class GenerateActionPointAiResModel {
  bool? success;
  String? source;
  List<ActionPoints>? actionPoints;
  String? meetingTypeCode;
  String? projectHint;
  String? meetingDate;

  GenerateActionPointAiResModel({
    this.success,
    this.source,
    this.actionPoints,
    this.meetingTypeCode,
    this.projectHint,
    this.meetingDate,
  });

  GenerateActionPointAiResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    source = json['source'];
    if (json['action_points'] != null) {
      actionPoints = <ActionPoints>[];
      json['action_points'].forEach((v) {
        actionPoints!.add(ActionPoints.fromJson(v));
      });
    }
    meetingTypeCode = json['meeting_type_code'];
    projectHint = json['project_hint'];
    meetingDate = json['meeting_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['source'] = source;
    if (actionPoints != null) {
      data['action_points'] = actionPoints!.map((v) => v.toJson()).toList();
    }
    data['meeting_type_code'] = meetingTypeCode;
    data['project_hint'] = projectHint;
    data['meeting_date'] = meetingDate;
    return data;
  }
}

class ActionPoints {
  String? description;
  String? targetDate;
  String? assigneeName;
  /// Set in-app when user picks an employee; sent as [assigned_to] when saving.
  String? assignedToId;
  /// Indicates if this action point was added manually by the user (true) or AI-generated (false)
  bool? isManual;

  ActionPoints({
    this.description,
    this.targetDate,
    this.assigneeName,
    this.assignedToId,
    this.isManual = false, // Default to false (AI-generated)
  });

  ActionPoints.fromJson(Map<String, dynamic> json) {
    description = json['description'];
    targetDate = json['target_date'];
    assigneeName = json['assignee_name'];
    // isManual is not coming from API, default to false
    isManual = json['is_manual'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['description'] = description;
    data['target_date'] = targetDate;
    data['assignee_name'] = assigneeName;
    // Only include assigned_to_id if it exists (for create API)
    if (assignedToId != null && assignedToId!.isNotEmpty) {
      data['assigned_to_id'] = assignedToId;
    }
    // isManual is for UI state only, not sent to API
    // data['is_manual'] = isManual; // Don't send to API
    return data;
  }

  /// Creates a copy of this ActionPoints with updated values
  ActionPoints copyWith({
    String? description,
    String? targetDate,
    String? assigneeName,
    String? assignedToId,
    bool? isManual,
  }) {
    return ActionPoints(
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      assigneeName: assigneeName ?? this.assigneeName,
      assignedToId: assignedToId ?? this.assignedToId,
      isManual: isManual ?? this.isManual,
    );
  }
}