import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final int id;
  final String name;
  final String? email;
  final String phone;
  final String userType;
  final bool isActive;
  final bool isVerified;
  final String? profileImage;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  User({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    required this.userType,
    required this.isActive,
    required this.isVerified,
    this.profileImage,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class LoginRequest {
  final String phone;
  final String password;
  
  LoginRequest({
    required this.phone,
    required this.password,
  });
  
  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RegisterRequest {
  final String name;
  final String phone;
  final String password;
  final String passwordConfirmation;
  final String userType;
  final String? email;
  
  RegisterRequest({
    required this.name,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    required this.userType,
    this.email,
  });
  
  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AuthResponse {
  final User user;
  final String token;
  final String? tokenType;
  
  AuthResponse({
    required this.user,
    required this.token,
    this.tokenType,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class OtpSendRequest {
  final String phone;
  
  OtpSendRequest({
    required this.phone,
  });
  
  factory OtpSendRequest.fromJson(Map<String, dynamic> json) => _$OtpSendRequestFromJson(json);
  Map<String, dynamic> toJson() => _$OtpSendRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class OtpVerifyRequest {
  final String phone;
  final String otp;
  
  OtpVerifyRequest({
    required this.phone,
    required this.otp,
  });
  
  factory OtpVerifyRequest.fromJson(Map<String, dynamic> json) => _$OtpVerifyRequestFromJson(json);
  Map<String, dynamic> toJson() => _$OtpVerifyRequestToJson(this);
}
