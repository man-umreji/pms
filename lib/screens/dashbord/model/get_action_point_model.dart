class GetActionPointReqModel {
  String? status;
  String? meetingTypeId;

  GetActionPointReqModel({
    this.status,
    this.meetingTypeId,
  });

  Map<String, dynamic> toJson() => {
    "status": status,
    "meeting_type_id": meetingTypeId,

  };
}

class GetActionPointResModel {
  bool? success;
  List<ActionPoint>? actionPoint;
  Filter? filter;

  GetActionPointResModel({this.success, this.actionPoint, this.filter});

  GetActionPointResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['action_point'] != null) {
      actionPoint = <ActionPoint>[];
      json['action_point'].forEach((v) {
        actionPoint!.add(new ActionPoint.fromJson(v));
      });
    }
    filter =
    json['filter'] != null ? new Filter.fromJson(json['filter']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.actionPoint != null) {
      data['action_point'] = this.actionPoint!.map((v) => v.toJson()).toList();
    }
    if (this.filter != null) {
      data['filter'] = this.filter!.toJson();
    }
    return data;
  }
}

class ActionPoint {
  String? id;
  String? projectId;
  String? meetingTypeId;
  String? meetingDate;
  String? createdBy;
  String? createdOn;
  String? updatedOn;
  String? isActive;
  String? meetingTypeName;
  String? projectCode;
  String? projectName;
  String? projectManager;
  String? createdByName;
  String? totalPoints;
  String? pendingPoints;
  String? inprogressPoints;
  String? completedPoints;
  String? overallStatus;

  ActionPoint(
      {this.id,
        this.projectId,
        this.meetingTypeId,
        this.meetingDate,
        this.createdBy,
        this.createdOn,
        this.updatedOn,
        this.isActive,
        this.meetingTypeName,
        this.projectCode,
        this.projectName,
        this.projectManager,
        this.createdByName,
        this.totalPoints,
        this.pendingPoints,
        this.inprogressPoints,
        this.completedPoints,
        this.overallStatus});

  ActionPoint.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    projectId = json['project_id'];
    meetingTypeId = json['meeting_type_id'];
    meetingDate = json['meeting_date'];
    createdBy = json['created_by'];
    createdOn = json['created_on'];
    updatedOn = json['updated_on'];
    isActive = json['is_active'];
    meetingTypeName = json['meeting_type_name'];
    projectCode = json['project_code'];
    projectName = json['project_name'];
    projectManager = json['project_manager'];
    createdByName = json['created_by_name'];
    totalPoints = json['total_points'];
    pendingPoints = json['pending_points'];
    inprogressPoints = json['inprogress_points'];
    completedPoints = json['completed_points'];
    overallStatus = json['overall_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['project_id'] = this.projectId;
    data['meeting_type_id'] = this.meetingTypeId;
    data['meeting_date'] = this.meetingDate;
    data['created_by'] = this.createdBy;
    data['created_on'] = this.createdOn;
    data['updated_on'] = this.updatedOn;
    data['is_active'] = this.isActive;
    data['meeting_type_name'] = this.meetingTypeName;
    data['project_code'] = this.projectCode;
    data['project_name'] = this.projectName;
    data['project_manager'] = this.projectManager;
    data['created_by_name'] = this.createdByName;
    data['total_points'] = this.totalPoints;
    data['pending_points'] = this.pendingPoints;
    data['inprogress_points'] = this.inprogressPoints;
    data['completed_points'] = this.completedPoints;
    data['overall_status'] = this.overallStatus;
    return data;
  }
}

class Filter {
  String? meetingTypeId;
  String? status;

  Filter({this.meetingTypeId, this.status});

  Filter.fromJson(Map<String, dynamic> json) {
    meetingTypeId = json['meeting_type_id'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['meeting_type_id'] = this.meetingTypeId;
    data['status'] = this.status;
    return data;
  }
}