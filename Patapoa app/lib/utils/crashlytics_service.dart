import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  /// Captures non-fatal custom exceptions.
  Future<void> recordError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal = false}) async {
    if (kDebugMode) {
      print('Crashlytics: Recording error: $exception');
    }
    await FirebaseCrashlytics.instance.recordError(exception, stack, reason: reason, fatal: fatal);
  }

  /// Sets user identifier for Crashlytics.
  Future<void> setUserIdentifier(String identifier) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
  }

  /// Triggers a test crash.
  void triggerTestCrash() {
    FirebaseCrashlytics.instance.crash();
  }
}
