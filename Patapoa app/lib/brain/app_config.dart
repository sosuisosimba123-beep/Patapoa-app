/// AppConfig contains local configuration settings for the Patapoa Brain.
class AppConfig {
  /// The Gemini API Key should be provided via --dart-define=GEMINI_API_KEY=...
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
}
