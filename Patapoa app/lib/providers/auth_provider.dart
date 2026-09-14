import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../services/api_service.dart';
import '../services/pocketbase_services.dart';
import '../models/user.dart';
import '../services/notification_service.dart';
import '../utils/location_helper.dart';

class AuthProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final ApiService _apiService = ApiService();
  late final GoogleSignIn _googleSignIn;
  bool _isGoogleInitialized = false;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _partialSocialData;

  AuthProvider() {
    _initializeGoogleSignIn();
    _syncWithPocketBase();
    // Listen to auth changes in PocketBase to keep Provider in sync
    pb.authStore.onChange.listen((_) {
      _syncWithPocketBase();
    });
  }

  void _initializeGoogleSignIn() {
    if (_isGoogleInitialized) return;
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: kIsWeb ? '884787724969-cc10epqnnd4dfj7c1als8uhrmf13h5vd.apps.googleusercontent.com' : null,
    );
    _isGoogleInitialized = true;
  }

  User? get user => _user;
  String? get token => pb.authStore.token;
  bool get isAuthenticated => pb.authStore.isValid;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get partialSocialData => _partialSocialData;

  void _syncWithPocketBase() {
    if (pb.authStore.isValid && pb.authStore.model != null) {
      final model = pb.authStore.model;
      if (model is RecordModel) {
        _user = User.fromJson({
          'id': model.id,
          ...model.data,
          'user_type': model.data['user_type'] ?? model.data['userType'] ?? model.data['role'],
          'created': model.created,
          'updated': model.updated,
        });
      } else {
        // Safe check for Admin or other models
        try {
          final data = (model as dynamic);
          _user = User(
            id: model.id,
            name: 'Superuser',
            email: data.email,
            userType: 'admin',
            isActive: true,
            isVerified: true,
            createdAt: DateTime.parse(model.created),
            updatedAt: DateTime.parse(model.updated),
          );
        } catch (e) {
          debugPrint('Error syncing non-record model: $e');
          _user = null;
        }
      }
    } else {
      _user = null;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password, {String? userType}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Attempting login for: $email');
      
      // 1. PocketBase Login
      if (userType == 'admin') {
        await pb.admins.authWithPassword(email, password);
      } else {
        final authData = await pb.collection('users').authWithPassword(email, password);
        debugPrint('PocketBase Login success: ${authData.record?.id}');
        
        // 2. NEW: Aggressive MySQL Sync/Login
        try {
          final res = await _apiService.post('/auth/login', {
            'login': email,
            'password': password,
            'user_type': userType,
          });
          
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final token = data['token'] ?? data['access_token'];
            if (token != null) await _apiService.setAuthToken(token);
            debugPrint('MySQL Login/Token Sync success');
          } else if (res.statusCode == 404 || res.statusCode == 401) {
            // User might exist in PB but not Laravel yet (Sync Gap)
            debugPrint('User missing in MySQL. Attempting auto-sync registration...');
            final pbModel = authData.record!;
            await _apiService.post('/auth/register', {
              'name': pbModel.data['name'] ?? 'User',
              'phone': pbModel.data['phone'] ?? pbModel.username,
              'email': email,
              'password': password,
              'user_type': userType ?? pbModel.data['user_type'] ?? 'customer',
            });
            // Try login again after auto-sync
            final retryRes = await _apiService.post('/auth/login', {
              'login': email, 'password': password, 'user_type': userType,
            });
            if (retryRes.statusCode == 200) {
              final data = jsonDecode(retryRes.body);
              final token = data['token'] ?? data['access_token'];
              if (token != null) await _apiService.setAuthToken(token);
            }
          }
        } catch (e) {
          debugPrint('Warning: MySQL Sync failed during login: $e');
        }

        // If userType is provided, verify it matches
        if (userType != null && authData.record != null) {
          final actualRole = authData.record!.data['user_type'] ?? authData.record!.data['userType'];
          debugPrint('Checking role: expected $userType, got $actualRole');
          if (actualRole != userType) {
            pb.authStore.clear();
            _errorMessage = 'Invalid account type for this login.';
            return false;
          }
        }
      }
      
      await _syncFcmToken();
      return true;
    } on ClientException catch (e) {
      debugPrint('PocketBase Login Error: ${e.response}');
      final msg = e.response['message'] ?? 'Login failed.';
      final errors = e.response['data'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        _errorMessage = errors.entries.map((e) => '${e.key}: ${e.value['message']}').join('\n');
      } else {
        _errorMessage = msg;
      }
      return false;
    } catch (e) {
      debugPrint('Unexpected Login Error: $e');
      _errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String userType,
    String? passwordConfirmation,
    Map<String, dynamic>? additionalData,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Attempting registration for: $email');
      // 1. Create the user record
      final body = {
        'username': phone.replaceAll('+', ''), // Phone as username
        'email': email,
        'password': password,
        'passwordConfirm': passwordConfirmation ?? password,
        'name': name,
        'phone': phone,
        'user_type': userType, // Primary field
        'userType': userType,  // Compat field 1
        'role': userType,      // Compat field 2
        ...?additionalData,
      };
      debugPrint('Registration body: $body');
      
      await pb.collection('users').create(body: body);
      debugPrint('User created successfully in PocketBase');

      // 2. NEW: Sync with MySQL (Laravel)
      try {
        await _apiService.post('/auth/register', {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'user_type': userType,
        });
        debugPrint('User synced with MySQL successfully');
      } catch (e) {
        debugPrint('Warning: MySQL Sync failed: $e');
        // We don't fail the whole registration if MySQL fails, 
        // but it might limit functionality until synced.
      }

      // 3. Login immediately to get the token
      await pb.collection('users').authWithPassword(email, password);
      debugPrint('Login success. Role in store: ${pb.authStore.model?.data['user_type']}');

      // 3. Request verification email
      try {
        await pb.collection('users').requestVerification(email);
        debugPrint('Verification email requested');
      } catch (e) {
        debugPrint('Warning: Could not send verification email: $e');
        // We don't fail the whole registration if email fails (maybe SMTP not set up)
      }

      await _syncFcmToken();
      return true;
    } on ClientException catch (e) {
      debugPrint('PocketBase Registration Error: ${e.response}');
      final msg = e.response['message'] ?? 'Registration failed.';
      final errors = e.response['data'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        _errorMessage = errors.entries.map((e) => '${e.key}: ${e.value['message']}').join('\n');
      } else {
        _errorMessage = msg;
      }
      return false;
    } catch (e) {
      debugPrint('Unexpected Registration Error: $e');
      _errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle(String userType) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Starting Google Fast-Track for $userType...');
      final authData = await pb.collection('users').authWithOAuth2(
        'google',
        (url) async {
          await FlutterWebAuth2.authenticate(
            url: url.toString(),
            callbackUrlScheme: 'com.nacci.patapoa.app',
          );
        }
      );

      if (pb.authStore.isValid && pb.authStore.model != null) {
        final model = pb.authStore.model as RecordModel;
        final currentRole = model.data['user_type'] ?? model.data['userType'] ?? model.data['role'];
        
        // Auto-assign role if missing or if user explicitly chose to upgrade
        if (currentRole == null || (currentRole == 'customer' && userType != 'customer')) {
           await pb.collection('users').update(model.id, body: {
             'user_type': userType,
             'userType': userType,
             'role': userType,
           });
           await pb.collection('users').authRefresh();
        }

        // Fast-track: Sync with MySQL in background
        _syncWithLaravel(model, userType);
        
        await _syncFcmToken();
        debugPrint('Google Auth Successful. Redirecting...');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Google Auth Error: $e');
      _errorMessage = 'Login failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Internal helper to ensure MySQL is always in sync with Google Auth
  Future<void> _syncWithLaravel(RecordModel pbUser, String userType) async {
    try {
      await _apiService.post('/auth/social-sync', {
        'pb_id': pbUser.id,
        'email': pbUser.data['email'] ?? '',
        'name': pbUser.data['name'],
        'user_type': userType,
      });
    } catch (e) {
      debugPrint('Laravel Social Sync ignored: $e');
    }
  }

  Future<bool> sendOtp(String phone) async {
    // Placeholder for PocketBase phone auth if implemented
    return true; 
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    // Placeholder for PocketBase phone auth if implemented
    return true;
  }

  Future<void> logout() async {
    pb.authStore.clear();
    _user = null;
    notifyListeners();
  }

  Future<void> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await pb.collection('users').requestPasswordReset(email);
    } catch (e) {
      _errorMessage = 'Failed to send reset email: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncFcmToken() async {
    if (_user == null) return;
    try {
      final fcmToken = await _notificationService.getToken();
      if (fcmToken != null) {
        await pb.collection('users').update(_user!.id, body: {
          'fcm_token': fcmToken,
        });
      }
      await _notificationService.subscribeToRole(_user!.userType);
    } catch (e) {
      debugPrint('FCM Sync error: $e');
    }
  }

  /// Tests sending device coordinates to PocketBase.
  Future<bool> updateUserLocation() async {
    if (_user == null || !isAuthenticated) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Capturing location...');
      final coords = await LocationHelper.getCurrentCoordinates();
      debugPrint('Captured: $coords. Sending to PocketBase...');

      await pb.collection('users').update(_user!.id, body: {
        'latitude': coords['latitude'],
        'longitude': coords['longitude'],
      });

      debugPrint('Location updated successfully in PocketBase.');
      return true;
    } catch (e) {
      _errorMessage = 'Location update failed: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
