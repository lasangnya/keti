import '../../../domain/reminders/reminder_content.dart';
import '../../../domain/study/study_enums.dart';
import '../cursor_pill_service.dart';
import '../notch_hook_service.dart';
import '../tray_pill_service.dart';

/// Display sink for due reminders (plan §6.1).
///
/// M4 ships a thin implementation over the existing native services; M5
/// replaces it with the full channel contract (visibilityMs, reminderId,
/// compliance-card sequencing). Tests substitute a recording fake.
abstract class ReminderDelivery {
  Future<void> show({
    required ReminderContent content,
    required Placement placement,
  });
}

class NativeReminderDelivery implements ReminderDelivery {
  @override
  Future<void> show({
    required ReminderContent content,
    required Placement placement,
  }) {
    return switch (placement) {
      Placement.cursorProximate => CursorPillService.showPill(content),
      Placement.notchCard => NotchHookService.showIsland(content),
      Placement.systemTray => TrayPillService.showPill(content),
    };
  }
}
