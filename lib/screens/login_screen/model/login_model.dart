class LoginReqModel {
  String? userName;
  String? password;

  LoginReqModel({
    this.userName,
    this.password,
  });

  Map<String, dynamic> toJson() => {
    "username": userName,
    "password": password,
  };
}


class LoginResModel {
  bool? success;
  String? token;
  int? isFirstLogin;
  User? user;
  Permissions? permissions;

  LoginResModel(
      {this.success,
        this.token,
        this.isFirstLogin,
        this.user,
        this.permissions});

  LoginResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    token = json['token'];
    isFirstLogin = json['is_first_login'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
    permissions = json['permissions'] != null
        ? new Permissions.fromJson(json['permissions'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['token'] = this.token;
    data['is_first_login'] = this.isFirstLogin;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    if (this.permissions != null) {
      data['permissions'] = this.permissions!.toJson();
    }
    return data;
  }
}

class User {
  int? id;
  String? username;
  String? name;
  String? email;
  String? mobile;
  String? role;
  bool? project;
  Null? district;

  User(
      {this.id,
        this.username,
        this.name,
        this.email,
        this.mobile,
        this.role,
        this.project,
        this.district});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    name = json['name'];
    email = json['email'];
    mobile = json['mobile'];
    role = json['role'];
    project = json['project'];
    district = json['district'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['username'] = this.username;
    data['name'] = this.name;
    data['email'] = this.email;
    data['mobile'] = this.mobile;
    data['role'] = this.role;
    data['project'] = this.project;
    data['district'] = this.district;
    return data;
  }
}

class Permissions {
  MeetingActionPoints? meetingActionPoints;

  Permissions({this.meetingActionPoints});

  Permissions.fromJson(Map<String, dynamic> json) {
    meetingActionPoints = json['meeting_action_points'] != null
        ? new MeetingActionPoints.fromJson(json['meeting_action_points'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.meetingActionPoints != null) {
      data['meeting_action_points'] = this.meetingActionPoints!.toJson();
    }
    return data;
  }
}

class MeetingActionPoints {
  bool? view;
  bool? create;
  bool? update;
  bool? delete;

  MeetingActionPoints({this.view, this.create, this.update, this.delete});

  MeetingActionPoints.fromJson(Map<String, dynamic> json) {
    view = json['view'];
    create = json['create'];
    update = json['update'];
    delete = json['delete'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['view'] = this.view;
    data['create'] = this.create;
    data['update'] = this.update;
    data['delete'] = this.delete;
    return data;
  }
}