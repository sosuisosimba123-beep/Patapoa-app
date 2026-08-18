import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'app_config.dart';

/// GeminiClient initializes the Google Generative AI model.
class GeminiClient {
  /// Priority order: 
  /// 1. --dart-define=GEMINI_API_KEY=...
  /// 2. AppConfig.geminiApiKey (Local Fallback)
  static String get _apiKey {
    const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    
    return AppConfig.geminiApiKey;
  }

  /// Returns an initialized GenerativeModel.
  static GenerativeModel createModel({String modelName = 'gemini-1.5-flash'}) {
    final key = _apiKey;
    
    if (key.isEmpty || key == 'YOUR_API_KEY_HERE') {
      debugPrint('WARNING: Gemini API Key is missing. AI features will be unavailable.');
      // Return a model that will fail gracefully on use rather than crashing on init
      return GenerativeModel(model: modelName, apiKey: 'MISSING_KEY');
    }
    
    return GenerativeModel(
      model: modelName,
      apiKey: key,
    );
  }
}
