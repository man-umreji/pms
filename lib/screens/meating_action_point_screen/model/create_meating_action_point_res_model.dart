import 'package:http/http.dart';

class CreateMeatingActionReqModel {
  String? meatingDate;
  String? projectId;
  String? meatingTypeId;
  List<MultipartFile>? attachments;

  CreateMeatingActionReqModel({
    this.meatingDate,
    this.projectId,
    this.meatingTypeId,
    this.attachments,
  });

  Map<String, String> toJson() => {
    "meeting_type_id": meatingTypeId ?? "",
    "project_id": projectId ?? "",
    "meeting_date": meatingDate ?? "",
  };
}


class CreateMeatingActionResModel {
  bool? status;
  String? message;
  int? actionPointId;

  CreateMeatingActionResModel({this.status, this.message, this.actionPointId});

  CreateMeatingActionResModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    actionPointId = json['action_point_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['action_point_id'] = this.actionPointId;
    return data;
  }
}