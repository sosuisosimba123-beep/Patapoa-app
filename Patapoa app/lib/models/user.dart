import 'package:json_annotation/json_annotation.dart';
import '../utils/number_utils.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class User {
  final int id;
  final String name;
  final String? email;
  final String phone;
  final String userType;
  final bool? isActive;
  final bool? isVerified;
  final String? profileImage;
  final String? fcmToken;
  final Map<String, dynamic>? merchant;
  final Map<String, dynamic>? rider;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  User({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    required this.userType,
    this.isActive,
    this.isVerified,
    this.profileImage,
    this.fcmToken,
    this.merchant,
    this.rider,
    this.createdAt,
    this.updatedAt,
  });

  bool get isMerchantOnboarded => 
    userType == 'merchant' && 
    merchant != null && 
    merchant!['latitude'] != null && 
    merchant!['latitude'] != 0.0;
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: NumberUtils.paramInt(json['id']),
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String,
      userType: json['user_type'] as String,
      isActive: json['is_active'] as bool?,
      isVerified: json['is_verified'] as bool?,
      profileImage: json['profile_image'] as String?,
      fcmToken: json['fcm_token'] as String?,
      merchant: json['merchant'] as Map<String, dynamic>?,
      rider: json['rider'] as Map<String, dynamic>?,
      createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String),
    );
  }

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
  final User? user;
  final String? token;
  final String? tokenType;
  
  AuthResponse({
    this.user,
    this.token,
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
