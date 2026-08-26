/// Build/run configuration via `--dart-define` (plan §6.3).
///
/// Environments:
///  - `dev`   (default): local development, emulator allowed, test tab visible
///  - `pilot`: real Firebase project, docs stamped `pilot`
///  - `study`: real Firebase project, locked down, docs stamped `study`
class AppConfig {
  const AppConfig._();

  /// One of `dev`, `pilot`, `study`.
  static const environment = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  /// Route Firestore/Auth to the local Emulator Suite.
  static const useFirebaseEmulator =
      bool.fromEnvironment('USE_FIRESTORE_EMULATOR', defaultValue: false);

  /// Build flag for the admin backend (plan §6.6, milestone M7).
  static const isAdminBuild =
      bool.fromEnvironment('KETI_ADMIN', defaultValue: false);

  /// Stamped onto every document/CSV row for auditability.
  static const appVersion = '1.0.0+1';

  /// Frozen study-protocol version; bump only with a protocol change.
  static const protocolVersion = '2026-08-v1';

  // ── Protocol timing constants (plan §10) ─────────────────────────
  static const reminderVisibilityMs = 45000;

  /// Compliance card appears this long after the reminder has disappeared.
  static const complianceCardDelayMs = 15000;

  /// Compliance card auto-dismisses after this long without a response;
  /// an auto-dismissed card is recorded as `Ignored`.
  static const complianceCardTimeoutMs = 30000;

  static const lateDeliveryGraceMs = 120000;
}
