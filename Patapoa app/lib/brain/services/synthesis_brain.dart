import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../gemini_client.dart';
import '../brain_rules.dart';

/// SynthesisBrain analyzes operational data for administrative insights.
class SynthesisBrain {
  final GenerativeModel _model;

  SynthesisBrain() : _model = GeminiClient.createModel();

  /// Takes raw operational logs and returns administrative insights.
  Future<String?> synthesizeAdminData(String rawLogs) async {
    if (rawLogs.trim().isEmpty) return "No data provided for synthesis.";

    try {
      final prompt = [
        Content.text(BrainRules.operationalSynthesisRule),
        Content.text('RAW OPERATIONAL DATA:\n$rawLogs'),
      ];

      final response = await _model.generateContent(prompt);
      
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      }
      return _localSynthesisFallback(rawLogs);
    } catch (e) {
      debugPrint('SynthesisBrain API Error: $e');
      return _localSynthesisFallback(rawLogs);
    }
  }

  /// Provides a basic summary when the AI intelligence layer is unavailable.
  String _localSynthesisFallback(String rawLogs) {
    return '''
Administrative Insights (AI Layer Offline):
• System is currently operating on basic analytical rules.
• Raw logs have been received and are stored for processing.
• Manual oversight recommended: Check dashboard for recent order counts and stock levels.
• Note: Detailed AI trend analysis is temporarily unavailable due to quota limits or connectivity issues.
''';
  }
}
