class SelectEmployeeReqModel {
  String? meatingTypeId;
  String? projectId;


  SelectEmployeeReqModel({
    this.meatingTypeId,
    this.projectId

  });

  Map<String, dynamic> toJson() => {
    "meeting_type_id": meatingTypeId,
    "project_id": projectId,

  };
}
class SelectEmployeeResModel {
  bool? status;
  String? message;
  List<Data>? data;

  SelectEmployeeResModel({this.status, this.message, this.data});

  SelectEmployeeResModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? id;
  String? employeeName;

  Data({this.id, this.employeeName});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    employeeName = json['employee_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['employee_name'] = this.employeeName;
    return data;
  }
}