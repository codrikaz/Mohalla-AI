class Reply {
  final String id;
  final String postId;
  final String userId;
  final String text;
  final String? audioUrl;
  final DateTime createdAt;
  final String? anonymousName;
  final bool? userIsVerified;

  const Reply({
    required this.id,
    required this.postId,
    required this.userId,
    required this.text,
    this.audioUrl,
    required this.createdAt,
    this.anonymousName,
    this.userIsVerified,
  });

  factory Reply.fromJson(Map<String, dynamic> json) => Reply(
        id: json['id'] as String,
        postId: json['post_id'] as String,
        userId: json['user_id'] as String,
        text: json['text'] as String,
        audioUrl: json['audio_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        anonymousName: json['users']?['anonymous_name'] as String?,
        userIsVerified: json['users']?['is_rwa_verified'] as bool?,
      );
}
