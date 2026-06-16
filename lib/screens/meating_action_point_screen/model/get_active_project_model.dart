class GetActiveProjectApiResModel {
  bool? status;
  String? message;
  List<GetActiveProjectData>? getActiveProjectdata;

  GetActiveProjectApiResModel({this.status, this.message, this.getActiveProjectdata});

  GetActiveProjectApiResModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      getActiveProjectdata = <GetActiveProjectData>[];
      json['data'].forEach((v) {
        getActiveProjectdata!.add(new GetActiveProjectData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.getActiveProjectdata != null) {
      data['data'] = this.getActiveProjectdata!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GetActiveProjectData {
  String? id;
  String? projectCode;
  String? name;
  String? projectHeadId;
  String? verticalId;
  String? portfolioId;

  GetActiveProjectData(
      {this.id,
        this.projectCode,
        this.name,
        this.projectHeadId,
        this.verticalId,
        this.portfolioId});

  GetActiveProjectData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    projectCode = json['project_code'];
    name = json['name'];
    projectHeadId = json['project_head_id'];
    verticalId = json['vertical_id'];
    portfolioId = json['portfolio_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['project_code'] = this.projectCode;
    data['name'] = this.name;
    data['project_head_id'] = this.projectHeadId;
    data['vertical_id'] = this.verticalId;
    data['portfolio_id'] = this.portfolioId;
    return data;
  }
}