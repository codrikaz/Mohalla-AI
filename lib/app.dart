import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/phone_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/name_screen.dart';
import 'screens/auth/location_screen.dart';
import 'screens/home_screen.dart';
import 'screens/feed/compose_screen.dart';
import 'screens/feed/post_detail_screen.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authService.isLoggedIn;
      final path = state.uri.path;

      // Splash, phone, otp, name, colony-detect — ye sab always allow
      if (path == '/' || path == '/phone' || path == '/otp' ||
          path == '/name' || path == '/colony-detect') {
        return null;
      }

      // Not logged in → phone
      if (!isLoggedIn) return '/phone';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/phone',
        builder: (_, __) => const PhoneScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (_, __) => const OtpScreen(),
      ),
      GoRoute(
        path: '/name',
        builder: (_, __) => const NameScreen(),
      ),
      GoRoute(
        path: '/colony-detect',
        builder: (_, __) => const LocationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/compose',
        builder: (_, __) => const ComposeScreen(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (_, state) => PostDetailScreen(
          postId: state.pathParameters['id']!,
        ),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Page nahi mila: ${state.error}'),
      ),
    ),
  );
});

class MohallaApp extends ConsumerWidget {
  const MohallaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'Mohalla',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
