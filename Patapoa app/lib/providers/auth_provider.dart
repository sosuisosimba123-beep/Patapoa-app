import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAuth = await _apiService.isAuthenticated();
      if (isAuth) {
        _token = await _apiService.getAuthToken();
        await _fetchUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _apiService.get(ApiConfig.authMe);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(data['user'] ?? data);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequest(phone: phone, password: password);
      final response = await _apiService.post(
        ApiConfig.authLogin,
        request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authResponse = AuthResponse.fromJson(data);

        _token = authResponse.token;
        _user = authResponse.user;

        await _apiService.setAuthToken(_token!);
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _errorMessage =
            data['message'] ?? 'Login failed: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String userType,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        name: name,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        userType: userType,
        email: email,
      );

      final response = await _apiService.post(
        ApiConfig.authRegister,
        request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final authResponse = AuthResponse.fromJson(data);

        _token = authResponse.token;
        _user = authResponse.user;

        await _apiService.setAuthToken(_token!);
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _errorMessage =
            data['message'] ?? 'Registration failed: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = OtpSendRequest(phone: phone);
      final response = await _apiService.post(
        ApiConfig.authOtpSend,
        request.toJson(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = json.decode(response.body);
        _errorMessage =
            data['message'] ?? 'OTP send failed: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'OTP send error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = OtpVerifyRequest(phone: phone, otp: otp);
      final response = await _apiService.post(
        ApiConfig.authOtpVerify,
        request.toJson(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = json.decode(response.body);
        _errorMessage =
            data['message'] ??
            'OTP verification failed: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      _errorMessage = 'OTP verification error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_token != null) {
        await _apiService.post(ApiConfig.authLogout, {});
      }
    } catch (e) {
      // Ignore logout API errors
      debugPrint('Logout API error: $e');
    } finally {
      _token = null;
      _user = null;
      await _apiService.clearAuthToken();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
