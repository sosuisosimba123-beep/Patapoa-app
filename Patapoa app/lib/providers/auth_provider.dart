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
        
        // 2. UNIVERSAL MIRROR SYNC (Laravel)
        final pbModel = authData.record!;
        final finalType = userType ?? pbModel.data['user_type'] ?? 'customer';

        try {
          final syncRes = await _apiService.post('/auth/pb-sync', {
            'email': email,
            'name': pbModel.data['name'] ?? 'User',
            'user_type': finalType,
          });

          if (syncRes.statusCode == 200) {
            final data = jsonDecode(syncRes.body);
            final token = data['data']?['token'] ?? data['token'];
            if (token != null) await _apiService.setAuthToken(token);
            debugPrint('Mirror Sync Success: MySQL is now aware of this $finalType');
          } else {
            throw Exception('Laravel Sync Failed: ${syncRes.body}');
          }
        } catch (e) {
          debugPrint('Critical Mirror Sync Error: $e');
          _errorMessage = 'System Synchronization Error. Please contact support.';
          pb.authStore.clear();
          return false;
        }

        // Verify role matches requested type
        if (userType != null && authData.record != null) {
          final actualRole = authData.record!.data['user_type'] ?? authData.record!.data['userType'];
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
      final errors = e.response['data'] as Map<String, dynamic>?;      if (errors != null && errors.isNotEmpty) {
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
      debugPrint('Initiating Google Fast-Track Sign-In (Manual Flow)...');
      
      // 1. Get the Google Auth Provider info
      final authMethods = await pb.collection('users').listAuthMethods();
      final provider = authMethods.oauth2.firstWhere((p) => p.name == 'google');
      
      // 2. Open browser and get the redirect URL
      final redirectContext = await FlutterWebAuth2.authenticate(
        url: provider.authUrl + '&redirect_uri=https://pocketbase.patapoa.online/api/oauth2-redirect',
        callbackUrlScheme: 'com.nacci.patapoa.app',
      );

      // 3. Extract the code from the redirect URL
      final code = Uri.parse(redirectContext).queryParameters['code'];
      if (code == null) throw Exception('No authorization code received');

      // 4. Finalize authentication with PocketBase
      final authData = await pb.collection('users').authWithOAuth2(
        'google',
        code,
        provider.codeVerifier,
        'https://pocketbase.patapoa.online/api/oauth2-redirect',
      );

      if (pb.authStore.isValid && pb.authStore.model != null) {
        final model = pb.authStore.model as RecordModel;
        
        // Ensure name and user_type are NEVER empty in PocketBase
        final String existingName = (model.data['name'] ?? '').toString();
        final String? existingRole = model.data['user_type'] ?? model.data['userType'] ?? model.data['role'];
        
        // If it's a new user or fields are missing, perform a "Full Identity Sync"
        if (existingName.isEmpty || existingRole == null || existingRole.isEmpty || (existingRole == 'customer' && userType != 'customer')) {
           final targetRole = (existingRole == 'customer' && userType != 'customer') ? userType : (existingRole ?? userType);
           
           // Extract name from OAuth2 data if missing in profile
           String? nameToSet = existingName.isNotEmpty ? existingName : authData.meta?['name'];
           if (nameToSet == null || nameToSet.toString().isEmpty) nameToSet = 'Patapoa User';

           await pb.collection('users').update(model.id, body: {
             'name': nameToSet,
             'user_type': targetRole,
             'userType': targetRole, // Backwards compatibility
             'role': targetRole,     // Backwards compatibility
           });
           
           debugPrint('PocketBase Identity Sync: Set name="$nameToSet", role="$targetRole"');
           await pb.collection('users').authRefresh();
        }

        // UNIVERSAL MIRROR SYNC (Laravel - Keeping for now until full migration)
        final pbModel = authData.record!;
        final finalType = userType ?? pbModel.data['user_type'] ?? 'customer';

        try {
          final syncRes = await _apiService.post('/auth/pb-sync', {
            'email': pbModel.data['email'] ?? '',
            'name': pbModel.data['name'] ?? 'User',
            'user_type': finalType,
          });

          if (syncRes.statusCode == 200) {
            final data = jsonDecode(syncRes.body);
            final token = data['data']?['token'] ?? data['token'];
            if (token != null) await _apiService.setAuthToken(token);
            debugPrint('Mirror Sync Success: MySQL is now aware of this $finalType');
          }
        } catch (e) {
          debugPrint('Google Laravel Sync Warning: $e');
        }
        
        await _syncFcmToken();
        debugPrint('Authentication successful. Directing to app...');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Google Auth Error: $e');
      _errorMessage = 'Google Sign-In was cancelled or failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
