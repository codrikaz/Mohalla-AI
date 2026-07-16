import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ai_post_suggestion.dart';

class AiPostException implements Exception {
  final String message;

  const AiPostException(this.message);

  @override
  String toString() => message;
}

class AiPostService {
  final SupabaseClient _client;

  AiPostService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<AiPostSuggestion> improvePost({
    required String text,
    required String targetLanguage,
  }) async {
    final trimmed = text.trim();
    if (trimmed.length < 10) {
      throw const AiPostException(
        'AI use karne ke liye kam se kam 10 characters likho.',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'ai-post-assistant',
        body: {
          'text': trimmed,
          'target_language': targetLanguage,
        },
      );

      if (response.status < 200 || response.status >= 300) {
        throw const AiPostException(
          'AI assistant abhi available nahi hai. Dobara try karo.',
        );
      }

      final data = response.data;
      if (data is! Map) {
        throw const AiPostException('AI se invalid response mila.');
      }

      final json = Map<String, dynamic>.from(data);
      if (json['error'] != null) {
        throw AiPostException(json['error'] as String);
      }
      return AiPostSuggestion.fromJson(json);
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] is String) {
        throw AiPostException(details['error'] as String);
      }
      throw const AiPostException(
        'AI assistant se connect nahi ho paya. Dobara try karo.',
      );
    } on AiPostException {
      rethrow;
    } catch (_) {
      throw const AiPostException(
        'AI assistant se connect nahi ho paya. Dobara try karo.',
      );
    }
  }
}
