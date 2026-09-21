import 'package:json_annotation/json_annotation.dart';
import '../utils/number_utils.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class User {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String userType;
  final bool isActive;
  final bool isVerified;
  final String? profileImage;
  final String? fcmToken;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? merchant;
  final Map<String, dynamic>? rider;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.userType,
    this.isActive = true,
    this.isVerified = false,
    this.profileImage,
    this.fcmToken,
    this.latitude,
    this.longitude,
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
      id: json['id'].toString(),
      name: json['name'] ?? json['username'] ?? 'User',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      userType: json['user_type'] ?? json['userType'] ?? json['role'] ?? 'customer',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      isVerified: json['verified'] ?? json['is_verified'] ?? false,
      profileImage: json['profileImage'] ?? json['profile_image'] as String?,
      fcmToken: json['fcm_token'] as String?,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      merchant: json['merchant'] as Map<String, dynamic>?,
      rider: json['rider'] as Map<String, dynamic>?,
      createdAt: json['created'] == null ? (json['created_at'] == null ? null : DateTime.parse(json['created_at'])) : DateTime.parse(json['created']),
      updatedAt: json['updated'] == null ? (json['updated_at'] == null ? null : DateTime.parse(json['updated_at'])) : DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'user_type': userType,
      'is_active': isActive,
      'verified': isVerified,
      'fcm_token': fcmToken,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
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
