import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart' show kDebugMode;

// Use your live production URL here when ready
const String _prodUrl = 'https://pocketbase.patapoa.online';
// Local development URL
const String _devUrl = 'http://10.0.2.2:8090';

// Initialize PocketBase based on build mode
final pb = PocketBase(kDebugMode ? _devUrl : _prodUrl);

Future<void> initPocketBase() async {
  final prefs = await SharedPreferences.getInstance();

  // Load the stored auth store string if it exists
  final storedAuthJson = prefs.getString('pb_auth');
  if (storedAuthJson != null) {
    try {
      final authData = jsonDecode(storedAuthJson);
      pb.authStore.save(authData['token'], authData['model']);
    } catch (_) {
      // Clear if invalid
    }
  }

  // Listen to auth changes and save them automatically
  pb.authStore.onChange.listen((event) {
    if (pb.authStore.isValid) {
      final authData = {
        'token': pb.authStore.token,
        'model': pb.authStore.model,
      };
      prefs.setString('pb_auth', jsonEncode(authData));
    } else {
      prefs.remove('pb_auth');
    }
  });
}
