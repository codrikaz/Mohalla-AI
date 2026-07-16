import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/crypto_utils.dart';
import '../core/utils/anon_name.dart';
import '../models/user_profile.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;

  Future<void> sendOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<UserProfile?> verifyOtp({
    required String phone,
    required String otp,
    String? countryCode,
    String? countryName,
  }) async {
    final res = await _client.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );

    if (res.user == null) return null;

    final phoneHash = CryptoUtils.hashPhone(phone);
    final anonName = AnonName.generate(phoneHash); // default urban style

    await _client.from('users').upsert({
      'id': res.user!.id,
      'phone_hash': phoneHash,
      'anonymous_name': anonName,
      'is_rwa_verified': false,
      if (countryCode != null) 'country_code': countryCode,
      if (countryName != null) 'country_name': countryName,
    }, onConflict: 'id');

    return await getProfile(res.user!.id);
  }

  Future<UserProfile?> getProfile(String userId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> updateFcmToken(String userId, String token) async {
    await _client
        .from('users')
        .update({'fcm_token': token}).eq('id', userId);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
