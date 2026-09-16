# keti • කෙටි

keti is a Flutter-based research prototype that delivers small, calm health reminders across different screen positions and presentation styles — built to study how design affects compliance without disrupting your flow. Keti means "short" in Sinhalese.

The app ships as **two modes in one codebase**, running on **macOS and Windows**:

- **Participant app** — the study instrument. Silent anonymous sign-in, a participant code entry, and the day protocol (reminders → compliance cards → end-of-day form). All behaviour is recorded to local CSVs and Firestore.
- **Researcher (admin) console** — password-gated admin backend with three tabs:
  - **Participants**: create participants, assign style order, activate Day 2.
  - **Links**: questionnaire links with `{participantId}` / `{day}` placeholders.
  - **Test Mode**: always-on developer test area — trigger compliance cards, pick reminder style (Ambient / Character) and placement (Cursor Proximate / Dynamic Island / Tray), and fire test reminders immediately.

The researcher console is reached either by building with `KETI_ADMIN=true` (dedicated researcher build) or via the **Researcher Access** button pinned bottom-right in the participant app, which opens the console in a second, parallel window.

On Windows the reminder overlays (compliance card, cursor pill, dynamic island, tray pill) are implemented as native Win32 overlay windows in `windows/runner/`.

## Prerequisites

| | macOS | Windows |
|---|---|---|
| Flutter SDK | stable channel (`flutter doctor` clean) | stable channel (`flutter doctor` clean) |
| Toolchain | Xcode (latest) + CocoaPods | Visual Studio 2022 with the **Desktop development with C++** workload |
| Firebase | project `keti-fcfd6` (or your own) | same project — add a Windows app under Project settings → Your apps |

## Firebase setup (local, required before running)

The repo is public, so Firebase client config (API keys) is **not** committed. Set it up locally once:

1. Copy the templates and fill in the real values from the Firebase console (Project settings → Your apps):
   - `lib/firebase_options.dart.example` → `lib/firebase_options.dart` — contains both the `macos` and `windows` option blocks; fill in both (Windows uses the web-style app config: API key, App ID, `authDomain`, `measurementId`).
   - `macos/Runner/GoogleService-Info.plist.example` → `macos/Runner/GoogleService-Info.plist` (macOS only).
2. Optionally keep `.env.local` as your reference record of the same values (`cp .env.local.example .env.local`).

All three target files are gitignored. **Never commit them.**

### Firebase console (one-time, researcher)

1. Enable **Anonymous** sign-in (Authentication → Sign-in method → Anonymous → Enable) — participants sign in silently.
2. Create the researcher account (Authentication → Users → Add user, email/password).
3. Grant the `admin` custom claim (see `tooling/README.md`):

   ```sh
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
     node tooling/set_admin.js researcher@example.com
   ```

4. Deploy the Firestore rules: `firebase deploy --only firestore:rules`.

## Installing dependencies

```sh
flutter pub get
```

## Running

### Participant app

| Platform | Command |
|---|---|
| macOS | `flutter run -d macos` |
| Windows | `flutter run -d windows` |

To produce a standalone debug build to copy onto a study machine:

```sh
flutter build macos --debug    # macOS → build/macos/Build/Products/Debug/keti.app
flutter build windows --debug  # Windows → build/windows/x64/runner/Debug/keti.exe
```

No further setup is needed on the participant machine — participant codes are created by the researcher via the admin console.

### Researcher (admin) console

Standalone admin build (dedicated researcher machine):

```sh
flutter run -d macos --dart-define=KETI_ADMIN=true     # macOS
flutter run -d windows --dart-define=KETI_ADMIN=true   # Windows
```

Sign in with the researcher email/password, then:

1. Set the questionnaire links on the **Links** tab (Google Forms templates with `{participantId}` and `{day}` placeholders).
2. Create participants on the **Participants** tab: enter a serial number (1, 2, 3…), confirm the auto-assigned style order (odd → Ambient Day 1, even → Character Day 1), and optionally override before saving.

Alternatively, from the running participant app, tap **Researcher Access** (bottom-right) — a second instance opens in researcher mode, so participant and researcher run in parallel windows sharing the same Firestore project.

### Local development with the Firebase Emulator Suite

```sh
flutter run -d macos --dart-define=USE_FIRESTORE_EMULATOR=true    # or -d windows
```

Requires the emulators running (`firebase emulators:start --only auth,firestore`). Other build-time flags live in `lib/core/constants/app_config.dart` (`APP_ENV` = `dev` | `pilot` | `study`).

## Day protocol

1. On the participant machine, launch the app (macOS `keti.app` / Windows `keti.exe`).
2. The participant enters their code (e.g. `P014`).
3. They see "Day N" and tap **Start Day N**.
4. The participant works normally for ~2 hours while reminders appear on screen.
   - Each reminder is presentational (it can't be dismissed).
   - After 45 seconds a small card appears at the top-right with a compliance question ("Did you drink some water?" / "Did you take a short break?").
   - Press **Done** or **Not now**; the card auto-dismisses after 15 seconds (recorded as `Ignored`).
   - All behaviour is recorded locally and to Firestore under the hood.
5. When all 8 reminders are finished, the app shows "Day N complete" with a button that opens the end-of-day Google Form.
6. Before Day 2, the researcher opens the admin console, finds the participant, and taps **Activate Day 2**.

## Withdrawal / data deletion

```sh
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
  node tooling/delete_participant.js P014
```
This deletes the participant subtree from Firestore. The participant machine's `keti_data/P014/` folder (CSV copies) must be deleted by the researcher as well.

## Where data lives

| Source | macOS | Windows |
|---|---|---|
| Participant app (device CSVs) | `~/Documents/keti_data/{participantCode}/{dayId}/events.csv` | `%USERPROFILE%\Documents\keti_data\{participantCode}\{dayId}\events.csv` |
| Firestore (authoritative) | `participants/{code}/studySessions/{dayId}/reminderEvents/{eventId}` | same |
| Admin in-app export | `~/Documents/keti_exports/{code}_events.csv` | `%USERPROFILE%\Documents\keti_exports\{code}_events.csv` |
| Fallback script export | `node tooling/export.js` → `*.csv` in any directory | same |

## Packaging / distribution

### macOS — DMG

Build a distributable disk image (`.app` + drag-to-Applications layout):

```sh
tooling/package_macos.sh
# → dist/keti-<version>.dmg
```

Send the `.dmg` to participants. To install: open the DMG, drag **keti** onto
**Applications**, then launch it from Launchpad.

**No Apple Developer ID — ad-hoc signed (the default).** `package_macos.sh`
re-signs the build ad-hoc: it strips the team's development provisioning profile
and signs with `--sign -`. Skipping that step makes the DMG unusable. A plain
`flutter build macos` embeds a *development* profile which only authorises the
Macs registered to the team, and on a free personal team expires every 7 days.
Once it expires macOS refuses to launch the app at all ("Launchd job spawn
failed", POSIX error 163) — on every machine, including the one that built it.

Ad-hoc signing removes the device list and the expiry, but it does **not**
satisfy Gatekeeper, so participants clear the download quarantine flag once
after installing:

1. Open the DMG and drag **keti** to **Applications**.
2. Open Terminal and run:

   ```sh
   xattr -dr com.apple.quarantine /Applications/keti.app
   ```

3. Launch **keti** normally.

If the participant would rather not use Terminal: try to open the app, then go to
**System Settings → Privacy & Security → Security** and click **Open Anyway**.
The older right-click → **Open** shortcut was removed in macOS 15, and the
button only appears for about an hour after a failed launch attempt.

> Transferring the DMG on a **USB stick** and copying it with Finder skips the
> quarantine flag entirely — no Terminal step needed.

Unsigned is fine for a handful of trusted study machines; keep the DMG private.

**Signed + notarized DMG (recommended when participants install themselves).**
Requires an Apple Developer Program membership and a *Developer ID Application*
certificate:

```sh
# one-time: store notarization credentials in the login keychain
xcrun notarytool store-credentials "keti-notary" \
  --apple-id "<you@example.com>" --team-id "HSGB29ANBA" \
  --password "<app-specific-password>"

MACOS_SIGN_IDENTITY="Developer ID Application: <Your Name> (HSGB29ANBA)" \
MACOS_NOTARY_PROFILE="keti-notary" \
tooling/package_macos.sh
```

A notarized DMG opens with a normal double-click, no warnings.

> Note: the release build is sandboxed (`com.apple.security.app-sandbox`), so
> the app's Documents directory resolves inside its container
> (`~/Library/Containers/app.keti.keti/Data/Documents/…`) rather than the real
> `~/Documents`. Verify where `keti_data/` lands on a packaged build.

### Windows — Inno Setup

Sign `keti.exe` with a code-signing certificate (SmartScreen will otherwise warn
on unverified publishers). Packaged with Inno Setup into `/installer/`.

## Tooling

Firestore rules tests, admin-claim setup, and data export/delete scripts live in [`tooling/`](tooling/README.md).