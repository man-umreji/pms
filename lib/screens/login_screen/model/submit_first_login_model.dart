class SubmitFirstLoginReqModel {
  String? otp;
  String? oldPassword;
  String? newPassword;
  String? confirmPassword;

  SubmitFirstLoginReqModel({
    this.otp,
    this.oldPassword,
    this.newPassword,
    this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    "otp": otp,
    "old_password": oldPassword,
    "new_password": newPassword,
    "confirm_password": confirmPassword,
  };
}

class SubmitFirstLoginResModel {
  bool? success;
  String? message;

  SubmitFirstLoginResModel({
    this.success,
    this.message,
  });

  SubmitFirstLoginResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    return data;
  }
}