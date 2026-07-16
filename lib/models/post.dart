class Post {
  final String id;
  final String? colonyId;   // nullable — GPS based system mein optional
  final String userId;
  final String category;
  final String text;
  final String? imageUrl;
  final String? audioUrl;
  final int agreeCount;
  final int disagreeCount;
  final bool isPinned;
  final bool isCountryFeed;
  final String? posterDisplayName;
  final String? country;

  // GPS location
  final double? locationLat;
  final double? locationLng;

  // Reverse geocoded area info (stored at post time)
  final String? areaName;   // e.g. "Civil Lines"
  final String? cityName;   // e.g. "Rampur"
  final String? stateName;  // e.g. "Uttar Pradesh"

  final DateTime createdAt;

  // Joined from users table
  final String? anonymousName;
  final bool? userIsVerified;

  // Current user's vote
  final String? myVote;

  const Post({
    required this.id,
    this.colonyId,
    required this.userId,
    required this.category,
    required this.text,
    this.imageUrl,
    this.audioUrl,
    required this.agreeCount,
    required this.disagreeCount,
    required this.isPinned,
    this.isCountryFeed = false,
    this.posterDisplayName,
    this.country,
    this.locationLat,
    this.locationLng,
    this.areaName,
    this.cityName,
    this.stateName,
    required this.createdAt,
    this.anonymousName,
    this.userIsVerified,
    this.myVote,
  });

  bool get isHidden {
    final total = agreeCount + disagreeCount;
    if (total == 0) return false;
    return (disagreeCount / total) >= 0.60;
  }

  // Country feed: naam + area | Local: anonymous naam
  String get displayLabel {
    if (isCountryFeed && posterDisplayName != null) {
      final area = [areaName, cityName].where((s) => s != null && s.isNotEmpty).join(', ');
      return area.isNotEmpty ? '$posterDisplayName — $area' : posterDisplayName!;
    }
    return anonymousName ?? 'Anonymous';
  }

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        colonyId: json['colony_id'] as String?,
        userId: json['user_id'] as String,
        category: json['category'] as String,
        text: json['text'] as String,
        imageUrl: json['image_url'] as String?,
        audioUrl: json['audio_url'] as String?,
        agreeCount: (json['agree_count'] as num?)?.toInt() ?? 0,
        disagreeCount: (json['disagree_count'] as num?)?.toInt() ?? 0,
        isPinned: (json['is_pinned'] as bool?) ?? false,
        isCountryFeed: (json['is_country_feed'] as bool?) ?? false,
        posterDisplayName: json['poster_display_name'] as String?,
        country: json['country'] as String?,
        locationLat: (json['location_lat'] as num?)?.toDouble(),
        locationLng: (json['location_lng'] as num?)?.toDouble(),
        areaName: json['area_name'] as String?,
        cityName: json['city_name'] as String?,
        stateName: json['state_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        anonymousName: json['users']?['anonymous_name'] as String?,
        userIsVerified: json['users']?['is_rwa_verified'] as bool?,
        myVote: json['my_vote'] as String?,
      );

  Post copyWith({
    int? agreeCount,
    int? disagreeCount,
    String? myVote,
    bool? isPinned,
  }) =>
      Post(
        id: id,
        colonyId: colonyId,
        userId: userId,
        category: category,
        text: text,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
        agreeCount: agreeCount ?? this.agreeCount,
        disagreeCount: disagreeCount ?? this.disagreeCount,
        isPinned: isPinned ?? this.isPinned,
        isCountryFeed: isCountryFeed,
        posterDisplayName: posterDisplayName,
        country: country,
        locationLat: locationLat,
        locationLng: locationLng,
        areaName: areaName,
        cityName: cityName,
        stateName: stateName,
        createdAt: createdAt,
        anonymousName: anonymousName,
        userIsVerified: userIsVerified,
        myVote: myVote ?? this.myVote,
      );
}
