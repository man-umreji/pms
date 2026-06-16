class GetProjectManagerReqModel {
  String? projectId;


  GetProjectManagerReqModel({
    this.projectId

  });

  Map<String, dynamic> toJson() => {
    "project_id": projectId,


  };
}

class GetProjectManagerResModel {
  bool? status;
  ProjectManagerData? projectManagerData;

  GetProjectManagerResModel({this.status, this.projectManagerData});

  GetProjectManagerResModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    projectManagerData = json['data'] != null ? new ProjectManagerData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.projectManagerData != null) {
      data['data'] = this.projectManagerData!.toJson();
    }
    return data;
  }
}

class ProjectManagerData {
  String? name;
  String? email;

  ProjectManagerData({this.name, this.email});

  ProjectManagerData.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    return data;
  }
}