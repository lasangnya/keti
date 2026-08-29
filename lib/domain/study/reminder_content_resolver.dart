import '../reminders/reminder_content.dart';
import 'study_enums.dart';

/// The visual content for one (kind, style) pair plus which placements had
/// to fall back to a shared asset.
///
/// Fallback definition (plan §5.3): a placement is a fallback when no
/// dedicated (style, kind, placement) frame sequence exists in
/// `macos/Runner/Assets.xcassets`. Current asset matrix:
///
/// | style     | kind       | cursor | notch | tray |
/// |-----------|------------|--------|-------|------|
/// | ambient   | break      | ✔      | ✔     | —    |
/// | ambient   | hydration  | ✔      | ✔     | —    |
/// | character | break      | ✔      | —     | —    |
/// | character | hydration  | ✔      | —     | —    |
///
/// Tray always reuses the cursor asset; the character style has no
/// notch/tray assets at all.
class ResolvedReminderContent {
  const ResolvedReminderContent({
    required this.content,
    required this.fallbackPlacements,
  });

  final ReminderContent content;
  final Set<Placement> fallbackPlacements;

  bool isFallback(Placement placement) => fallbackPlacements.contains(placement);
}

/// Pure resolver mapping (kind, style) → visual content.
///
/// Single source of truth for reminder presentation, shared by the study
/// orchestrator and the developer test mode. The variant number
/// (Hydration 1–5 / Micro break 1–3) does not change visuals today; it only
/// feeds `contentVariantId`.
class ReminderContentResolver {
  const ReminderContentResolver();

  ResolvedReminderContent resolve(ReminderKind kind, PresentationStyle style) =>
      switch ((kind, style)) {
        (ReminderKind.microBreak, PresentationStyle.ambient) => _ambientBreak(),
        (ReminderKind.hydration, PresentationStyle.ambient) =>
          _ambientHydration(),
        (ReminderKind.microBreak, PresentationStyle.characterBased) =>
          _characterBreak(),
        (ReminderKind.hydration, PresentationStyle.characterBased) =>
          _characterHydration(),
      };

  // Ambient notch cards use the "default" preset (400×100).
  static const _ambientNotchWidth = 400.0;
  static const _ambientNotchHeight = 100.0;

  // Character notch presentation reuses the "narrow-deep" preset (250×250)
  // with the cursor asset scaled into it.
  static const _characterNotchWidth = 250.0;
  static const _characterNotchHeight = 250.0;

  static const _ambientFallbacks = {Placement.systemTray};
  static const _characterFallbacks = {
    Placement.notchCard,
    Placement.systemTray,
  };

  // Ambient cursor pills: a square window matching the square frame assets
  // (renders at 48px). Vertically centered on the cursor
  // (offsetY = -height/2) and offset a little to the right of the cursor
  // (offsetX = 12).
  ResolvedReminderContent _ambientBreak() => ResolvedReminderContent(
        fallbackPlacements: _ambientFallbacks,
        content: const ReminderContent(
          message: "Time for a break",
          cursorResource: "ambient_break_cursor_pill",
          notchResource: "ambient_break_notch_card",
          trayResource: "ambient_break_cursor_pill",
          cursorWidth: 48,
          cursorHeight: 48,
          cursorOffsetX: 12,
          cursorOffsetY: -24,
          notchWidth: _ambientNotchWidth,
          notchHeight: _ambientNotchHeight,
          trayWidth: 22,
          trayHeight: 4,
          totalFrames: 250, // 30 fps → ~8.3 s sequence (matches character)
        ),
      );

  ResolvedReminderContent _ambientHydration() => ResolvedReminderContent(
        fallbackPlacements: _ambientFallbacks,
        content: const ReminderContent(
          message: "Stay hydrated",
          cursorResource: "ambient_hydration_cursor_pill",
          notchResource: "ambient_hydration_notch_card",
          trayResource: "ambient_hydration_cursor_pill",
          cursorWidth: 48,
          cursorHeight: 48,
          cursorOffsetX: 12,
          cursorOffsetY: -24,
          notchWidth: _ambientNotchWidth,
          notchHeight: _ambientNotchHeight,
          trayWidth: 4,
          trayHeight: 22,
          totalFrames: 250, // 30 fps → ~8.3 s sequence (matches character)
        ),
      );

  ResolvedReminderContent _characterBreak() => ResolvedReminderContent(
        fallbackPlacements: _characterFallbacks,
        content: const ReminderContent(
          message: "Keti needs a stretch!",
          cursorResource: "character_break_cursor_pill",
          notchResource: "character_break_cursor_pill",
          trayResource: "character_break_cursor_pill",
          cursorWidth: 80,
          cursorHeight: 80,
          cursorOffsetX: 0,
          cursorOffsetY: -40,
          notchWidth: _characterNotchWidth,
          notchHeight: _characterNotchHeight,
          trayWidth: 22,
          trayHeight: 22,
          totalFrames: 250, // 30 fps → ~8.3 s sequence
        ),
      );

  ResolvedReminderContent _characterHydration() => ResolvedReminderContent(
        fallbackPlacements: _characterFallbacks,
        content: const ReminderContent(
          message: "Drink water with Keti!",
          cursorResource: "character_hydration_cursor_pill",
          notchResource: "character_hydration_cursor_pill",
          trayResource: "character_hydration_cursor_pill",
          cursorWidth: 80,
          cursorHeight: 80,
          cursorOffsetX: 0,
          cursorOffsetY: -40,
          notchWidth: _characterNotchWidth,
          notchHeight: _characterNotchHeight,
          trayWidth: 22,
          trayHeight: 22,
          totalFrames: 250, // 30 fps → ~8.3 s sequence
        ),
      );
}
