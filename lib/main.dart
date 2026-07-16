import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/constants/app_constants.dart';
import 'services/fcm_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // timeago short locale
  timeago.setLocaleMessages('en_short', timeago.EnShortMessages());

  // Firebase + FCM — google-services.json chahiye (SETUP.md dekho)
  try {
    await Firebase.initializeApp();
    await FCMService().init();
  } catch (e) {
    debugPrint('⚠️  Firebase init skipped (add google-services.json): $e');
    // FCM ke bina bhi app chalega — sirf push nahi aayenge
  }

  // Supabase initialize — SETUP.md mein URL + AnonKey fill karo
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: MohallaApp(),
    ),
  );
}
