import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/presentation/widgets/schedule_editor.dart';

void main() {
  testWidgets('ScheduleRowEditor wraps instead of overflowing when narrow',
      (tester) async {
    final draft = ScheduleDraft(
      offsetController: TextEditingController(text: '20'),
      placement: Placement.cursorProximate,
      kind: ReminderKind.hydration,
      variantNumber: 1,
    );
    addTearDown(draft.dispose);

    final ceilings = VariantCeilings();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: ScheduleRowEditor(
                index: 0,
                draft: draft,
                ceilingFor: ceilings.ceilingFor,
                onAddVersion: ceilings.addVersion,
                onChanged: () {},
              ),
            ),
          ),
        ),
      ),
    );

    // A RenderFlex overflow would be surfaced here as a FlutterError.
    expect(tester.takeException(), isNull);
  });

  test('VariantCeilings.addVersion extends the ceiling by one', () {
    final c = VariantCeilings();
    expect(c.ceilingFor(ReminderKind.hydration), 5);
    expect(c.addVersion(ReminderKind.hydration), 6);
    expect(c.ceilingFor(ReminderKind.hydration), 6);
  });

  test('VariantCeilings.seed tracks the highest used variant', () {
    final c = VariantCeilings();
    c.seed([
      const ScheduledReminder(
        reminderNumber: 1,
        offset: Duration(minutes: 5),
        placement: Placement.cursorProximate,
        kind: ReminderKind.hydration,
        variantNumber: 8,
      ),
    ]);
    expect(c.ceilingFor(ReminderKind.hydration), 8);
    expect(c.ceilingFor(ReminderKind.microBreak), 3);
  });
}
