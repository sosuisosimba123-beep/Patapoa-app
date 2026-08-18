import 'dart:convert';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await _apiService.post(ApiConfig.authLogin, {
        'phone': phone,
        'password': password,
        'user_type': userType,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? data['access_token'];
        
        if (token != null) {
          await _apiService.setAuthToken(token);
        }
        
        return data['data'] ?? data;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Error logging in: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    required String userType,
    String? email,
    String? city,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final body = {
        'name': name,
        'phone': phone,
        'password': password,
        'user_type': userType,
        if (email != null) 'email': email,
        if (city != null) 'city': city,
        ...?additionalData,
      };

      final response = await _apiService.post(ApiConfig.authRegister, body);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? data['access_token'];
        
        if (token != null) {
          await _apiService.setAuthToken(token);
        }
        
        return data['data'] ?? data;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Error registering: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post(ApiConfig.authLogout, {});
      await _apiService.clearAuthToken();
    } catch (e) {
      // Clear token even if logout request fails
      await _apiService.clearAuthToken();
      throw Exception('Error logging out: $e');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get(ApiConfig.authMe);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put(ApiConfig.authMe, data);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['data'] ?? responseData;
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<Map<String, dynamic>> socialLogin({
    required String email,
    required String name,
    required String socialId,
    required String provider,
    required String userType,
  }) async {
    try {
      final response = await _apiService.post(ApiConfig.authSocialLogin, {
        'email': email,
        'name': name,
        'social_id': socialId,
        'provider': provider,
        'user_type': userType,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['data']?['token'] ?? data['token'];

        if (token != null) {
          await _apiService.setAuthToken(token);
        }

        return data['data'] ?? data;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Social login failed');
      }
    } catch (e) {
      throw Exception('Error during social login: $e');
    }
  }

  Future<Map<String, dynamic>> completeSocialRegistration({
    required String email,
    required String phone,
    required String name,
    required String userType,
    required String socialId,
    required String provider,
  }) async {
    try {
      final response = await _apiService.post(ApiConfig.authSocialComplete, {
        'email': email,
        'phone': phone,
        'name': name,
        'user_type': userType,
        'social_id': socialId,
        'provider': provider,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['data']?['token'] ?? data['token'];

        if (token != null) {
          await _apiService.setAuthToken(token);
        }

        return data['data'] ?? data;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Registration completion failed');
      }
    } catch (e) {
      throw Exception('Error completing registration: $e');
    }
  }

  Future<bool> isAuthenticated() async {
    return await _apiService.isAuthenticated();
  }
}
