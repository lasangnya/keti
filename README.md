# keti • කෙටි
keti is a Flutter-based research prototype that delivers small, calm health reminders across different screen positions and presentation styles — built to study how design affects compliance without disrupting your flow. Keti means "short" in Sinhalese.

## Firebase setup (local, required before running)

The repo is public, so Firebase client config (API keys) is **not** committed. Set it up locally once:

1. Copy the templates and fill in the real values from the Firebase console (Project `keti-fcfd6` → Project settings → Your apps):
   - `lib/firebase_options.dart.example` → `lib/firebase_options.dart`
   - `macos/Runner/GoogleService-Info.plist.example` → `macos/Runner/GoogleService-Info.plist`
2. Optionally keep `.env.local` as your reference record of the same values (`cp .env.local.example .env.local`).

All three target files are gitignored. **Never commit them.**

## Runbook — study sessions

### Machine setup (one-time per study machine)

```sh
# 1. Build the participant app (macOS)
flutter build macos --debug

# 2. Ensure anonymous sign-in is enabled in the Firebase console
#    (Authentication → Sign-in method → Anonymous → Enable).
# 3. The app needs no further setup — participant codes are created
#    by the researcher via the admin mode.
```

### Researcher setup (one-time)

1. Run the admin build: `flutter run -d macos --dart-define=KETI_ADMIN=true`
2. Sign in with the researcher email you created in Firebase Auth (email/password user).
3. Set the questionnaire links on the **Links** tab (Google Forms templates with `{participantId}` and `{day}` placeholders).
4. Create participants on the **Participants** tab: enter a serial number (1, 2, 3…), confirm the auto-assigned style order (odd → Ambient Day 1, even → Character Day 1), and optionally override before saving.

### Day protocol

1. On the participant machine, launch `keti.app`.
2. The participant enters their code (e.g. `P014`).
3. They see "Day N" and tap **Start Day N**.
4. The participant works normally for ~2 hours while reminders appear on screen.
   - Each reminder is presentational (it can't be dismissed).
   - After 45 seconds a small card appears at the top-right with a compliance question ("Did you drink some water?" / "Did you take a short break?").
   - Press **Done** or **Not now**; the card times out after 2 minutes automatically.
   - All behaviour is recorded locally and to Firestore under the hood.
5. When all 8 reminders are finished, the app shows "Day N complete" with a button that opens the end-of-day Google Form.
6. Before Day 2, the researcher opens the admin app, finds the participant, and taps **Activate Day 2**.

### Withdrawal / data deletion

```sh
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
  node tooling/delete_participant.js P014
```
This deletes the participant subtree from Firestore. The participant machine's `keti_data/P014/` folder (CSV copies) must be deleted by the researcher.

### Where data lives

| Source | Location |
|---|---|
| Participant app (device CSVs) | `~/Documents/keti_data/{participantCode}/{dayId}/events.csv` |
| Firestore (authoritative) | `participants/{code}/studySessions/{dayId}/reminderEvents/{eventId}` |
| Admin in-app export | `~/Documents/keti_exports/{code}_events.csv` |
| Fallback script export | `node tooling/export.js` → `*.csv` in any directory |
