class GetMeatingTypeReqModel {
  String? userName;
  String? password;

  GetMeatingTypeReqModel({
    this.userName,
    this.password,
  });

  Map<String, dynamic> toJson() => {
    "username": userName,
    "password": password,
  };
}

class GetMeatingTypeResModel {
  bool? success;
  List<MeetingType>? meetingType;

  GetMeatingTypeResModel({this.success, this.meetingType});

  GetMeatingTypeResModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['meeting_type'] != null) {
      meetingType = <MeetingType>[];
      json['meeting_type'].forEach((v) {
        meetingType!.add(MeetingType.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['success'] = success;
    if (meetingType != null) {
      data['meeting_type'] =
          meetingType!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MeetingType {
  int? id;
  String? name;

  MeetingType({this.id, this.name});

  MeetingType.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  // 🔥🔥🔥 IMPORTANT FIX (DO NOT MISS)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MeetingType &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}