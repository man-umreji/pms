class GetActionPointViewReqModel {
  final int meetingId;

  GetActionPointViewReqModel({
    required this.meetingId,
  });

  Map<String, dynamic> toJson() {
    return {
      "meeting_id": meetingId,
    };
  }
}

class GetActionViewResModel {
  bool? success;
  Data? data;

  GetActionViewResModel({this.success, this.data});

  GetActionViewResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  Meeting? meeting;
  List<Details>? details;
  List<Attachments>? attachments;
  List<Projects>? projects;
  List<Remark>? remarks;  // ✅ ADDED: Remark history
  int? currentUserId;

  Data({
    this.meeting,
    this.details,
    this.attachments,
    this.projects,
    this.remarks,  // ✅ ADDED
    this.currentUserId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    meeting = json['meeting'] != null ? Meeting.fromJson(json['meeting']) : null;

    if (json['details'] != null) {
      details = <Details>[];
      json['details'].forEach((v) {
        details!.add(Details.fromJson(v));
      });
    }

    if (json['attachments'] != null) {
      attachments = <Attachments>[];
      json['attachments'].forEach((v) {
        attachments!.add(Attachments.fromJson(v));
      });
    }

    if (json['projects'] != null) {
      projects = <Projects>[];
      json['projects'].forEach((v) {
        projects!.add(Projects.fromJson(v));
      });
    }

    // ✅ ADDED: Parse remarks
    if (json['remarks'] != null) {
      remarks = <Remark>[];
      json['remarks'].forEach((v) {
        remarks!.add(Remark.fromJson(v));
      });
    }

    currentUserId = json['current_user_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (meeting != null) {
      data['meeting'] = meeting!.toJson();
    }

    if (details != null) {
      data['details'] = details!.map((v) => v.toJson()).toList();
    }

    if (attachments != null) {
      data['attachments'] = attachments!.map((v) => v.toJson()).toList();
    }

    if (projects != null) {
      data['projects'] = projects!.map((v) => v.toJson()).toList();
    }

    // ✅ ADDED: Convert remarks to JSON
    if (remarks != null) {
      data['remarks'] = remarks!.map((v) => v.toJson()).toList();
    }

    data['current_user_id'] = currentUserId;

    return data;
  }
}

class Meeting {
  String? id;
  dynamic projectId;
  String? meetingTypeId;
  String? meetingDate;
  String? createdBy;
  String? createdOn;
  dynamic updatedOn;
  String? isActive;
  dynamic projectName;
  dynamic projectManager;
  String? createdByName;
  String? meetingType;
  String? meetingCode;

  Meeting({
    this.id,
    this.projectId,
    this.meetingTypeId,
    this.meetingDate,
    this.createdBy,
    this.createdOn,
    this.updatedOn,
    this.isActive,
    this.projectName,
    this.projectManager,
    this.createdByName,
    this.meetingType,
    this.meetingCode,
  });

  Meeting.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    projectId = json['project_id'];
    meetingTypeId = json['meeting_type_id'];
    meetingDate = json['meeting_date'];
    createdBy = json['created_by'];
    createdOn = json['created_on'];
    updatedOn = json['updated_on'];
    isActive = json['is_active'];
    projectName = json['project_name'];
    projectManager = json['project_manager'];
    createdByName = json['created_by_name'];
    meetingType = json['meeting_type'];
    meetingCode = json['meeting_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['project_id'] = projectId;
    data['meeting_type_id'] = meetingTypeId;
    data['meeting_date'] = meetingDate;
    data['created_by'] = createdBy;
    data['created_on'] = createdOn;
    data['updated_on'] = updatedOn;
    data['is_active'] = isActive;
    data['project_name'] = projectName;
    data['project_manager'] = projectManager;
    data['created_by_name'] = createdByName;
    data['meeting_type'] = meetingType;
    data['meeting_code'] = meetingCode;
    return data;
  }
}

class Details {
  String? id;
  String? actionPointId;
  String? description;
  dynamic subProjectId;
  String? assignedTo;
  String? status;
  String? targetDate;
  String? createdBy;
  String? createdOn;
  String? updatedOn;
  dynamic subProjectName;
  String? assignedEmployeeName;

  Details({
    this.id,
    this.actionPointId,
    this.description,
    this.subProjectId,
    this.assignedTo,
    this.status,
    this.targetDate,
    this.createdBy,
    this.createdOn,
    this.updatedOn,
    this.subProjectName,
    this.assignedEmployeeName,
  });

  Details.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    actionPointId = json['action_point_id'];
    description = json['description'];
    subProjectId = json['sub_project_id'];
    assignedTo = json['assigned_to'];
    status = json['status'];
    targetDate = json['target_date'];
    createdBy = json['created_by'];
    createdOn = json['created_on'];
    updatedOn = json['updated_on'];
    subProjectName = json['sub_project_name'];
    assignedEmployeeName = json['assigned_employee_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['action_point_id'] = actionPointId;
    data['description'] = description;
    data['sub_project_id'] = subProjectId;
    data['assigned_to'] = assignedTo;
    data['status'] = status;
    data['target_date'] = targetDate;
    data['created_by'] = createdBy;
    data['created_on'] = createdOn;
    data['updated_on'] = updatedOn;
    data['sub_project_name'] = subProjectName;
    data['assigned_employee_name'] = assignedEmployeeName;
    return data;
  }
}

class Attachments {
  String? id;
  String? actionPointId;
  String? fileName;
  String? filePath;
  String? uploadedBy;
  String? uploadedOn;
  String? uploadedByName;

  Attachments({
    this.id,
    this.actionPointId,
    this.fileName,
    this.filePath,
    this.uploadedBy,
    this.uploadedOn,
    this.uploadedByName,
  });

  Attachments.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    actionPointId = json['action_point_id'];
    fileName = json['file_name'];
    filePath = json['file_path'];
    uploadedBy = json['uploaded_by'];
    uploadedOn = json['uploaded_on'];
    uploadedByName = json['uploaded_by_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['action_point_id'] = actionPointId;
    data['file_name'] = fileName;
    data['file_path'] = filePath;
    data['uploaded_by'] = uploadedBy;
    data['uploaded_on'] = uploadedOn;
    data['uploaded_by_name'] = uploadedByName;
    return data;
  }
}

class Projects {
  String? id;
  String? projectCode;
  String? name;
  String? projectHeadId;
  String? verticalId;
  String? portfolioId;

  Projects({
    this.id,
    this.projectCode,
    this.name,
    this.projectHeadId,
    this.verticalId,
    this.portfolioId,
  });

  Projects.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    projectCode = json['project_code'];
    name = json['name'];
    projectHeadId = json['project_head_id'];
    verticalId = json['vertical_id'];
    portfolioId = json['portfolio_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['project_code'] = projectCode;
    data['name'] = name;
    data['project_head_id'] = projectHeadId;
    data['vertical_id'] = verticalId;
    data['portfolio_id'] = portfolioId;
    return data;
  }
}

// ✅ NEW CLASS: Remark model for history
class Remark {
  String? id;
  String? remark;
  String? createdBy;
  String? createdOn;
  String? createdByName;

  Remark({
    this.id,
    this.remark,
    this.createdBy,
    this.createdOn,
    this.createdByName,
  });

  Remark.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    remark = json['remark'];
    createdBy = json['created_by'];
    createdOn = json['created_on'];

    // ✅ FIX: handle multiple possible keys from API
    createdByName =
        json['created_by_name'] ??
            json['user_name'] ??
            json['userName'] ??
            '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['remark'] = remark;
    data['created_by'] = createdBy;
    data['created_on'] = createdOn;

    // Keep original key (API usually expects this)
    data['created_by_name'] = createdByName;

    return data;
  }
}