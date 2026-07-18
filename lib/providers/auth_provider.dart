import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/fcm_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

// Current Supabase auth user stream
final supabaseAuthProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// ─── User Profile ─────────────────────────────────────────────────────────────
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>(
  (ref) => UserProfileNotifier(ref.read(authServiceProvider)),
);

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final AuthService _authService;

  UserProfileNotifier(this._authService) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final profile = await _authService.getProfile(user.id);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reload() => _loadProfile();
  void clear() => state = const AsyncValue.data(null);
}

// ─── Current Location (GPS + reverse geocoded area) ──────────────────────────
final currentLocationProvider =
    StateNotifierProvider<CurrentLocationNotifier, AreaInfo?>(
  (ref) => CurrentLocationNotifier(ref.read(locationServiceProvider)),
);

class CurrentLocationNotifier extends StateNotifier<AreaInfo?> {
  final LocationService _locationService;

  CurrentLocationNotifier(this._locationService) : super(null) {
    _load();
  }

  Future<void> _load() async {
    final info = await _locationService.getAreaInfo();
    if (info != null) state = info;
  }

  Future<void> refresh() => _load();
}

// ─── Auth Flow ────────────────────────────────────────────────────────────────
final authFlowProvider = StateNotifierProvider<AuthFlowNotifier, AuthFlowState>(
  (ref) => AuthFlowNotifier(ref),
);

class AuthFlowState {
  final bool isLoading;
  final String? error;
  final String? pendingPhone;
  final String? pendingCountryCode;
  final String? pendingCountryName;

  const AuthFlowState({
    this.isLoading = false,
    this.error,
    this.pendingPhone,
    this.pendingCountryCode,
    this.pendingCountryName,
  });

  AuthFlowState copyWith({
    bool? isLoading,
    String? error,
    String? pendingPhone,
    String? pendingCountryCode,
    String? pendingCountryName,
  }) =>
      AuthFlowState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        pendingPhone: pendingPhone ?? this.pendingPhone,
        pendingCountryCode: pendingCountryCode ?? this.pendingCountryCode,
        pendingCountryName: pendingCountryName ?? this.pendingCountryName,
      );
}

class AuthFlowNotifier extends StateNotifier<AuthFlowState> {
  final Ref _ref;

  AuthFlowNotifier(this._ref) : super(const AuthFlowState());

  Future<bool> sendOtp(
    String phone, {
    String countryCode = 'IN',
    String countryName = 'India',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _ref.read(authServiceProvider).sendOtp(phone);
      state = AuthFlowState(
        pendingPhone: phone,
        pendingCountryCode: countryCode,
        pendingCountryName: countryName,
      );
      return true;
    } catch (e) {
      state = AuthFlowState(error: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp({required String otp}) async {
    if (state.pendingPhone == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _ref.read(authServiceProvider).verifyOtp(
            phone: state.pendingPhone!,
            otp: otp,
            countryCode: state.pendingCountryCode,
            countryName: state.pendingCountryName,
          );
      if (profile != null) {
        final token = await FCMService().getToken();
        if (token != null) {
          await _ref
              .read(authServiceProvider)
              .updateFcmToken(profile.id, token);
        }
        await _ref.read(userProfileProvider.notifier).reload();
        state = const AuthFlowState();
        return true;
      }
      state = AuthFlowState(error: 'The OTP is incorrect. Please try again.');
      return false;
    } catch (e) {
      state = AuthFlowState(
        pendingPhone: state.pendingPhone,
        pendingCountryCode: state.pendingCountryCode,
        pendingCountryName: state.pendingCountryName,
        error: 'OTP verification failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _ref.read(authServiceProvider).signOut();
    _ref.read(userProfileProvider.notifier).clear();
    state = const AuthFlowState();
  }
}
