# Mohalla — Setup Guide
> Sirf tumhari colony ke log. Anonymous. Safe. Real.

---

## ⚡ App setup

### Step 1 — Supabase Setup (10 minutes)

1. **Account banao** → https://supabase.com (free hai)

2. **New Project** → Name: `mohalla`, Region: South Asia (Mumbai)

3. **SQL Editor** → `supabase/schema.sql` ka poora content paste karo → Run karo
   - Core app tables ban jayengi
   - RLS policies set ho jayengi
   - GPS-based feed schema aur RLS policies configure ho jayengi

4. **Phone Auth enable karo**
   - Supabase Dashboard → Authentication → Providers → Phone → Enable
   - Twilio account chahiye SMS ke liye (trial free hai: https://twilio.com)
   - Twilio mein: Account SID, Auth Token, Phone Number lao
   - Supabase mein fill karo

5. **Storage bucket banao** (post photos ke liye)
   - Supabase → Storage → New Bucket → Name: `post-images` → Public: ON

6. **Keys copy karo**
   - Supabase → Settings → API
   - `Project URL` copy karo
   - `anon public` key copy karo

7. **Fill karo** → `lib/core/constants/app_constants.dart`
   ```dart
   static const String supabaseUrl = 'https://xxxxx.supabase.co';  // tumhara URL
   static const String supabaseAnonKey = 'eyJhbGci...';            // tumhara anon key
   ```

---

### Step 2 — Firebase Setup (10 minutes)

> ⚠️ Firebase sirf push notifications ke liye hai. Bina iske bhi app chalega — sirf alerts phone par nahi aayenge jab app band ho.

1. **Firebase Console** → https://console.firebase.google.com
   - New Project → Name: `mohalla`

2. **Android app add karo**
   - Package name: `com.codrikaz.mohalla`
   - App nickname: Mohalla
   - `google-services.json` download karo

3. **File rakho** → `android/app/google-services.json`

4. **Cloud Messaging enable karo**
   - Firebase Console → Project Settings → Cloud Messaging → Enable

---

## ✨ Mohalla AI Setup (Build Week)

1. Supabase SQL Editor mein `supabase/migration_build_week_ai.sql` run karo.
2. OpenAI key ko Flutter ya GitHub mein mat rakho. Supabase secret banao:

```bash
supabase secrets set OPENAI_API_KEY=YOUR_OPENAI_API_KEY
```

3. Edge Function deploy karo:

```bash
supabase functions deploy ai-post-assistant
```

AI assistant sirf signed-in users ke liye hai. Har user ko UTC day mein 3
new generations milti hain. Same input ka cached result limit use nahi karta.

---

## 📱 App Run Karo

```bash
# Dependencies install karo
flutter pub get

# Android phone USB se connect karo (USB Debugging on karo)
flutter run

# Release APK banao
flutter build apk --release
# APK milega: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔑 RWA / Colony Leader Verify Karo

Kisi ko "Verified" badge dene ke liye (sirf tum karo — admin):

```sql
-- Supabase SQL Editor mein run karo
update public.users
set is_rwa_verified = true
where id = 'user-ka-uuid-yahan';
```

User ka UUID: Supabase → Authentication → Users → user dhundho

---

## 💰 Revenue Setup

### Razorpay (payments ke liye — Phase 2)
1. https://razorpay.com → Account banao
2. Test mode mein start karo
3. Keys `app_constants.dart` mein add karo (jab implement karo)

### Local Shop Ads
- Manually Supabase dashboard se sponsored posts add karo
- `is_pinned: true` flag lagao — feed mein top par aayegi

---

## 📁 Project Structure

```
lib/
  core/
    constants/    → app_constants.dart  ← SUPABASE KEYS YAHAN
    theme/        → colors, fonts
    utils/        → SHA-256, Haversine, AnonName
  models/         → Colony, Post, User, Reply, Alert
  services/       → Auth, Location, FCM
  providers/      → Riverpod state management
  screens/
    auth/         → Phone → OTP → Colony Detect
    feed/         → Feed, Compose, Post Detail
    alerts/       → Emergency alerts
    profile/      → User profile, my posts
  widgets/        → PostCard, VoteButtons, CategoryBar
  app.dart        → Routes (go_router)
  main.dart       → Entry point

supabase/
  schema.sql      → Database tables + RLS + RPC

android/
  app/
    google-services.json  ← FIREBASE FILE YAHAN (add karna hai)
```

---

## ❓ Common Issues

**"Location nahi mila"**
→ Phone mein GPS on karo, app ko location permission do

**"Colony nahi mili"**
→ Supabase mein colony add karo with correct lat/lng

**"OTP nahi aaya"**
→ Supabase mein Twilio configure karo

**"Supabase error"**
→ `app_constants.dart` mein URL aur AnonKey check karo

---

## 🚀 Mohalla — Kya hai ye app?

> **Bina government ke, bina police ke, bina kisi authority ke** — sirf tumhari colony ke verified neighbours ek doosre se baat kar sakte hain. Anonymously. Safely.
>
> WhatsApp group mein spam hai, number expose hota hai, koi bhi join kar sakta hai.
> Mohalla mein sirf wo log jo GPS se verified hain ki woh actually wahan rehte hain.

**Core value:**
- ✅ Anonymous — asli naam kisi ko nahi pata
- ✅ Verified local — sirf asli neighbours
- ✅ No spam — vote system se bad posts hide
- ✅ Real-time — koi event ho toh turant pata chale
- ✅ Emergency — ek tap mein poori colony alert
