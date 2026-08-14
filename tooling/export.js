/**
 * Fallback CSV export — walks the Firestore tree and writes three CSVs
 * (participants, sessions, events) with the same column layout as the
 * in-app admin export and the on-device study CSVs, so all three sources
 * merge cleanly. Needs a service-account key.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node tooling/export.js > export.zip   # or redirect to files
 */

const fs = require('node:fs');
const path = require('node:path');
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'keti-fcfd6',
});

const db = admin.firestore();

const P_HEADER = [
  'participantCode','serial','styleOrder','assignmentOverride','activeDay',
  'environment','protocolVersion',
];
const S_HEADER = [
  'participantCode','dayId','dayNumber','style','status','startedAtLocal',
  'completedAtLocal','resumedCount','scheduleJson','linksJson',
  'participantExitRequestedAt',
];
const E_HEADER = [
  'eventId','participantCode','dayId','dayNumber','reminderNumber',
  'scheduledOffsetSec','scheduledAtLocal','reminderShownAtLocal',
  'reminderHiddenAtLocal','deliveryLatenessMs','placement','style',
  'reminderKind','contentVariantId','deliveryStatus','failureReason',
  'suppressionReason','usedFallback','cardShownAtLocal','outcome',
  'answeredAtLocal','responseLatencyMs','sessionResumed','environment',
  'appVersion','protocolVersion','cardResponse',
];

function csvRow(fields) {
  return fields.map(f => {
    const s = String(f ?? '');
    return s.includes(',') || s.includes('"') || s.includes('\n')
      ? `"${s.replaceAll('"', '""')}"`
      : s;
  }).join(',');
}

async function main() {
  const participants = await db.collection('participants').get();
  const pRows = [];
  const sRows = [];
  const eRows = [];

  for (const pdoc of participants.docs) {
    const pdata = pdoc.data();
    pRows.push(csvRow([
      pdata.participantCode, pdata.serial, pdata.styleOrder,
      pdata.assignmentOverride, pdata.activeDay,
      pdata.environment, pdata.protocolVersion,
    ]));

    for (const dayId of ['day1', 'day2']) {
      const sdoc = await pdoc.ref.collection('studySessions').doc(dayId).get();
      if (!sdoc.exists) continue;
      const sdata = sdoc.data();
      sRows.push(csvRow([
        sdata.participantCode, sdata.dayId, sdata.dayNumber, sdata.style,
        sdata.status, sdata.startedAtLocal, sdata.completedAtLocal ?? '',
        sdata.resumedCount ?? 0,
        JSON.stringify(sdata.scheduleSnapshot ?? []),
        JSON.stringify(sdata.linksSnapshot ?? {}),
        sdata.participantExitRequestedAt
          ? sdata.participantExitRequestedAt.toDate().toISOString()
          : '',
      ]));

      const events = await sdoc.ref.collection('reminderEvents')
        .orderBy('reminderNumber').get();
      for (const edoc of events.docs) {
        const d = edoc.data();
        eRows.push(csvRow([
          d.eventId, d.participantCode, d.dayId, d.dayNumber,
          d.reminderNumber, d.scheduledOffsetSec, d.scheduledAtLocal,
          d.reminderShownAtLocal, d.reminderHiddenAtLocal,
          d.deliveryLatenessMs, d.placement, d.style,
          d.reminderKind, d.contentVariantId, d.deliveryStatus,
          d.failureReason, d.suppressionReason, d.usedFallback,
          d.cardShownAtLocal, d.outcome, d.answeredAtLocal,
          d.responseLatencyMs, d.sessionResumed, d.environment,
          d.appVersion, d.protocolVersion, d.cardResponse,
        ]));
      }
    }
  }

  const outDir = process.argv[3] || '.';
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, 'participants.csv'), csvRow(P_HEADER) + '\n' + pRows.join('\n') + '\n');
  fs.writeFileSync(path.join(outDir, 'sessions.csv'), csvRow(S_HEADER) + '\n' + sRows.join('\n') + '\n');
  fs.writeFileSync(path.join(outDir, 'events.csv'), csvRow(E_HEADER) + '\n' + eRows.join('\n') + '\n');
  console.log(`Wrote ${pRows.length} participants, ${sRows.length} sessions, ${eRows.length} events.`);
  process.exit(0);
}

main();
