class FirstEmailOtpReqModel {
  String? userName;


  FirstEmailOtpReqModel({
    this.userName,

  });

  Map<String, dynamic> toJson() => {
    "username": userName,

  };
}

class FirstEmailOtpResModel {
  bool? success;
  String? message;
  String? userId;

  FirstEmailOtpResModel({this.success, this.message, this.userId});

  FirstEmailOtpResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    userId = json['user_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    data['user_id'] = this.userId;
    return data;
  }
}