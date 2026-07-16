# Devpost Submission Package

Use this file as the final copy-and-check checklist. Replace every `TODO` item with a real link or value before pressing Devpost's final Submit button.

## Category

**Apps for Your Life**

## Project name

**Mohalla AI — Hyperlocal Community Alerts**

## Elevator pitch (under 200 characters)

Mohalla AI connects nearby residents through useful local alerts and reports, with AI-powered rewriting, categorization, and Hindi or English translation.

## About the project

### Inspiration

Important neighbourhood information is often scattered across messaging groups and social media. People may not know about safety alerts, local problems, or requests for help close to their location. Mohalla was created to make nearby community communication focused, useful, and privacy-conscious.

### What it does

Mohalla connects residents through a GPS-aware local feed. Users can publish safety alerts, report local problems, request help, share events, attach photos, reply, and vote on posts.

During OpenAI Build Week, Mohalla gained an optional AI Post Assistant. A resident can write an informal message, request English or Hindi translation, and receive a clearer title, rewritten post, and suggested category. The user previews and approves the result before publishing.

### How we built it

The mobile app is built with Flutter and Riverpod. Supabase provides phone authentication, PostgreSQL storage, row-level security, realtime updates, image storage, and the serverless Edge Function. Firebase Cloud Messaging supports notifications.

The Edge Function authenticates the user and calls the OpenAI Responses API with GPT-5.6 Luna. Structured outputs constrain the response to a title, improved text, category, translation, and language. The API key is stored only as a backend secret.

### Challenges we ran into

The main challenges were keeping API credentials out of the APK, controlling cost, making model output predictable, handling multilingual text, and separating existing functionality from Build Week work. The final design uses authenticated backend calls, strict structured output, per-user daily limits, caching, and a preserved baseline commit.

### Accomplishments that we're proud of

Mohalla AI adds assistance without taking control away from residents. AI is optional, the result is previewed, repeated requests are cached, and the user remains responsible for the final post. The feature fits the existing community workflow instead of being a disconnected chatbot.

### What we learned

We learned how Flutter, Supabase Edge Functions, PostgreSQL RLS, and the OpenAI Responses API can form a secure mobile AI architecture. We also learned that visible user control and strict cost limits are essential for a community-facing AI feature.

### What's next

Next steps include server-side geospatial filtering, more Indian languages, duplicate local-issue grouping, stronger moderation, accessibility improvements, and municipal or RWA status workflows.

## Built with tags

```text
Flutter
Dart
Riverpod
Supabase
PostgreSQL
Supabase Edge Functions
OpenAI API
GPT-5.6 Luna
Codex
Firebase Cloud Messaging
Android
Geolocation
```

## Required links

- Repository: https://github.com/codrikaz/Mohalla-AI
- APK or free test build: `TODO_ADD_APK_LINK`
- Public YouTube demo under three minutes: `TODO_ADD_YOUTUBE_LINK`
- Codex `/feedback` session ID: `TODO_ADD_FEEDBACK_SESSION_ID`
- Test account/instructions: `TODO_ADD_PRIVATELY_IN_DEVPOST`

## Three-minute video script

- **0:00–0:20:** Explain that important nearby alerts are lost in noisy messaging groups.
- **0:20–0:45:** Show login, location, and the local feed.
- **0:45–1:10:** Create an informal water, electricity, safety, or road report.
- **1:10–1:40:** Select Hindi or English and press **Improve**.
- **1:40–2:00:** Show the title, category, rewritten post, translation, and Apply action.
- **2:00–2:15:** Repeat the request and show that the cached result does not consume the limit.
- **2:15–2:35:** Show the architecture diagram and explain that the API key stays in Supabase.
- **2:35–2:50:** Show baseline commit versus Build Week files and explain Codex usage.
- **2:50–2:58:** State the community impact and future plan.

Record the real app on a device or emulator. Keep the video public, under three minutes, and include spoken audio explaining both Codex and GPT-5.6 usage.

## Screenshot checklist

1. Local feed with nearby posts
2. Compose screen with Mohalla AI panel
3. AI suggestion preview
4. Hindi or English translation result
5. Published improved post

## Final submission checklist

- [ ] Supabase Build Week migration applied
- [ ] `OPENAI_API_KEY` configured as a Supabase secret
- [ ] Edge Function deployed
- [ ] AI flow tested with the judging account
- [ ] Daily limit and cached response demonstrated
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Release APK signed with a private release key
- [ ] APK uploaded to a judge-accessible link
- [ ] Repository contains the final commits and documentation
- [ ] Three-to-five screenshots uploaded
- [ ] Public YouTube video is under three minutes
- [ ] Controlled test credentials added privately
- [ ] `/feedback` run in the main implementation task
- [ ] Feedback session ID added
- [ ] Every `TODO` in this file replaced
- [ ] Devpost preview checked before final submission
