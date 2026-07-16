class Alert {
  final String id;
  final String sentBy;
  final String type;
  final String message;
  final DateTime createdAt;
  final String? senderName;

  const Alert({
    required this.id,
    required this.sentBy,
    required this.type,
    required this.message,
    required this.createdAt,
    this.senderName,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
        id: json['id'] as String,
        sentBy: json['sent_by'] as String,
        type: json['type'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        senderName: json['users']?['anonymous_name'] as String?,
      );
}
