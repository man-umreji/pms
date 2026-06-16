class GetUserListResModel {
  bool? status;
  List<UserListData>? userListData;

  GetUserListResModel({this.status, this.userListData});

  GetUserListResModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      userListData = <UserListData>[];
      json['data'].forEach((v) {
        userListData!.add(new UserListData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.userListData != null) {
      data['data'] = this.userListData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class UserListData {
  String? id;
  String? name;
  String? email;

  UserListData({this.id, this.name, this.email});

  UserListData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['email'] = this.email;
    return data;
  }
}