import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/pocketbase_services.dart';
import '../models/user.dart';
import '../services/notification_service.dart';
import '../utils/location_helper.dart';

class AuthProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
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
      
      if (userType == 'admin') {
        await pb.admins.authWithPassword(email, password);
      } else {
        final authData = await pb.collection('users').authWithPassword(email, password);
        debugPrint('Login success: ${authData.record?.id}');
        
        // If userType is provided, verify it matches
        if (userType != null && authData.record != null) {
          final actualRole = authData.record!.data['userType'];
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
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Attempting registration for: $email');
      // 1. Create the user record
      final body = {
        'username': phone.replaceAll('+', ''), // Phone as username (removing + for compatibility)
        'email': email,
        'password': password,
        'passwordConfirm': passwordConfirmation ?? password,
        'name': name,
        'phone': phone,
        'userType': userType,
      };
      debugPrint('Registration body: $body');
      
      await pb.collection('users').create(body: body);
      debugPrint('User created successfully');

      // 2. Login immediately to get the token
      await pb.collection('users').authWithPassword(email, password);
      debugPrint('Login after registration success');

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
    _partialSocialData = null;
    notifyListeners();

    try {
      final authData = await pb.collection('users').authWithOAuth2(
        'google',
        (url) async {
          await FlutterWebAuth2.authenticate(
            url: url.toString(),
            callbackUrlScheme: 'com.nacci.patapoa.app',
          );
        }
      );

      if (authData.record != null) {
        // If it's a new user, we might need to set the userType
        if (authData.record!.data['userType'] == null) {
           await pb.collection('users').update(authData.record!.id, body: {
             'userType': userType,
           });
        }
        await _syncFcmToken();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Google Sign-In failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
