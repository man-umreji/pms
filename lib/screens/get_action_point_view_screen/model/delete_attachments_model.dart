class DeleteAttachmentsReqModel {
  final int meetingId;
  final int attachmentId;

  DeleteAttachmentsReqModel({
    required this.meetingId,
    required this.attachmentId,
  });

  Map<String, dynamic> toJson() {
    return {
      "meeting_id": meetingId,
      "attachment_id": attachmentId,
    };
  }
}

class DeleteAttachmentsResModel {
  bool? success;
  String? message;

  DeleteAttachmentsResModel({this.success, this.message});

  DeleteAttachmentsResModel.fromJson(Map<String, dynamic> json) {
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