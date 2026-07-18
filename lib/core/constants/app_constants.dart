class AppConstants {
  // ⚠️  Ye dono values SETUP.md padh ke fill karo
  static const String supabaseUrl = 'https://asgwbdlmzmbrwmpgooht.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzZ3diZGxtem1icndtcGdvb2h0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgyNjIxNzcsImV4cCI6MjA5MzgzODE3N30.X5-jw_6anKXZQ6jWeqIXgeLfRKgUhZz--qhKzSqy50A';

  static const int urbanRadiusMeters = 600;
  static const int ruralRadiusMeters = 2000;

  static const int maxPostLength = 500;

  // Keep paid generation off in the public build while API billing is absent.
  static const bool aiAssistantEnabled = false;
  static const double autoHideThreshold = 0.60; // 60% disagree → hide

  static const String appName = 'Mohalla';
}

class PostCategory {
  static const String safety = 'safety';
  static const String info = 'info';
  static const String issue = 'issue';
  static const String krishi = 'krishi';

  static const List<String> urban = [safety, info, issue];
  static const List<String> rural = [safety, info, issue, krishi];

  static String displayName(String cat) {
    switch (cat) {
      case safety:
        return '🚨 Safety';
      case info:
        return '📢 Info';
      case issue:
        return '⚠️ Issue';
      case krishi:
        return '🌾 Agriculture';
      default:
        return cat;
    }
  }

  static String shortName(String cat) {
    switch (cat) {
      case safety:
        return 'Safety';
      case info:
        return 'Info';
      case issue:
        return 'Issue';
      case krishi:
        return 'Agriculture';
      default:
        return cat;
    }
  }
}

class AlertType {
  static const String fire = 'fire';
  static const String theft = 'theft';
  static const String medical = 'medical';
  static const String flood = 'flood';
  static const String bijli = 'bijli';
  static const String other = 'other';
  static const String fasalKharab = 'fasal_kharab';
  static const String janwarAaya = 'janwar_aaya';

  static const List<String> urban = [fire, theft, medical, flood, bijli, other];
  static const List<String> rural = [
    fire,
    theft,
    medical,
    flood,
    bijli,
    fasalKharab,
    janwarAaya,
    other
  ];

  static String displayName(String type) {
    switch (type) {
      case fire:
        return '🔥 Fire';
      case theft:
        return '🥷 Theft';
      case medical:
        return '🏥 Medical emergency';
      case flood:
        return '🌊 Flood';
      case bijli:
        return '⚡ Power outage';
      case fasalKharab:
        return '🌾 Crop damage';
      case janwarAaya:
        return '🐗 Wild animal';
      default:
        return '🚨 Emergency';
    }
  }
}
