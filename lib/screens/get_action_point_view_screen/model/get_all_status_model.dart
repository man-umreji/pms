class GetAllStatusResModel {
  bool? success;
  List<StatusList>? statusList;

  GetAllStatusResModel({this.success, this.statusList});

  GetAllStatusResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['status_list'] != null) {
      statusList = <StatusList>[];
      json['status_list'].forEach((v) {
        statusList!.add(new StatusList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.statusList != null) {
      data['status_list'] = this.statusList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class StatusList {
  String? value;
  String? label;

  StatusList({this.value, this.label});

  StatusList.fromJson(Map<String, dynamic> json) {
    value = json['value'];
    label = json['label'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['value'] = this.value;
    data['label'] = this.label;
    return data;
  }
}