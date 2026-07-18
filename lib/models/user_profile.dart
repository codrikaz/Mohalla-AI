class UserProfile {
  final String id;
  final String phoneHash;
  final bool isRwaVerified;
  final String? fcmToken;
  final String? anonymousName;
  final String? displayName; // Country feed mein real naam
  final String? countryCode; // ISO 3166-1 alpha-2 e.g. "IN", "US"
  final String? countryName; // e.g. "India", "United States"
  final String? countryFlag; // e.g. "🇮🇳"
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.phoneHash,
    this.isRwaVerified = false,
    this.fcmToken,
    this.anonymousName,
    this.displayName,
    this.countryCode,
    this.countryName,
    this.countryFlag,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        phoneHash: json['phone_hash'] as String,
        isRwaVerified: (json['is_rwa_verified'] as bool?) ?? false,
        fcmToken: json['fcm_token'] as String?,
        anonymousName: json['anonymous_name'] as String?,
        displayName: json['display_name'] as String?,
        countryCode: json['country_code'] as String?,
        countryName: json['country_name'] as String?,
        countryFlag: json['country_flag'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_hash': phoneHash,
        'is_rwa_verified': isRwaVerified,
        'fcm_token': fcmToken,
        'anonymous_name': anonymousName,
        'display_name': displayName,
        'country_code': countryCode,
        'country_name': countryName,
        'country_flag': countryFlag,
        'created_at': createdAt.toIso8601String(),
      };

  UserProfile copyWith({
    String? fcmToken,
    String? anonymousName,
    String? displayName,
    String? countryCode,
    String? countryName,
    String? countryFlag,
  }) =>
      UserProfile(
        id: id,
        phoneHash: phoneHash,
        isRwaVerified: isRwaVerified,
        fcmToken: fcmToken ?? this.fcmToken,
        anonymousName: anonymousName ?? this.anonymousName,
        displayName: displayName ?? this.displayName,
        countryCode: countryCode ?? this.countryCode,
        countryName: countryName ?? this.countryName,
        countryFlag: countryFlag ?? this.countryFlag,
        createdAt: createdAt,
      );
}
