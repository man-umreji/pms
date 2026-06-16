class ChangePasswordReqModel {
  String? oldPassword;
  String? newPassword;
  String? confirmPassword;

  ChangePasswordReqModel({
    this.oldPassword,
    this.newPassword,
    this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    "oldpass": oldPassword,
    "newpass": newPassword,
    "cpass": confirmPassword,
  };
}

class ChangePasswordResModel {
  bool? success;
  String? message;

  ChangePasswordResModel({this.success, this.message});

  ChangePasswordResModel.fromJson(Map<String, dynamic> json) {
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