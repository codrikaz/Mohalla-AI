# OpenAI Build Week Development Record

This file separates Mohalla's pre-existing functionality from the work created during OpenAI Build Week 2026.

## Baseline

- Baseline commit: `5ae1c9b`
- Commit message: `pre-build-week baseline`
- Development branch: `openai-build-week`
- Baseline contains the existing Flutter/Supabase Mohalla application.

## New Build Week objective

Create a meaningful AI-assisted posting experience that helps residents communicate neighbourhood information clearly while protecting credentials and limiting cost.

## New user experience

1. The resident writes an informal community message.
2. The resident optionally selects English or Hindi translation.
3. The resident presses **Improve**.
4. The authenticated Flutter app invokes a Supabase Edge Function.
5. The backend checks the user's cache and three-request daily limit.
6. GPT-5.6 Luna returns a structured title, rewritten post, category, and translation.
7. The resident previews the result and explicitly chooses whether to apply it.
8. The resident remains responsible for publishing the post.

## Evidence map

| New work | Files |
|---|---|
| AI suggestion data contract | `lib/models/ai_post_suggestion.dart` |
| Authenticated function client and error handling | `lib/services/ai_post_service.dart` |
| Improve button, language selector, preview, and apply flow | `lib/screens/feed/compose_screen.dart` |
| OpenAI Responses API and structured output | `supabase/functions/ai-post-assistant/index.ts` |
| Daily limit, cache, storage policy, and vote hardening | `supabase/migration_build_week_ai.sql` |
| Focused automated tests | `test/widget_test.dart` |
| Setup and submission documentation | `README.md`, `DEVPOST_SUBMISSION.md` |

## Cost controls

- `gpt-5.6-luna` is used for cost-sensitive generation.
- AI runs only after an explicit button press.
- Input is limited to 500 characters.
- Output is limited and validated with structured JSON.
- Each authenticated user receives three new generations per UTC day.
- Identical user inputs and language choices reuse cached results.
- Failed upstream requests restore the claimed allowance.

## Security decisions

- `OPENAI_API_KEY` is stored as a Supabase Edge Function secret.
- The app sends the current Supabase JWT to the Edge Function.
- The function verifies the user instead of trusting a user ID from the request.
- Cache and usage RLS policies permit users to read only their own rows.
- Only the backend service role writes cached model results.
- Vote counts are recalculated from real vote rows to prevent direct RPC inflation.
- Storage writes are restricted to the authenticated user's folder.

## Human decisions

The product owner selected the neighbourhood problem, target users, location-based experience, supported languages, categories, daily limit, and the decision to require user approval before applying AI output. Codex assisted with implementation, review, tests, and documentation.

## Verification record

Run before the final commit:

```bash
flutter analyze
flutter test
cd android
gradlew.bat assembleDebug
```

Record the final results and commit hash in the Devpost submission before publishing.
