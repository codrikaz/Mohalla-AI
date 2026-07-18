class AiPostSuggestion {
  final String title;
  final String improvedText;
  final String category;
  final String translatedText;
  final String language;
  final int remainingRequests;
  final bool cached;

  const AiPostSuggestion({
    required this.title,
    required this.improvedText,
    required this.category,
    required this.translatedText,
    required this.language,
    required this.remainingRequests,
    required this.cached,
  });

  factory AiPostSuggestion.fromJson(Map<String, dynamic> json) {
    return AiPostSuggestion(
      title: json['title'] as String? ?? '',
      improvedText: json['improved_text'] as String? ?? '',
      category: json['category'] as String? ?? 'info',
      translatedText: json['translated_text'] as String? ?? '',
      language: json['language'] as String? ?? 'Original',
      remainingRequests: (json['remaining_requests'] as num?)?.toInt() ?? 0,
      cached: json['cached'] as bool? ?? false,
    );
  }

  String get postText {
    final value = '$title\n\n$improvedText'.trim();
    if (value.length <= 500) return value;
    return value.substring(0, 500).trimRight();
  }
}
