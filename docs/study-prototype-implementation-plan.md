# keti — Study Prototype: Codebase Analysis & Implementation Plan

**Date:** 2026-07-28 (v3 — local CSV storage + in-app admin CSV export)
**Scope:** Turn the current reminder test mode into the final 3 × 2 within-subjects research-study prototype (Flutter/Dart + Firebase/Cloud Firestore, macOS desktop).
**Status:** Plan only — no implementation yet. Verified findings are cited with file paths, class names, and method names; anything that could not be confirmed from the codebase is explicitly flagged.

**Revision history**
- **v2:** ID-entry participant flow (no login); compliance moved to a uniform top-right card shown after each reminder; admin mode for participants/day-activation/schedules/questionnaire-links; day-completion UX with questionnaire buttons; Firestore-driven schedules.
- **v3 (this revision):** local on-device storage changed from JSONL journal to **CSV files** (per-session state CSV + append-only log CSV), synced to Firestore under the hood — a local database is documented as the alternative (§6.4, §10.11). **Admin mode can download per-participant CSVs generated from Firestore** directly in the app (§6.6, §7.4).

---

## 1. Current-state assessment

### 1.1 Verified repository findings

**Toolchain & platforms**
- Flutter **3.44.1 stable**, Dart **3.12.1** (`flutter --version`; `pubspec.yaml:22` → `sdk: ^3.12.1`).
- Desktop-only project: `macos/`, `windows/`, `linux/` exist; **no `ios/`, `android/`, or `web/`** directories. `.metadata` confirms platforms: linux, macos, windows.
- Dependencies (`pubspec.yaml:30-47`): `flutter_riverpod ^3.3.2` + `riverpod_annotation ^4.0.3` (codegen via `build_runner`), `google_fonts ^8.1.0`, `flutter_svg ^2.3.0`, `firebase_core ^4.12.1`, `cupertino_icons`. **Verified absent from `pubspec.lock`: `cloud_firestore`, `firebase_auth`, `shared_preferences`, `url_launcher`, `csv`** — no database, no auth, no local persistence, no external-link or CSV support today.

**Firebase setup**
- Project `keti-fcfd6`, configured for **macOS and Windows only** (`lib/firebase_options.dart:36-44`; Linux throws `UnsupportedError`). The Windows options are a *web* app config (`appId …:web:…`).
- `firebase.json` contains only FlutterFire platform config — **no Firestore rules file, no indexes file, no `.firebaserc`**.
- `macos/Runner/GoogleService-Info.plist` exists but is **untracked in git**, as are `firebase.json` and `lib/firebase_options.dart` (`git status`); `lib/main.dart` and `pubspec.yaml` have uncommitted modifications. Firebase integration is uncommitted WIP on top of commit `d43438e`.
- `main.dart:13-15` initializes only `Firebase.initializeApp(...)`. No other Firebase service is referenced anywhere in `lib/`.
- **Build risk (verified):** `macos/Runner/DebugProfile.entitlements` has `app-sandbox=true` + `network.server` but **not `network.client`**; `Release.entitlements` has only `app-sandbox`. With App Sandbox on and no `com.apple.security.network.client`, outbound HTTPS (Firestore/Auth) will fail at runtime on macOS.

**Architecture & state management**
- `lib/` layout: `application/` (Riverpod providers + `.g.dart` codegen), `core/` (constants, services, theme), `domain/` (`reminder_content.dart`), `presentation/` (pages, widgets).
- State: **Riverpod 3 with `@riverpod` codegen** (`reminder_manager.dart:9-10`, `theme_provider.dart:9-10`, etc.).
- Navigation: **no router**. `home_page.dart` renders a `NavigationRail` whose index lives in `navigation_provider.dart` (`Navigation` notifier, `_items` list of 4 pages). Page switch = index change; no routes/URLs.
- Pages: `DashboardPage`, `BreaksPage`, `HydrationPage` are **placeholder `Text('… Content')` stubs** (each ~18 lines). `TestModePage` is the only functional page.
- `main.dart:30,41-46`: a **global `HardwareKeyboard` handler logs every key name** (`event.logicalKey.debugName`) into `userActivityProvider`; a `Listener` logs pointer move/click/scroll. `user_activity_provider.dart` tracks idle state (1 s threshold) and `print`s totals. Nothing is persisted. (Privacy-relevant: key-name capture must never reach Firestore.)

**How the current "press button → show reminder" test mode works**
1. `test_mode_page.dart`: toggle `isActive`, pick style (`ambient`/`character`), then 3 placement cards (Cursor / Dynamic Island / Tray) each with 2 buttons (Break / Hydration).
2. Buttons call `TestMode.getBreakContent()` / `getHydrationContent()` (`test_mode_provider.dart:55-132`), which build a `ReminderContent` (message, per-placement asset resource name, width/height/offsets, `totalFrames`).
3. Content + `ReminderLocation` are wrapped in `ReminderRequest` and passed to `ReminderManager.enqueue()` (`reminder_manager.dart:21-26`).
4. `ReminderManager._processQueue()` dispatches to `CursorPillService.showPill`, `NotchHookService.showIsland`, or `TrayPillService.showPill` via `MethodChannel`s (`platform_channels.dart`), then **waits `totalFrames/25fps + 800ms`** before dequeuing the next item. Errors are `print`ed and swallowed (`reminder_manager.dart:56-57`).
5. Native side (`macos/Runner/MainFlutterWindow.swift`) registers the 4 channels and calls `CursorPillManager` / `IslandManager` / `TrayPillManager` / `ComplianceCardManager`.

**Placement implementations (macOS native, verified)**
- **Cursor proximate** — `CursorPillManager.swift`: borderless non-activating `NSPanel` at `mainMenu+1` level, **follows the cursor at 60 fps**, plays the PNG sequence once, auto-exits. `panel.ignoresMouseEvents = true` → already non-interactive, which matches the v2 design (no changes needed for click-through).
- **Top-center notch card** — `IslandManager.swift` + `IslandView.swift`: top-center panel, plays frames once, has a **"Dismiss" button** (must be removed for the uniform study build), auto-dismisses at sequence end.
- **System tray** — `TrayPillManager.swift` + `TrayCardView.swift`: `NSStatusItem` + a capsule card dropped beneath it. **The card renders only the animation image; the `message` string is passed but never displayed** (`TrayCardView.swift:13-26` shows only `Image`).
- **Compliance card** — `ComplianceCardManager.swift` + `ComplianceCardView.swift`: a tray-anchored card with title + **two buttons**, 5 s auto-dismiss, reporting `onButtonClicked` → Dart (`compliance_card_service.dart` prints the label). **This is the direct predecessor of the v2 compliance card** — it must be generalized: anchored top-right of screen (not to the tray), no 5 s auto-dismiss, parameterized question/buttons/timeout, callbacks keyed by reminderId.

**Assets & presentation styles** (`macos/Runner/Assets.xcassets`)
- Exactly 6 frame sequences exist: `ambient_break_cursor_pill`, `ambient_break_notch_card`, `ambient_hydration_cursor_pill`, `ambient_hydration_notch_card`, `character_break_cursor_pill`, `character_hydration_cursor_pill`.
- Consequences, verified in `test_mode_provider.dart`: ambient has distinct notch assets; **tray always reuses cursor assets**; **character style reuses `character_*_cursor_pill` for all three placements** (lines 62-64, 103-105) — there are no character notch/tray assets.
- Display duration is animation-driven: ambient = 100 frames @25fps ≈ **4 s**, character = 250 frames ≈ **10 s** — far below the required 30–60 s visibility.

**Persistence, lifecycle, error handling, tests**
- Persistence: none. Queue is in-memory; app restart loses everything.
- Lifecycle: `AppDelegate.swift:12-14` → `applicationShouldTerminateAfterLastWindowClosed = true` (**closing the window quits the app** — a live risk for 2-hour sessions). No sleep/wake, backgrounding, or App Nap handling anywhere.
- Error handling: `on PlatformException → print` in all 4 services. Note: `MissingPluginException` (thrown on Windows/Linux where no native handlers exist — both runners are **stock templates**) is **not** a `PlatformException`, so services don't catch it; only `ReminderManager`'s generic `catch (e)` does.
- Tests: `test/widget_test.dart` is the **stale template counter test** (expects `find.text('0')`) — it fails against the current app. That is the entire test coverage.
- Hygiene: `print()` used throughout (against `flutter_lints` defaults); `.idea/` churn and `.DS_Store` untracked; `design/` directory is empty; `google_fonts` (`theme_provider.dart:23`, `GoogleFonts.geistTextTheme()`) fetches fonts from Google's CDN at runtime by default — offline fragility **and** a GDPR-adjacent IP-leak concern for a German study.

### 1.2 What already works
- End-to-end demo path on macOS: test-mode button → Riverpod queue → native animated reminder at all three placements, in both styles.
- Native rendering primitives for all three placements, plus a working two-button **compliance card** (`ComplianceCardManager/View`) that the plan generalizes into the uniform measurement instrument.
- A clean Riverpod + layered folder structure that new study code can slot into without a rewrite.
- Firebase Core initialized; asset pipeline (6 animation sequences) bundled in the macOS asset catalog.

### 1.3 Gaps vs. the study protocol (v3)
No scheduling engine, no Firestore-driven per-participant schedules, no participant ID-entry flow, no admin mode (participants/day activation/schedules/links/CSV export), no day-completion + questionnaire-link UX, no uniform compliance card at top-right, no counterbalancing storage, no Firestore event logging, no local persistence (CSV or DB) or sync, no 30–60 s visibility control, no failure/suppression capture, no environment separation, no usable tests, entitlements blocking network, Windows/Linux native layers absent.

### 1.4 Cannot be confirmed from the codebase
Whether Firestore/Auth are enabled in the Firebase console or which region the project uses; whether the app has ever run on Windows; the intended look of character-style notch/tray assets (`design/` is empty); the macOS deployment target and signing setup for participant machines; the contents/purpose of `.artifacts/` and `.omo/run-continuation/`.

---

## 2. Study requirements matrix

| Study requirement | Prototype feature | Priority | Affected code area | Acceptance criteria |
|---|---|---|---|---|
| ID-entry day start, no login | Home screen = participant ID field; anonymous auth happens invisibly at launch | P0 | new `presentation/pages/study/id_entry_page.dart`, `firebase_auth` | Entering `P014` loads participant + schedule from Firestore; no other credential ever requested |
| Firestore-driven per-participant schedule | Admin-written schedule doc fetched on ID entry, cached locally, snapshotted into the session | P0 | `schedules` docs, schedule repository, scheduler | Editing a schedule in admin → next ID entry runs the new times/placements |
| 8 reminders/day at configured offsets from session start | Deterministic `StudyScheduler` anchored to `sessionStartedAt` | P0 | new `application/study/scheduler.dart` | Unit test: fire times = T+offset ±1 s with fake clock |
| Timing survives sleep/backgrounding/accidental quit | 1 s tick + catch-up (deliver if ≤120 s late, else `suppressed(late)`); session-aware app termination; resume from local CSV store | P0 | scheduler, `AppDelegate.swift`, `csv_store.dart` | Kill app at 00:25 → relaunch resumes original clock; missed reminder logged `notDisplayed`, none duplicated |
| 3 placements × 2 styles per participant-day | Native managers render schedule rows in day's assigned style | P0 | `CursorPillManager`, `IslandManager/View`, `TrayPillManager/TrayCardView`, content resolver | Manual QA: all 8 reminders match schedule row + style |
| Uniform compliance card (top-right, same all study) | Generalized `ComplianceCardManager`: top-right anchor, per-kind question, 2 outcome buttons, appears at reminder window end | P0 | `ComplianceCard*`, `compliance_card_service.dart` | Card is pixel-identical across placements/styles; appears after every reminder window; outcomes recorded |
| 30–60 s reminder visibility | `visibilityMs` protocol constant (default 45 s), decoupled from animation length; reminders non-interactive | P0 | native managers, `app_config.dart` | Reminder persists exactly `visibilityMs` (animation holds final frame); no Dismiss button on any placement |
| Counterbalanced style order, stable | `styleOrder` on participant doc (serial parity default, admin-overridable at creation); immutable for clients | P0 | admin mode, `participants` collection, rules | Restart/reinstall/ID re-entry → same order; client write to `styleOrder` rejected (emulator test) |
| Day activation by researcher | `activeDay` field, admin-only writable; client may only start the active day | P0 | admin mode, rules | Day 2 cannot be started before activation (emulator test); activation instantly visible to participant app on next fetch |
| Day completion + questionnaire buttons | Completion screen; "Complete end of day questionnaire" (day-specific link), final questionnaire after Day 2 | P0 | study pages, `url_launcher`, config links | Button opens configured Google Form with `{participantId}`/`{day}` substituted |
| Admin-configurable links | `config/study` doc: start / day1-end / day2-end / final URL templates | P1 | admin mode, config repository | Link edit in admin → participant app uses new URL on next fetch |
| One event record per reminder exposure, **local CSV + Firestore** | Per-session CSV pair on device (state + append-only log) + Firestore doc per reminder, written CSV-first, synced immediately when online | P0 | `csv_store.dart`, `sync_service.dart`, event repository | Airplane-mode session → 0 events lost after reconnect; local `events.csv` contains the same 8 rows as Firestore |
| **Admin CSV download** | In-app export: per-participant CSVs (and all-participants batch) generated from Firestore, saved to a local export folder | P0 | admin mode, `admin_export_service.dart` | Researcher clicks "Download CSV" for P014 → valid `events.csv`/`sessions.csv`/`participant.csv` open in Excel/R/SPSS with all rows |
| Core data fields (researcher's list) | participant ID, date/time, reminder number, placement, style, delivered/suppressed/failed, completed/dismissed | P0 | event model + schema | All 7 present in every exported row (mapping table §7.5) |
| Failure recording | `deliveryStatus` + `failureReason`/`suppressionReason` on every path (channel error, app quit, late, inactive) | P0 | orchestrator, repositories | Simulated channel failure → `failed` event, no crash |
| Test mode preserved, separated | `APP_ENV` gating; test triggers local-CSV-only, never Firestore | P1 | `main.dart`, navigation, test_mode_page | `study` build shows no test UI; test runs produce no Firestore docs |
| No questionnaire/rating UI in app | Only external-link buttons | P0 | — | Verified by inspection |

---

## 3. Participant and researcher flow

### 3.1 Researcher flow (admin mode)
1. Opens the app in **admin mode** on their own machine (options in §6.6; recommended: same app, `--dart-define=KETI_ADMIN=true`, researcher email sign-in).
2. **Creates participant**: enters serial → app proposes code `P014` and auto-assigns style order by parity (odd → Ambient-first, even → Character-first); researcher can override before saving. This writes the participant doc + per-day schedule docs (copied from the default template) to Firestore.
3. **Configures questionnaire links** once per study (start, Day-1 end, Day-2 end, final) in a settings form; stored in `config/study` with `{participantId}` / `{day}` placeholders.
4. Optionally **edits a participant's schedule** (8 rows: time offset, placement; style comes from the order) — default template covers the standard protocol.
5. After Day 1 is complete, clicks **"Activate Day 2"** for that participant. (`activeDay` is admin-only writable; the participant app reads it on next ID entry.)
6. Monitors progress: per participant, sees Day 1/Day 2 status and event counts (read-only, derived from session docs).
7. **Downloads CSVs directly in admin mode**: a "Download CSV" action per participant (plus "Export all") reads that participant's Firestore data and writes flattened CSV files (participant / sessions / reminder events) to the local export folder (§7.4) — no scripts needed for routine export. The Admin SDK script remains as a fallback/bulk option.

### 3.2 Participant flow — Day 1
1. App launches → invisible anonymous sign-in → **ID entry screen** (last used ID pre-filled from local storage).
2. Participant types ID (e.g., `P014`) → app fetches participant doc + `config/study` + Day-1 schedule doc; caches all locally.
3. App validates: participant exists, `activeDay == 1`, Day 1 not already completed. Shows the **day screen**: "Day 1", a Start button, and (if configured) a "Pre-study questionnaire" button opening the start link. Condition names are **not** displayed (§10.8).
4. Start → session doc created (server timestamp + **schedule snapshot** + link snapshot), 8 event records initialized as `scheduled` (Firestore docs + local CSV rows), scheduler starts. The participant works naturally; keti stays open.
5. Each reminder: shown at its offset in the day's style for `visibilityMs` (45 s) → auto-dismisses → **compliance card appears top-right** with the kind-appropriate question and two buttons → outcome (`completed`/`dismissed`/`timedOut`) + latencies recorded to the local CSVs and to Firestore under the hood.
6. After reminder 8 finalizes → session status `completed` → **"Day 1 complete"** screen with **"Complete end of day questionnaire"** button (opens Day-1 end link with placeholders substituted). App returns to ID entry.

### 3.3 Participant flow — Day 2
Identical, except: entry validates `activeDay == 2`, style is the other one per `styleOrder`, and the completion screen shows both the Day-2 end link and the **final questionnaire** link.

### 3.4 Resume/restart behavior
If the app quits mid-session (crash, reboot, accidental window close — window close does **not** quit during an active session, §6.5): on relaunch, the ID-entry screen detects an unfinished session for that ID from the local CSV store and offers **Resume**. The scheduler re-anchors to the **original** `sessionStartedAt` (restored from the CSV/session snapshot); reminders ≤120 s past due are delivered immediately (lateness logged); older ones become `notDisplayed(app_terminated)`. Deterministic event IDs make re-writes idempotent; `resumedCount` increments; events carry `sessionResumed: true`. Restarting a day from zero is **not** offered; voiding a session is an admin-script action (`status: voided`), never a client action.

### 3.5 Google Forms
No integration. Admin stores URL **templates** (e.g., `…/viewform?usp=pp_url&entry.111={participantId}&entry.222={day}`); the app substitutes placeholders and opens the browser via `url_launcher`. Questionnaire answers live in Google Forms, keyed by the same participant code + day. Whether a participant actually submitted is **not** tracked by the app.

---

## 4. Condition assignment strategy

**Default method — serial parity, admin-executed.** When the researcher creates a participant in admin mode, the serial's parity assigns the order: **odd → Ambient Day 1 / Character Day 2; even → Character Day 1 / Ambient Day 2**. Reproducible by anyone from the code alone, exactly half/half when serials are issued sequentially, zero randomness or server state. The researcher sees the computed order before confirming and may override it at creation time (recorded as `assignmentOverride: true`).

**Storage & immutability:** `styleOrder` lives on `participants/{code}`, written once by admin. Firestore rules deny *all* client writes to the participant doc (§8) — only the admin account can touch it, and the admin UI refuses order changes after Day 1 has started (soft lock; a hard override remains possible via admin script for emergencies, with a runbook note that such participants must be flagged in analysis). Restart, reinstall, or re-entering the ID can never change the order: it is read from Firestore on every ID entry and cached locally for offline continuity.

**Pilot/test override:** in `dev`/`pilot` environments the admin form always allows overriding, and docs are stamped `environment: "pilot"` so pilot data filters out at analysis.

---

## 5. Reminder scheduling and UI design

### 5.1 Domain models (new, `lib/domain/study/`)

```dart
enum Placement { cursorProximate, notchCard, systemTray }
enum PresentationStyle { ambient, characterBased }
enum ReminderKind { hydration, microBreak }
enum DeliveryStatus { scheduled, delivered, suppressed, failed, notDisplayed }
enum ResponseOutcome { none, completed, dismissed, timedOut }
enum StyleOrder { ambientFirst, characterFirst }

class ScheduledReminder {            // one row of a participant-day schedule doc
  final int reminderNumber;          // 1–8
  final Duration offset;             // from session start
  final Placement placement;
  final ReminderKind kind;
  final int variantNumber;           // Hydration 1..5, Micro break 1..3
  String get contentVariantId;       // "hydration_1", "micro_break_2", …
}

class DaySchedule {                  // fetched from Firestore, snapshotted into session
  final int dayNumber;
  final PresentationStyle style;     // derived from styleOrder + dayNumber at snapshot time
  final List<ScheduledReminder> reminders; // exactly 8
}

class ReminderEvent {                // one Firestore doc + one CSV row
  final String participantId, dayId;
  final int dayNumber, reminderNumber;
  // schedule
  final Duration scheduledOffset;
  final DateTime scheduledAtLocal;
  // reminder display
  final DateTime? reminderShownAtLocal, reminderHiddenAtLocal;
  // compliance card
  final DateTime? cardShownAtLocal, answeredAtLocal;
  final ResponseOutcome outcome;
  final int? responseLatencyMs;      // answeredAt − cardShownAt
  // condition + audit
  final Placement placement; final PresentationStyle style;
  final ReminderKind kind; final String contentVariantId;
  final DeliveryStatus deliveryStatus;
  final String? failureReason, suppressionReason;
  final bool usedFallback, sessionResumed;
  final String appVersion, protocolVersion, environment;
}
```

The **default schedule template** (what admin copies to each new participant; identical both days, style resolved per day):

```dart
const kDefaultScheduleTemplate = [
  ScheduledReminder(1, Duration(minutes: 20), Placement.cursorProximate, ReminderKind.hydration, 1),
  ScheduledReminder(2, Duration(minutes: 30), Placement.notchCard,       ReminderKind.microBreak, 1),
  ScheduledReminder(3, Duration(minutes: 40), Placement.systemTray,      ReminderKind.hydration, 2),
  ScheduledReminder(4, Duration(minutes: 60), Placement.cursorProximate, ReminderKind.microBreak, 2),
  ScheduledReminder(5, Duration(minutes: 65), Placement.notchCard,       ReminderKind.hydration, 3),
  ScheduledReminder(6, Duration(minutes: 80), Placement.cursorProximate, ReminderKind.hydration, 4),
  ScheduledReminder(7, Duration(minutes: 90), Placement.systemTray,      ReminderKind.microBreak, 3),
  ScheduledReminder(8, Duration(minutes: 100), Placement.systemTray,     ReminderKind.hydration, 5),
];
```

### 5.2 Timing chain per reminder
```
sessionStartedAt + offset
  → reminder shown (placement, style)          [deliveryStatus: delivered, reminderShownAt]
  → visible exactly visibilityMs (default 45 s) [reminderHiddenAt]
  → compliance card shown top-right            [cardShownAt]
  → button press                               [outcome: completed|dismissed, answeredAt, responseLatencyMs]
     OR card timeout (default 120 s)           [outcome: timedOut]
  → event finalized (CSV + Firestore)
```
- Scheduler = single 1 s tick comparing `DateTime.now()` to absolute fire times (no accumulated durations → immune to drift/throttling). Late >120 s → `suppressed(late_delivery)`. Tick gap >120 s (sleep/lock) → `suppressed(device_inactive)`. App Nap disabled during sessions via `ProcessInfo.beginActivity(.userInitiated)` in `AppDelegate`.
- **The session uses the schedule snapshot taken at session start** — admin edits mid-session never leak into a running session (validity).
- Overlaps impossible by construction: closest reminders are 5 min apart; worst-case chain (45 s window + 120 s card) ≈ 2¾ min.

### 5.3 Reminder display (presentational only)
- **Cursor proximate** — `CursorPillManager` as today (already click-through); add `visibilityMs`: animation plays once, final frame holds until window end.
- **Top-center notch card** — `IslandView` **loses its Dismiss button** (uniform non-interactive reminders); same hold-final-frame behavior.
- **System tray** — `TrayCardView` gains the **message text** (currently dropped) under/beside the animation; status item persists for the window.
- Fallback matrix (logged via `usedFallback`): character+notch/tray → character cursor asset scaled to frame; missing asset → ambient equivalent; native show failure → `failed` event (the compliance card is **not** shown for undelivered reminders — no stimulus, no compliance question; the failure itself is the data).

### 5.4 The uniform compliance card (the measurement instrument)
Generalizes `ComplianceCardManager`/`ComplianceCardView`:
- **Position:** top-right corner of the main screen (panel, `mainMenu+1` level, non-activating) — **not** tray-anchored. Identical position, size, styling, and behavior for every reminder, placement, style, day, and participant. One SwiftUI view, no variants — protected as a constant instrument.
- **Content:** kind-appropriate question (defaults: hydration → "Did you drink some water?", micro-break → "Did you take a short break?") + two buttons (defaults "Done" → `completed`, "Not now" → `dismissed`). Strings are app constants (admin-editable question text is a P2 option, §10.3).
- **Lifecycle:** shown at reminder-window end; dismisses on answer or after `cardTimeoutMs` (default 120 s → `timedOut`); native safety-max 10 min against orphan panels.
- **Channel contract:** Dart → native `showComplianceCard { reminderId, question, button1Text, button2Text, timeoutMs }`; native → Dart `onCardAction { reminderId, action }`, `onCardTimeout { reminderId }`. `compliance_card_service.dart` keeps a persistent handler and routes by `reminderId` (today it registers a one-shot handler and only prints).

### 5.5 Test mode without contamination
- `APP_ENV` (`--dart-define`): `dev` shows the Test Mode tab as today; `pilot` behind a long-press; `study` compiles it out.
- Test triggers run through the same display pipeline (reminder + card) but with `participantId: "TEST"` and **local-CSV-only writes** — never Firestore — so QA can validate end-to-end without polluting analysis data.

---

## 6. Recommended Flutter architecture

### 6.1 Module map (additive to the existing layout — no rewrite)

```
lib/
  domain/
    reminders/reminder_content.dart     (extended: variantId, visibilityMs, placement serialization)
    study/                              (NEW: enums, ScheduledReminder, DaySchedule, ReminderEvent,
                                         kDefaultScheduleTemplate, pure content resolver,
                                         csv serialization: toCsvRow/fromCsvRow + header)
  application/
    reminders/reminder_manager.dart     (evolved → orchestrator: display + card sequencing per event)
    study/                              (NEW)
      participant_provider.dart         (ID entry, fetch+cache participant/config/schedule, validation)
      session_controller.dart           (start/resume/complete Day N, session status)
      scheduler_provider.dart           (tick loop, grace policy, catch-up)
    admin/                              (NEW — compiled only in admin builds)
      admin_auth_provider.dart          (researcher email sign-in)
      participants_provider.dart        (create/list/activate-day/override)
      study_config_provider.dart        (questionnaire links, default template editing)
      export_provider.dart              (per-participant + all-participants CSV download)
    test_mode/, navigation/, theme/     (as today)
  core/
    constants/ (app_strings, platform_channels extended, app_config.dart NEW:
                env, versions, visibilityMs, cardTimeoutMs, grace window, data/export paths)
    services/
      cursor_pill_service / notch_hook_service / tray_pill_service
                                        (extended: reminderId, visibilityMs; platform guard)
      compliance_card_service.dart      (rewritten: persistent handler, reminderId routing)
      firestore/ (NEW: participant_repository, config_repository, schedule_repository,
                  session_repository, reminder_event_repository — behind interfaces)
      local/ (NEW: local_store.dart — shared_preferences: last ID, cached config/schedule,
              session snapshot pointer;
              csv_store.dart — per-session CSV pair: events.csv (state) + event_log.csv
              (append-only transitions); atomic writes; CSV read-back for resume;
              sync_service.dart — CSV↔Firestore reconciliation on launch/connectivity)
      admin/ (NEW: admin_export_service.dart — Firestore → flattened CSV files)
  presentation/
    pages/study/   (NEW: id_entry_page, day_start_page, session_page, day_complete_page)
    pages/admin/   (NEW: admin_login_page, participants_page, participant_detail_page,
                    schedule_editor_page, links_settings_page — admin builds only)
    pages/test_mode/ (unchanged UX; gated)
```

### 6.2 State & navigation
Riverpod 3 codegen stays. `ReminderManager` keeps its queue purely for *display serialization*; timing belongs to the scheduler (absolute fire times). Navigation stays `NavigationRail` + index provider; items are a function of build mode (participant / admin) and `APP_ENV`. Placeholder pages (Dashboard/Breaks/Hydration) are removed; the participant build's home is the ID-entry screen.

### 6.3 Environments
`AppConfig.fromEnvironment()` reads `APP_ENV` ∈ {dev, pilot, study}, `USE_FIRESTORE_EMULATOR`, `KETI_ADMIN` (bool). dev → emulator + test tab; pilot → real project + `environment: "pilot"` stamped on docs; study → locked down.

### 6.4 Local CSV storage & sync model (v3)

**On-device layout** (under the app's sandboxed documents directory — no extra entitlements needed):

```
keti_data/
  P014/
    day1/
      session.csv        # one row: session snapshot (start time, style, status, resumedCount, links)
      events.csv         # 8 rows — ALWAYS the latest state of every reminder event
      event_log.csv      # append-only audit trail: one row per state transition
    day2/ …
```

- **`events.csv` (state):** rewritten atomically (write temp file → rename) after every event mutation. 8 rows — trivially cheap. This is the row set the researcher can open directly in Excel/R/SPSS on the participant's machine, and the input to reconciliation.
- **`event_log.csv` (audit):** append-only; one row per transition (`timestamp, eventId, transition, field, oldValue, newValue`). Never rewritten → no data loss from a crash mid-write; also makes every mutation forensically traceable.
- **`session.csv`:** the session snapshot needed to resume after an app quit (original `sessionStartedAt`, schedule snapshot, status).
- CSV dialect: RFC 4180 quoting, UTF-8 (with BOM option for Excel), header row frozen by `protocolVersion`. Domain models carry `toCsvRow()` / `fromCsvRow()` + a `csvHeader` constant so writer, reader, and admin export can never drift apart.

**Sync (under the hood):** every event mutation → (1) append to `event_log.csv`, (2) rewrite `events.csv`, (3) write to Firestore. Online: the Firestore write lands immediately (perceived realtime). Offline: the Firestore SDK's persistent cache queues it; on reconnect the SDK flushes. On app launch and on connectivity regain, `sync_service.dart` reconciles: reads `events.csv`, fetches the session's Firestore docs, and replays any row whose local state is newer/more complete using deterministic doc IDs + `set(merge:)` — idempotent, so replays can never duplicate. Reconciliation verifies row counts (8/8) and logs discrepancies to `event_log.csv`.

**Why CSV and not a local database (default):** at 8 events/session there is nothing to query relationally; CSV gives the researcher a directly readable local copy with zero export step and zero dependencies. **Alternative documented:** SQLite via `drift` as the local store (better if per-device ad-hoc querying or larger event volumes ever appear), with CSVs generated from it — listed as open decision §10.11, default: CSV pair.

### 6.5 Lifecycle
`WidgetsBindingObserver` logs pause/resume into `event_log.csv`; `SessionController.resumeIfNeeded()` on launch restores from `session.csv` + `events.csv` and re-anchors the scheduler. `applicationShouldTerminateAfterLastWindowClosed` → **`false` during an active session** (window close hides the UI; scheduler keeps running via the persistent tray item), `true` otherwise — the single most important reliability change for 2-hour sessions.

### 6.6 Admin backend — options

| Option | What it is | Pros | Cons |
|---|---|---|---|
| **A (recommended)** | Admin mode inside the same app: `KETI_ADMIN=true` build, researcher email sign-in, extra admin pages | One codebase; reuses domain models, repos, CSV serializers, theme; participant builds compile it out; runs on the researcher's Mac like the participant build; **CSV export is a button, not a script** | Shipped participant binary must have admin compiled out (build-flag discipline, tested) |
| B | Separate small admin app (second target in repo, macOS or Flutter web) | Clean separation; web variant usable anywhere | Second app to build/deploy; web adds firebase config + hosting surface; duplicated models risk drift |
| C | Firebase console + Admin SDK scripts only | Zero UI code | Error-prone (no validation), unfriendly day-to-day, easy to mistype schedule rows; export only via script |
| D | Local CLI (Admin SDK) | Auditable, scriptable | Least friendly; no visual confirmation of schedules |

**Recommendation: A**, with C's scripts kept for admin-claim setup, session voiding, and participant deletion. Admin auth: one researcher **email/password** account (created in console), given a custom claim `admin: true` by a one-time setup script; Firestore rules gate all config/participant writes on that claim (§8). Participant apps never see admin code (`--dart-define` compile gating + tree-shaking of the admin pages).

**Admin CSV export (in-app):** `admin_export_service.dart` reads a participant's Firestore subtree (participant doc, session docs, all `reminderEvents`), flattens them with the **same `toCsvRow()`/header code as the device CSVs** (identical columns, guaranteed), and writes three files per participant (`P014_participant.csv`, `P014_sessions.csv`, `P014_events.csv`) plus an optional combined all-participants `events.csv`. Output goes to a configurable export folder — default: `keti_exports/` inside the app's documents directory (sandbox-safe, no extra entitlement), with a "Reveal in Finder" button; choosing an arbitrary folder requires the `com.apple.security.files.user-selected.read-write` entitlement (decision §10.12).

---

## 7. Firestore schema and event model

### 7.1 Collection hierarchy

```
config/study                                   # one doc: links + protocol constants (admin-written)
participants/{participantCode}                 # e.g. P014 (admin-written; client read-only)
participants/{participantCode}/schedules/{dayId}        # "day1" | "day2" — 8-row array docs
participants/{participantCode}/studySessions/{dayId}    # one per completed/attempted day
participants/{participantCode}/studySessions/{dayId}/reminderEvents/{eventId}  # "reminder01"…"reminder08"
```

### 7.2 Example documents

```jsonc
// config/study  (admin only)
{
  "protocolVersion": "2026-08-v1",
  "questionnaireLinks": {
    "start":   "https://docs.google.com/forms/d/e/…/viewform?usp=pp_url&entry.10={participantId}",
    "day1End": "https://docs.google.com/forms/d/e/…/viewform?usp=pp_url&entry.10={participantId}&entry.11=day1",
    "day2End": "https://docs.google.com/forms/d/e/…/viewform?usp=pp_url&entry.10={participantId}&entry.11=day2",
    "final":   "https://docs.google.com/forms/d/e/…/viewform?usp=pp_url&entry.10={participantId}"
  },
  "defaultSchedule": [ /* the 8-row template from §5.1, as maps */ ],
  "updatedAt": "<serverTimestamp>"
}

// participants/P014  (admin-written; client read-only)
{
  "participantCode": "P014",
  "serial": 14,
  "styleOrder": "CHARACTER_FIRST",       // parity default; admin-overridable at creation
  "assignmentOverride": false,
  "activeDay": 1,                        // admin flips to 2 — the only mutable operational field
  "environment": "study",
  "createdAt": "<serverTimestamp>",
  "protocolVersion": "2026-08-v1"
}

// participants/P014/schedules/day1  (admin-written from template; client read-only)
{
  "dayId": "day1", "dayNumber": 1,
  "reminders": [
    { "n": 1, "offsetSec": 1200, "placement": "CURSOR_PROXIMATE", "kind": "HYDRATION",  "variant": 1 },
    { "n": 2, "offsetSec": 1800, "placement": "NOTCH_CARD",       "kind": "MICRO_BREAK","variant": 1 },
    { "n": 3, "offsetSec": 2400, "placement": "SYSTEM_TRAY",      "kind": "HYDRATION",  "variant": 2 },
    { "n": 4, "offsetSec": 3600, "placement": "CURSOR_PROXIMATE", "kind": "MICRO_BREAK","variant": 2 },
    { "n": 5, "offsetSec": 3900, "placement": "NOTCH_CARD",       "kind": "HYDRATION",  "variant": 3 },
    { "n": 6, "offsetSec": 4800, "placement": "CURSOR_PROXIMATE", "kind": "HYDRATION",  "variant": 4 },
    { "n": 7, "offsetSec": 5400, "placement": "SYSTEM_TRAY",      "kind": "MICRO_BREAK","variant": 3 },
    { "n": 8, "offsetSec": 6000, "placement": "SYSTEM_TRAY",      "kind": "HYDRATION",  "variant": 5 }
  ],
  "updatedAt": "<serverTimestamp>"
}

// participants/P014/studySessions/day1  (client-created at day start)
{
  "dayId": "day1", "dayNumber": 1,
  "participantCode": "P014",
  "style": "CHARACTER_BASED",            // resolved from styleOrder at start; immutable
  "status": "active",                    // active | completed | voided(admin script only)
  "startedAt": "<serverTimestamp>",
  "startedAtLocal": "2026-08-03T09:02:11+02:00",
  "completedAt": null,
  "resumedCount": 0,
  "scheduleSnapshot": [ /* the 8 rows actually used — admin edits mid-session can't leak in */ ],
  "linksSnapshot": { "day1End": "https://…" },
  "environment": "study",
  "appVersion": "1.0.0+2", "protocolVersion": "2026-08-v1"
}

// …/reminderEvents/reminder04  (pre-created "scheduled", updated through its lifecycle;
//  these exact fields are also the columns of events.csv on device and of the admin export)
{
  "eventId": "reminder04",
  "participantCode": "P014", "dayId": "day1", "dayNumber": 1,
  "reminderNumber": 4,
  "scheduledOffsetSec": 3600,
  "scheduledAtLocal": "2026-08-03T10:02:11+02:00",
  // reminder display
  "reminderShownAt": "<serverTimestamp|null>",
  "reminderShownAtLocal": "2026-08-03T10:02:13+02:00",
  "reminderHiddenAtLocal": "2026-08-03T10:02:58+02:00",
  "deliveryLatenessMs": 1830,
  // condition
  "placement": "CURSOR_PROXIMATE",
  "style": "CHARACTER_BASED",
  "reminderKind": "MICRO_BREAK",
  "contentVariantId": "micro_break_2",
  // technical outcome
  "deliveryStatus": "delivered",         // scheduled|delivered|suppressed|failed|notDisplayed
  "failureReason": null,                 // e.g. "platform_exception:channel"
  "suppressionReason": null,             // "late_delivery" | "device_inactive" | "app_terminated"
  "usedFallback": false,
  // behavioral outcome (compliance card)
  "cardShownAtLocal": "2026-08-03T10:02:58+02:00",
  "outcome": "completed",                // none|completed|dismissed|timedOut
  "answeredAt": "<serverTimestamp>",
  "responseLatencyMs": 7120,
  // audit
  "sessionResumed": false,
  "environment": "study",
  "appVersion": "1.0.0+2", "protocolVersion": "2026-08-v1",
  "updatedAt": "<serverTimestamp>"
}
```

### 7.3 Immutable fields
- `participants`: fully client-immutable (admin-owned).
- `config/study`, `schedules/*`: admin-only writes.
- `studySessions`: client may only update `status` (active→completed), `completedAt`, `resumedCount`. `style`, `startedAt`, snapshots are write-once.
- `reminderEvents`: client may only update lifecycle fields (`reminderShownAt*`, `reminderHiddenAtLocal`, `deliveryLatenessMs`, `deliveryStatus`, `failureReason`, `suppressionReason`, `usedFallback`, `cardShownAtLocal`, `outcome`, `answeredAt`, `responseLatencyMs`, `sessionResumed`, `updatedAt`). Condition fields, IDs, versions are write-once. Enforced via `affectedKeys().hasOnly(...)` in rules.

### 7.4 Timestamps, sync, CSV export, indexes
- Dual timestamps (server authoritative + local ISO-8601) as before. Sync: CSV-first + SDK queue + reconciliation (§6.4).
- **Three export paths, one column layout** (all use the domain models' `toCsvRow()` + `csvHeader`):
  1. **On-device CSVs** (`events.csv` per session) — always current, collectable by hand.
  2. **Admin in-app export** (primary) — per-participant and all-participant CSVs generated from Firestore (§6.6).
  3. **Admin SDK script** `tooling/export.js` (fallback/bulk) — same columns, for use without the app.
  All three merge/deduplicate on (`participantCode`, `dayId`, `eventId`).
- **Indexes: none required** — all access is by document path; export uses list/get (no query constraints).

### 7.5 Researcher's core field list → schema mapping

| Requested field | Schema field(s) |
|---|---|
| participant ID | `participantCode` (event + session + path) |
| date and time (links Day 1/2) | `participantCode` + `dayId` keys; `scheduledAtLocal` / `reminderShownAt` / `answeredAt` |
| reminder number | `reminderNumber` (1–8) |
| reminder placement | `placement` |
| reminder style | `style` |
| delivered / suppressed / failed | `deliveryStatus` + `failureReason` / `suppressionReason` |
| completed / dismissed | `outcome` (+ `responseLatencyMs`, `answeredAt`) |

Kept in addition (cheap, high analytic value, still minimal): `contentVariantId`, `deliveryLatenessMs`, `usedFallback`, `sessionResumed`, `environment`, `appVersion`, `protocolVersion`.

---

## 8. Security and privacy plan

**Authentication — two tiers, both invisible to participants:**
- **Participant app:** Anonymous Firebase Auth at launch (silent). Gives rules a real principal without any login UI. **No uid↔participant binding** (v2 simplification): the participant app may read participant/config/schedule docs and write sessions/events for any code — acceptable because machines are researcher-controlled and data is pseudonymous and non-sensitive; integrity is enforced by *shape* and *transition* rules instead of identity binding. (Binding remains possible as a hardening option, §10.7.)
- **Admin mode:** one researcher **email/password** account with custom claim `admin: true` (set once via `tooling/set_admin.js`). Only this account can create participants, flip `activeDay`, edit schedules and links — and read across participants for in-app CSV export.

**DRAFT Firestore rules — must be validated in the Emulator Suite before any real session:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() { return request.auth != null; }
    function isAdmin()  { return signedIn() && request.auth.token.admin == true; }

    match /config/study {
      allow read: if signedIn();
      allow write: if isAdmin();
    }

    match /participants/{pid} {
      allow read: if signedIn();
      allow create, update, delete: if isAdmin();   // styleOrder, activeDay: admin-owned

      match /schedules/{dayId} {
        allow read: if signedIn();
        allow write: if isAdmin();
      }

      match /studySessions/{dayId} {
        allow read: if signedIn();
        // a participant app may start only the currently active day, once
        allow create: if signedIn()
          && dayId in ['day1','day2']
          && request.resource.data.dayNumber ==
               get(/databases/$(database)/documents/participants/$(pid)).data.activeDay
          && !('voided' in request.resource.data.status);
        allow update: if isAdmin() || (signedIn()
          && request.resource.data.diff(resource.data).affectedKeys()
               .hasOnly(['status','completedAt','resumedCount']));
        allow delete: if false;

        match /reminderEvents/{eventId} {
          allow read: if signedIn();
          allow create: if signedIn();
          allow update: if signedIn()
            && request.resource.data.diff(resource.data).affectedKeys().hasOnly(
                 ['reminderShownAt','reminderShownAtLocal','reminderHiddenAtLocal',
                  'deliveryLatenessMs','deliveryStatus','failureReason','suppressionReason',
                  'usedFallback','cardShownAtLocal','outcome','answeredAt',
                  'responseLatencyMs','sessionResumed','updatedAt']);
          allow delete: if false;
        }
      }
    }
    match /{document=**} { allow read, write: if false; }
  }
}
```

**Researcher access/export:** routine export happens **in admin mode** (§6.6 — CSVs from Firestore at the click of a button, using the researcher's admin-claimed account; rules already permit the reads above). Admin SDK scripts (`tooling/export.js` fallback, `tooling/delete_participant.js`, `tooling/set_admin.js`) run locally with a service-account JSON kept **off the repo and off participant machines**. Only the scripts can void sessions or delete data.

**GDPR-conscious minimization (study in Germany):**
- Stored: pseudonymous code, timestamps, condition data, interaction outcomes, versions. Nothing else — no names, emails, device IDs, keystroke content, IP-telemetry SDKs.
- The existing `main.dart` key logger is **deleted** (removes `logicalKey.debugName` capture; the study needs no activity data).
- Bundle the Geist font as a local asset (stops runtime requests to Google servers from participant machines).
- Firestore region **europe-west3 (Frankfurt)** — set in the console (cannot be confirmed from code; console checklist item).
- **Withdrawal/deletion:** code↔identity mapping stays in the researcher's consent records outside Firebase. On withdrawal: `delete_participant.js P014` deletes the participant subtree; the participant's `keti_data/P014/` CSV folder on the study machine is deleted by the researcher; already-exported CSVs are handled per consent terms. No identity exists in Firebase, so a code alone identifies no one.

---

## 9. Implementation roadmap

**M1 — Study domain core (pure Dart, no Firebase)**
- Goal: enums, `ScheduledReminder`/`DaySchedule`/`ReminderEvent`, `kDefaultScheduleTemplate`, pure content resolver with fallback matrix, JSON + **CSV (`toCsvRow`/`fromCsvRow`/`csvHeader`)** serialization matching §7.
- Files: new `lib/domain/study/*`; refactor `test_mode_provider.dart` to consume the resolver.
- Dependencies: none.
- Acceptance: template equals spec (8 rows/offsets/placements/kinds); resolver covers all (kind, style, placement) incl. fallbacks; model round-trips JSON **and CSV**.
- Tests: unit — template integrity, resolver matrix, JSON/CSV round-trips (incl. quoting edge cases: commas in strings, null fields).

**M2 — Local persistence: CSV store + ID-entry participant flow (no Firestore yet)**
- Goal: `shared_preferences` local store (last ID, cached config/schedule, session pointer); **`csv_store.dart`** (atomic `events.csv` rewrite, append-only `event_log.csv`, `session.csv`, read-back); ID-entry screen with validation; offline-cache logic; day-start screen shell.
- Files: `core/services/local/local_store.dart`, `csv_store.dart`, `application/study/participant_provider.dart`, `presentation/pages/study/id_entry_page.dart`, `day_start_page.dart`, nav rework (remove placeholders).
- Dependencies: `shared_preferences`; M1.
- Acceptance: simulated session writes correct CSV pair; killing the app mid-write never corrupts `events.csv` (atomic rename); enter ID → (mocked repo) day screen; relaunch pre-fills ID, serves cache "offline", offers resume from `session.csv`.
- Tests: unit (CSV write/read-back, atomic write via temp+rename, log append), widget (entry flow, invalid ID, cached path).

**M3 — Firestore wiring + anonymous auth + rules v1 (Emulator-first)**
- Goal: add `cloud_firestore`, `firebase_auth`; **fix entitlements (`network.client`, both files)**; repositories; silent anonymous sign-in; draft rules in Emulator; commit `firestore.rules` and `.firebaserc` (Firebase client config stays **local-only/gitignored** — the repo is public — with committed `.example` templates).
- Files: `core/services/firestore/*`, `macos/Runner/*.entitlements`, `main.dart` (emulator switch + auth), `pubspec.yaml`, new `firestore.rules`.
- Dependencies: M2; console: enable Auth (anonymous + email), Firestore at europe-west3.
- Acceptance: against emulator — ID entry creates nothing but reads participant; session create blocked unless `activeDay` matches; participant doc write blocked for non-admin; event field-tampering blocked.
- Tests: **Emulator suite** for every rule branch; repo unit tests with `fake_cloud_firestore`.

**M4 — Scheduler + session controller + resume**
- Goal: day start (session doc + snapshot + 8 pre-created events in Firestore **and** CSVs), tick scheduler with grace policies, terminate/resume from the CSV store; session-aware `applicationShouldTerminateAfterLastWindowClosed`; App Nap disabled in sessions.
- Files: `application/study/scheduler_provider.dart`, `session_controller.dart`, `AppDelegate.swift`.
- Dependencies: M1–M3.
- Acceptance: fake-clock unit tests; kill-at-00:25 integration → resume on original clock, missed event `notDisplayed(app_terminated)`, `resumedCount=1`, no duplicates in CSV or Firestore.
- Tests: unit (scheduler/catch-up), integration (100-min simulated session at 100× against emulator → 8 correct docs + 8 correct CSV rows).

**M5 — Uniform reminder display + compliance card**
- Goal: channel contract v2 (`reminderId`, `visibilityMs`); hold-final-frame windows on all three placements; remove Island Dismiss button; tray message text; generalized top-right compliance card (question + 2 buttons, timeout, `onCardAction/onCardTimeout`); `compliance_card_service.dart` rewrite; platform guards (`MissingPluginException`).
- Files: 4 services + `platform_channels.dart` (Dart & Swift), `CursorPillManager`, `IslandView`, `TrayCardView`, `ComplianceCard*`, `reminder_manager.dart` → orchestrator.
- Dependencies: M4; macOS native work.
- Acceptance: each reminder shows exactly 45 s; card appears top-right after every window, identical across conditions; outcomes + latencies land in CSV + Firestore events; forced channel failure → `failed` event, no card, no crash.
- Tests: widget tests (Dart callback routing), manual QA checklist per placement (native UI), emulator test of full reminder→card→event chain.

**M6 — Study-mode shell, day completion, questionnaire links**
- Goal: `AppConfig` envs; session page (quiet status: code, day, next-reminder countdown); day-complete screen with "Complete end of day questionnaire" (+ final link on Day 2) via `url_launcher` with placeholder substitution; test-mode gating; delete key logger; bundle fonts; version stamping.
- Files: `main.dart`, `core/constants/app_config.dart`, `navigation_provider.dart`, study pages, `pubspec.yaml` (font assets + `url_launcher`), delete `user_activity_provider.dart` + main.dart handlers.
- Dependencies: M2–M5.
- Acceptance: `study` build has no test UI/dev strings; day completes → button opens correct Form URL with `{participantId}`/`{day}` substituted; every doc/CSV row stamped with env/versions.
- Tests: widget (full Day-1 → Day-2 screen flow), unit (URL template substitution).

**M7 — Admin mode (recommended Option A) incl. in-app CSV export**
- Goal: `KETI_ADMIN=true` build; researcher email login; participants list + create (serial → parity order, override); participant detail (status per day, event counts); **Activate Day 2**; links settings form (4 URL templates); schedule editor (8-row form; default-template reset); **"Download CSV" per participant + "Export all"** writing flattened CSVs from Firestore to the export folder with Reveal-in-Finder. `tooling/set_admin.js`.
- Files: `application/admin/*`, `presentation/pages/admin/*`, `core/services/admin/admin_export_service.dart`, admin auth wiring, `tooling/set_admin.js`.
- Dependencies: M3 (rules/claim), M6.
- Acceptance: create participant → docs appear (participant + 2 schedules); activate Day 2 → participant app can start Day 2 and not before; link edit → participant app opens new URL; **export produces byte-compatible column layout with device CSVs and correct row counts**; order change blocked after Day 1 start (UI) and for non-admins (rules).
- Tests: widget (admin forms + export button), emulator (admin claim gates; export against emulator data), unit (Firestore doc → CSV row flattening, nested fields, nulls).

**M8 — Offline reconciliation + hardening of export paths**
- Goal: `sync_service.dart` (CSV↔Firestore reconciliation on launch/connectivity, row-count verification); `tooling/export.js` (script fallback) + `tooling/delete_participant.js`; runbook (README): machine setup, admin setup, day protocol, withdrawal procedure, CSV locations.
- Files: `core/services/local/sync_service.dart`, repositories (CSV-first write path), `tooling/*`, README.
- Dependencies: M3–M4, M7.
- Acceptance: airplane-mode session → reconnect → 8/8 in Firestore, no dupes, CSV and Firestore agree; deletion script removes a participant tree.
- Tests: emulator offline/online toggle; reconciliation unit tests (local-newer, remote-newer, divergent); script dry-run on emulator dump.

**M9 — Pilot hardening**
- Goal: 2–4 pilot codes end-to-end (`environment: "pilot"`); fix findings; replace stale `widget_test.dart`; `flutter analyze` clean; commit/decide Firebase config files; signing/notarization plan for study machines.
- Acceptance: pilot export (in-app + device CSVs) is complete and correctly shaped for both days and both orders.

**Smallest viable version for the real study:** M1 + M2 + M3 + M4 + M5 + M6 + **M7-minimal (create participant, activate Day 2, edit links, per-participant CSV download)** + the CSV store from M2. Schedule editor (rest of M7), reconciliation polish (M8), and pilot hardening (M9) de-risk but are not on the critical path — in a pinch, schedules ship as the default template and data is collected from the on-device CSVs by hand.

---

## 10. Open decisions

1. **Visibility duration (30–60 s)?** Default: **45 s** fixed (`visibilityMs`), same for all reminders.
2. **Compliance card timeout?** Default: **120 s**, then `timedOut`. Long enough for a natural pause, short enough never to collide with the next reminder (≥5 min away).
3. **Card question/button wording?** Default: hydration → "Did you drink some water?", micro-break → "Did you take a short break?"; buttons "Done" / "Not now". Constants, identical for everyone (admin-editable text = P2, not recommended — instrument uniformity).
4. **Card timing interpretation?** Default: card appears **at the end of the reminder's visibility window** (reminder shows 45 s → card). Alternative (card 30–60 s after onset while reminder may still be up) is a one-line scheduling change if preferred.
5. **Late-delivery grace window?** Default: **120 s**, then `suppressed(late_delivery)`.
6. **Target OS?** Default: **macOS only** (native layers exist only there; Windows = separate future milestone).
7. **Participant-app write security?** Default: anonymous-auth + shape/transition rules, **no uid binding** (controlled machines, pseudonymous data). Hardening option: bind uid at first entry with admin re-bind script — adds failure modes for marginal gain.
8. **Show condition names on the participant screen?** Default: **no** — day screen shows "Day 1"/"Day 2" only, reducing demand characteristics.
9. **Screen-lock detection?** Default: tick-gap inference (`device_inactive`); native `CGSession` polling only if the researcher later needs lock vs. sleep separated.
10. **Character notch/tray assets?** Default: cursor-asset fallback with `usedFallback` flag; commission assets only if fidelity is judged at risk (design question, not answerable from code).
11. **Local storage: CSV vs database?** Default: **CSV pair** (`events.csv` state + `event_log.csv` append-only + `session.csv`) — directly researcher-readable, zero dependencies, sufficient at 8 events/session. Alternative: SQLite via `drift` as the store with CSVs generated from it, if on-device querying or larger volumes ever appear.
12. **Admin export location?** Default: `keti_exports/` in the app's sandboxed documents directory + "Reveal in Finder" (no extra entitlements). Configurable arbitrary folder requires adding `com.apple.security.files.user-selected.read-write` to both entitlements files.

---

## 11. Risks and mitigations

**Experimental validity**
- *Uniform-instrument contamination: the compliance card must never vary.* Mitigation: single SwiftUI view + constant strings, no style/placement parameters; code-review checkpoint in M5; QA screenshot diff across conditions.
- *Admin edits leaking into a running session.* Mitigation: schedule + links **snapshotted into the session doc** at start; scheduler runs the snapshot only.
- *Test-mode contamination.* Mitigation: `APP_ENV` compile gating; test triggers local-CSV-only; `environment` stamped on every doc/row.
- *Order reassignment.* Mitigation: admin-owned `styleOrder`, rules deny client writes, admin UI soft-locks after Day 1 start.
- *Wrong-ID entry* (participant types someone else's code). Mitigation: confirmation screen ("You are P014 — Day 1"), last-ID pre-fill, admin can void a mis-entered session; data is linkable/correctable via `participantCode` at analysis.
- *Late/duplicated reminders.* Mitigation: absolute-time scheduling, 120 s grace, deterministic event IDs (idempotent writes), lateness logged in ms.

**Reliability & timing**
- *Window close quits the app mid-session.* Mitigation: session-aware termination (M4) — app survives window close during sessions via the tray item.
- *App Nap/sleep stalls timers.* Mitigation: `beginActivity(.userInitiated)`; tick + catch-up; gaps logged as `device_inactive`.
- *Queue delaying schedule.* Mitigation: scheduler owns absolute timing; queue only serializes rendering; gaps ≥5 min vs ≤2¾ min worst-case chain.
- *Non-macOS channel crashes.* Mitigation: platform guards; study build targets macOS only.

**Data integrity (CSV + Firestore + offline)**
- *CSV corruption from a crash mid-write.* Mitigation: `events.csv` written atomically (temp file + rename); `event_log.csv` append-only (never rewritten); reconciliation verifies 8/8 row counts.
- *Divergence between device CSVs and Firestore.* Mitigation: single serialization code path (`toCsvRow`/`csvHeader` shared by device store, admin export, and script); `sync_service` reconciliation on launch/connectivity; `updatedAt` + transition log to resolve newer state.
- *Offline at ID entry (no cached config).* Mitigation: clear "cannot start offline" error; cache from any prior successful fetch otherwise.
- *Rules misconfiguration silently dropping writes.* Mitigation: full emulator suite in M3/M7 before any real session; device CSVs are ground truth for recovery.
- *Clock skew.* Mitigation: dual timestamps; server authoritative.
- *macOS sandbox blocking network* (verified missing `network.client`). Mitigation: M3 entitlement fix + real-project smoke test before pilot.

**Deployment**
- *Firebase config with API keys in a public repo.* Mitigation: `firebase_options.dart` and `GoogleService-Info.plist` are gitignored and local-only, with committed `.example` templates and a gitignored `.env.local` reference; `firebase.json`/`.firebaserc` (no keys) are committed; rotate/restrict keys in the Google Cloud console if they are ever exposed.
- *Admin claim mis-setup locks out admin.* Mitigation: `set_admin.js` script + runbook; tested in emulator first.
- *Link rot / wrong Form URLs.* Mitigation: admin "open test link" button in the links form; placeholder validation on save (`{participantId}` must be present).
- *Unknown study machines.* Mitigation: macOS-only, one researcher-controlled release build per machine, M5 QA checklist per machine, frozen `protocolVersion`.

---

**Summary of what changes conceptually:** the app keeps its Riverpod skeleton, native placement managers, and test mode, and gains: an ID-entry participant flow driven entirely by Firestore config; a deterministic scheduler with resume; a **uniform top-right compliance card** as the single behavioral instrument; a **CSV-first local store** (state + append-only log per session) synced to Firestore under the hood; and an **admin mode** (same app, build-flag gated) for participants, day activation, schedules, questionnaire links, and **one-click per-participant CSV downloads**. Questionnaires stay in Google Forms; no accounts, no notifications, no personalization — nothing beyond the protocol.
