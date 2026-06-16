class ActionPointSummaryPointsReqModel {
  String? status;
  String? meetingTypeId;

  ActionPointSummaryPointsReqModel({
    this.status,
    this.meetingTypeId,
  });

  Map<String, dynamic> toJson() => {
    "status": status,
    "meeting_type_id": meetingTypeId,

  };
}


class ActionPointSummaryPointsResModel {
  bool? success;
  ActionSummary? actionSummary;

  ActionPointSummaryPointsResModel({this.success, this.actionSummary});

  ActionPointSummaryPointsResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    actionSummary = json['action_summary'] != null
        ? new ActionSummary.fromJson(json['action_summary'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.actionSummary != null) {
      data['action_summary'] = this.actionSummary!.toJson();
    }
    return data;
  }
}

class ActionSummary {
  int? total;
  int? pending;
  int? inprogress;
  int? completed;

  ActionSummary({this.total, this.pending, this.inprogress, this.completed});

  ActionSummary.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    pending = json['pending'];
    inprogress = json['inprogress'];
    completed = json['completed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total'] = this.total;
    data['pending'] = this.pending;
    data['inprogress'] = this.inprogress;
    data['completed'] = this.completed;
    return data;
  }
}