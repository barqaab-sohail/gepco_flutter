class UserModel {
  int? status;
  String? userName;
  String? email;
  String? picture;
  String? token;
  String? message;

  UserModel(
      {this.status,
      this.userName,
      this.email,
      this.picture,
      this.token,
      this.message});

  UserModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    userName = json['userName'];
    email = json['email'];
    picture = json['picture'];
    token = json['token'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['userName'] = userName;
    data['email'] = email;
    data['picture'] = picture;
    data['token'] = token;
    data['message'] = message;
    return data;
  }
}
