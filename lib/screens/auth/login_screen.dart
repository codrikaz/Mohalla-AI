import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = false;
  bool _isCompletingSignIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (state) {
        if (state.session != null) _completeSignIn();
      },
    );

    if (Supabase.instance.client.auth.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _completeSignIn());
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final launched = await ref.read(authServiceProvider).signInWithGoogle();
      if (!launched && mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Could not open Google sign-in. Please try again.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Google sign-in failed: $error';
      });
    }
  }

  Future<void> _completeSignIn() async {
    if (_isCompletingSignIn) return;
    _isCompletingSignIn = true;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final profile = await ref.read(authServiceProvider).ensureGoogleProfile();
      await ref.read(userProfileProvider.notifier).reload();

      if (!mounted) return;
      if (profile.displayName == null || profile.displayName!.trim().isEmpty) {
        context.go('/name');
      } else {
        context.go('/home');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not finish sign-in: $error';
      });
    } finally {
      _isCompletingSignIn = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 72),
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Mohalla',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Connect with your neighbourhood and stay informed about what is happening nearby.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 44),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _startGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: TextButton.icon(
                onPressed: _isLoading ? null : () => context.push('/phone'),
                icon: const Icon(Icons.phone_outlined, size: 20),
                label: const Text(
                  'Continue with phone number',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.redSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.red, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'Your sign-in details are used only to secure your account. Local posts remain anonymous.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
