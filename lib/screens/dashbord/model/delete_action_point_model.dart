class DeleteActionPointReqModel {
  String? meetingId;

  DeleteActionPointReqModel({
    this.meetingId,
  });

  Map<String, dynamic> toJson() => {
    "meeting_id": meetingId,

  };
}

class DeleteActionPointResModel {
  bool? success;
  String? message;

  DeleteActionPointResModel({this.success, this.message});

  DeleteActionPointResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    return data;
  }
}