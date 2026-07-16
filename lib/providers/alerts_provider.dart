import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/alert.dart';

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AsyncValue<List<Alert>>>(
  (ref) => AlertsNotifier(),
);

class AlertsNotifier extends StateNotifier<AsyncValue<List<Alert>>> {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  AlertsNotifier() : super(const AsyncValue.loading()) {
    _load();
    _subscribeRealtime();
  }

  Future<void> _load() async {
    try {
      final data = await _client
          .from('alerts')
          .select('*, users(anonymous_name)')
          .order('created_at', ascending: false)
          .limit(50);
      final alerts = (data as List)
          .map((e) => Alert.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(alerts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    _channel = _client
        .channel('alerts:all')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alerts',
          callback: (_) => _load(),
        )
        .subscribe();
  }

  Future<bool> sendAlert({
    required String type,
    required String message,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await _client.from('alerts').insert({
        'sent_by': userId,
        'type': type,
        'message': message,
      });
      // Also create a pinned safety post
      await _client.from('posts').insert({
        'user_id': userId,
        'category': 'safety',
        'text': '🚨 ALERT: $message',
        'is_pinned': true,
        'agree_count': 0,
        'disagree_count': 0,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() => _load();

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
