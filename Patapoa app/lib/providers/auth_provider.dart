import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  late final GoogleSignIn _googleSignIn;
  bool _isGoogleInitialized = false;

  AuthProvider() {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    if (_isGoogleInitialized) {
      return;
    }
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: kIsWeb ? '884787724969-cc10epqnnd4dfj7c1als8uhrmf13h5vd.apps.googleusercontent.com' : null,
    );
    _isGoogleInitialized = true;
  }

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  // For social login flow
  Map<String, dynamic>? _partialSocialData;
  Map<String, dynamic>? get partialSocialData => _partialSocialData;

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
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final Map<String, dynamic>? data = jsonResponse['data'];
        if (data != null) {
          _user = User.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<bool> login(String login, String password, {String? userType}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = {
        'login': login,
        'password': password,
        'user_type': userType,
      }..removeWhere((key, value) => value == null);

      final response = await _apiService.post(
        ApiConfig.authLogin,
        request,
      );

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = jsonResponse['data'];
        if (data == null) {
          _errorMessage = 'Invalid response from server';
          return false;
        }

        final authResponse = AuthResponse.fromJson(data);

        _token = authResponse.token;
        _user = authResponse.user;

        if (_token != null) {
          await _apiService.setAuthToken(_token!);
          await _syncFcmToken(); // Add this
          notifyListeners();
          return true;
        } else {
          // If no token, maybe we need to verify OTP first
          notifyListeners();
          return true;
        }
      } else {
        if (jsonResponse['errors'] != null) {
          final Map<String, dynamic> errors = jsonResponse['errors'];
          _errorMessage = errors.values.map((e) => e is List ? e.first : e).join('\n');
        } else {
          _errorMessage = jsonResponse['message'] ?? 'Login failed';
        }
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

      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic>? data = jsonResponse['data'];
        if (data == null) {
          _errorMessage = 'Invalid response from server';
          return false;
        }

        final authResponse = AuthResponse.fromJson(data);

        _token = authResponse.token;
        _user = authResponse.user;

        if (_token != null) {
          await _apiService.setAuthToken(_token!);
          await _syncFcmToken(); // Add this
          notifyListeners();
          return true;
        } else {
          // If no token, maybe we need to verify OTP first
          notifyListeners();
          return true;
        }
      } else {
        if (jsonResponse['errors'] != null) {
          final Map<String, dynamic> errors = jsonResponse['errors'];
          _errorMessage = errors.values.map((e) => e is List ? e.first : e).join('\n');
        } else {
          _errorMessage = jsonResponse['message'] ?? 'Registration failed';
        }
        return false;
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      if (e.toString().contains('422')) {
        _errorMessage = 'This phone number is already registered. Please login instead.';
      } else {
        _errorMessage = 'Connection error. Please check if the server is running.';
      }
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
        if (data['errors'] != null) {
          final Map<String, dynamic> errors = data['errors'];
          _errorMessage = errors.values.map((e) => e is List ? e.first : e).join('\n');
        } else {
          _errorMessage = data['message'] ?? 'Failed to send OTP';
        }
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
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final Map<String, dynamic> data = jsonResponse.containsKey('data')
            ? jsonResponse['data']
            : jsonResponse;

        final authResponse = AuthResponse.fromJson(data);

        _token = authResponse.token;
        _user = authResponse.user;

        if (_token != null) {
          await _apiService.setAuthToken(_token!);
          await _syncFcmToken(); // Add this
          notifyListeners();
          return true;
        } else {
          // If no token, maybe we need to verify OTP first
          notifyListeners();
          return true;
        }
      } else {
        final data = json.decode(response.body);
        if (data['errors'] != null) {
          final Map<String, dynamic> errors = data['errors'];
          _errorMessage = errors.values.map((e) => e is List ? e.first : e).join('\n');
        } else {
          _errorMessage = data['message'] ?? 'Verification failed';
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Verification error: $e';
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

  Future<void> _syncFcmToken() async {
    if (_user == null) {
      return;
    }
    try {
      final fcmToken = await _notificationService.getToken();
      if (fcmToken != null) {
        await _apiService.put(ApiConfig.userUpdateFcmToken(_user!.id), {'fcm_token': fcmToken});
      }

      // Subscribe to role-specific topic
      await _notificationService.subscribeToRole(_user!.userType);
    } catch (e) {
      debugPrint('FCM Sync error: $e');
    }
  }

  Future<bool> signInWithGoogle(String userType) async {
    _isLoading = true;
    _errorMessage = null;
    _partialSocialData = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final body = {
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'social_id': googleUser.id,
        'provider': 'google',
        'user_type': userType,
      };

      final response = await _apiService.post(ApiConfig.authSocialLogin, body);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonResponse['data'];

        if (data['is_new_user'] == true) {
          // User needs to complete profile (phone/password)
          _partialSocialData = {
            'email': data['email'],
            'name': data['name'],
            'social_id': data['social_id'],
            'provider': data['provider'],
            'user_type': userType,
          };
          _isLoading = false;
          notifyListeners();
          return false; // Return false but partialSocialData is set
        }

        final authResponse = AuthResponse.fromJson(data);
        _token = authResponse.token;
        _user = authResponse.user;

        if (_token != null) {
          await _apiService.setAuthToken(_token!);
          notifyListeners();
          return true;
        }
      }

      _errorMessage = jsonResponse['message'] ?? 'Google Sign-In failed';
      return false;
    } catch (e) {
      debugPrint('Google Sign-In error raw: $e');
      if (e.toString().contains('401') || e.toString().contains('invalid_client')) {
        _errorMessage = 'Authorization Error: Please ensure this origin is registered in Google Cloud Console under "Authorized JavaScript origins".';
      } else {
        _errorMessage = 'Google Sign-In error: $e';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
