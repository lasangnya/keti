# keti • කෙටි
keti is a Flutter-based research prototype that delivers small, calm health reminders across different screen positions and presentation styles — built to study how design affects compliance without disrupting your flow. Keti means "short" in Sinhalese.

## Firebase setup (local, required before running)

The repo is public, so Firebase client config (API keys) is **not** committed. Set it up locally once:

1. Copy the templates and fill in the real values from the Firebase console (Project `keti-fcfd6` → Project settings → Your apps):
   - `lib/firebase_options.dart.example` → `lib/firebase_options.dart`
   - `macos/Runner/GoogleService-Info.plist.example` → `macos/Runner/GoogleService-Info.plist`
2. Optionally keep `.env.local` as your reference record of the same values (`cp .env.local.example .env.local`).

All three target files are gitignored. **Never commit them.**
