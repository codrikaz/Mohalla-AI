import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post.dart';
import '../models/reply.dart';
import '../core/utils/haversine_utils.dart';
import 'auth_provider.dart';

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// 'local' | 'country'
final selectedFeedTypeProvider = StateProvider<String>((ref) => 'local');

// Local feed — GPS radius se posts
final feedProvider =
    StateNotifierProvider<FeedNotifier, AsyncValue<List<Post>>>(
  (ref) => FeedNotifier(),
);

// Country feed — user ke country ki posts
final countryFeedProvider =
    StateNotifierProvider<CountryFeedNotifier, AsyncValue<List<Post>>>(
  (ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    return CountryFeedNotifier(profile?.countryCode);
  },
);

// ─── Local Feed (GPS based) ───────────────────────────────────────────────────
class FeedNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _channel;
  Position? _position;

  // 2km radius — local feed
  static const double _radiusMeters = 2000;

  FeedNotifier() : super(const AsyncValue.loading()) {
    _loadPosts();
    _subscribeRealtime();
  }

  Future<void> _loadPosts() async {
    try {
      final userId = _client.auth.currentUser?.id;

      // GPS position lo
      try {
        _position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        // GPS na mile toh bhi chalo — saari posts dikhao
      }

      // Saari local posts fetch karo (country feed nahi)
      final data = await _client
          .from('posts')
          .select('*, users(anonymous_name, is_rwa_verified)')
          .eq('is_country_feed', false)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .limit(300);

      List<Post> posts = (data as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();

      // GPS mile toh radius filter lagao
      if (_position != null) {
        posts = posts.where((p) {
          if (p.locationLat == null || p.locationLng == null) return false;
          final dist = HaversineUtils.distanceInMeters(
            _position!.latitude,
            _position!.longitude,
            p.locationLat!,
            p.locationLng!,
          );
          return dist <= _radiusMeters;
        }).toList();
      }

      // User ke votes load karo
      if (userId != null && posts.isNotEmpty) {
        final postIds = posts.map((p) => p.id).toList();
        final votes = await _client
            .from('votes')
            .select('post_id, type')
            .eq('user_id', userId)
            .inFilter('post_id', postIds);

        final voteMap = {
          for (final v in votes as List)
            (v as Map<String, dynamic>)['post_id'] as String:
                v['type'] as String
        };

        posts = posts.map((p) => p.copyWith(myVote: voteMap[p.id])).toList();
      }

      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    _channel = _client
        .channel('local_feed_gps')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            if (payload.newRecord['is_country_feed'] != true) _loadPosts();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'posts',
          callback: (_) => _loadPosts(),
        )
        .subscribe();
  }

  Future<bool> createPost({
    required String category,
    required String text,
    XFile? image,
    bool isCountryFeed = false,
    String? posterDisplayName,
    String? countryCode,
    double? locationLat,
    double? locationLng,
    String? areaName,
    String? cityName,
    String? stateName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      String? imageUrl;
      if (image != null) {
        final bytes = await image.readAsBytes();
        final ext = image.path.split('.').last;
        final path =
            'posts/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _client.storage.from('post-images').uploadBinary(path, bytes);
        imageUrl = _client.storage.from('post-images').getPublicUrl(path);
      }

      await _client.from('posts').insert({
        'user_id': userId,
        'category': category,
        'text': text,
        'image_url': imageUrl,
        'agree_count': 0,
        'disagree_count': 0,
        'is_pinned': false,
        'is_country_feed': isCountryFeed,
        'country': isCountryFeed ? countryCode : null,
        'poster_display_name': isCountryFeed ? posterDisplayName : null,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'area_name': areaName,
        'city_name': cityName,
        'state_name': stateName,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> vote(String postId, String voteType) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final posts = state.valueOrNull ?? [];
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    if (posts[idx].myVote != null) return;

    final updated = List<Post>.from(posts);
    updated[idx] = posts[idx].copyWith(
      agreeCount: voteType == 'agree'
          ? posts[idx].agreeCount + 1
          : posts[idx].agreeCount,
      disagreeCount: voteType == 'disagree'
          ? posts[idx].disagreeCount + 1
          : posts[idx].disagreeCount,
      myVote: voteType,
    );
    state = AsyncValue.data(updated);

    try {
      await _client.from('votes').insert({
        'post_id': postId,
        'user_id': userId,
        'type': voteType,
      });
      await _client.rpc('increment_vote', params: {
        'p_post_id': postId,
        'p_vote_type': voteType,
      });
    } catch (_) {
      state = AsyncValue.data(posts);
    }
  }

  Future<bool> deletePost(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await _client
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', userId);
      await _loadPosts();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() => _loadPosts();

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// ─── Country Feed ─────────────────────────────────────────────────────────────
class CountryFeedNotifier extends StateNotifier<AsyncValue<List<Post>>> {
  final String? _countryCode;
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  CountryFeedNotifier(this._countryCode) : super(const AsyncValue.loading()) {
    _load();
    _subscribeRealtime();
  }

  Future<void> _load() async {
    try {
      var query = _client
          .from('posts')
          .select('*, users(anonymous_name, is_rwa_verified)')
          .eq('is_country_feed', true);

      if (_countryCode != null) {
        query = query.eq('country', _countryCode);
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(100);

      final posts = (data as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    _channel = _client
        .channel('country_feed:${_countryCode ?? 'all'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            final isCountry = payload.newRecord['is_country_feed'] == true;
            final postCountry = payload.newRecord['country'] as String?;
            if (isCountry &&
                (_countryCode == null || postCountry == _countryCode)) {
              _load();
            }
          },
        )
        .subscribe();
  }

  Future<void> refresh() => _load();

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// ─── Replies ──────────────────────────────────────────────────────────────────
final repliesProvider =
    FutureProvider.family<List<Reply>, String>((ref, postId) async {
  final data = await Supabase.instance.client
      .from('replies')
      .select('*, users(anonymous_name, is_rwa_verified)')
      .eq('post_id', postId)
      .order('created_at');
  return (data as List)
      .map((e) => Reply.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── My Posts ─────────────────────────────────────────────────────────────────
final myPostsProvider = FutureProvider<List<Post>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await Supabase.instance.client
      .from('posts')
      .select('*, users(anonymous_name, is_rwa_verified)')
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  return (data as List)
      .map((e) => Post.fromJson(e as Map<String, dynamic>))
      .toList();
});
