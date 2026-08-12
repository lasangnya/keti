/**
 * Firestore security rules suite (plan §8 / milestone M3).
 *
 * Run with:  npm run test:rules   (from the repo root's tooling/ dir,
 * wraps: firebase emulators:exec --only auth,firestore "npm test")
 *
 * Covers every branch of firestore.rules:
 *  - unauthenticated access denied
 *  - anonymous (participant app) reads allowed, admin-owned writes denied
 *  - activeDay gate on session creation
 *  - session update field whitelist
 *  - reminder event lifecycle field whitelist
 *  - admin claim allows config writes
 *  - catch-all denial
 */
const { describe, it, before, after, beforeEach } = require('node:test');
const assert = require('node:assert');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
} = require('firebase/firestore');

const RULES = readFileSync(join(__dirname, '..', '..', 'firestore.rules'), 'utf8');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'keti-rules-test',
    firestore: { rules: RULES },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

// ── helpers ──────────────────────────────────────────────────────────

function anonDb(uid = 'anon-device-1') {
  return testEnv.authenticatedContext(uid).firestore();
}

function adminDb() {
  return testEnv
    .authenticatedContext('researcher-1', { admin: true })
    .firestore();
}

async function seedParticipant(data = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'participants', 'P014'), {
      participantCode: 'P014',
      serial: 14,
      styleOrder: 'CHARACTER_FIRST',
      assignmentOverride: false,
      activeDay: 1,
      environment: 'study',
      protocolVersion: '2026-08-v1',
      ...data,
    });
  });
}

async function seedSession(dayId = 'day1', data = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'participants', 'P014', 'studySessions', dayId),
      {
        dayId,
        dayNumber: Number(dayId.replace('day', '')),
        participantCode: 'P014',
        style: 'CHARACTER_BASED',
        status: 'active',
        startedAtLocal: '2026-08-03T09:02:11+02:00',
        resumedCount: 0,
        ...data,
      }
    );
  });
}

function sessionData(dayNumber) {
  return {
    dayId: `day${dayNumber}`,
    dayNumber,
    participantCode: 'P014',
    style: 'CHARACTER_BASED',
    status: 'active',
    startedAtLocal: '2026-08-03T09:02:11+02:00',
    resumedCount: 0,
  };
}

function eventData() {
  return {
    eventId: 'reminder01',
    participantCode: 'P014',
    dayId: 'day1',
    dayNumber: 1,
    reminderNumber: 1,
    placement: 'CURSOR_PROXIMATE',
    style: 'CHARACTER_BASED',
    reminderKind: 'HYDRATION',
    deliveryStatus: 'SCHEDULED',
    outcome: 'NONE',
  };
}

// ── unauthenticated ──────────────────────────────────────────────────

describe('unauthenticated access', () => {
  it('denies reads without auth', async () => {
    await seedParticipant();
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'participants', 'P014')));
    await assertFails(getDoc(doc(db, 'config', 'study')));
  });
});

// ── anonymous participant app ────────────────────────────────────────

describe('anonymous participant app', () => {
  it('may read participant, config and schedule documents', async () => {
    await seedParticipant();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'config', 'study'), {
        protocolVersion: '2026-08-v1',
      });
      await setDoc(doc(context.firestore(), 'links', 'templates'), {
        preStudy: 'https://forms.example/pre?pid={participantId}',
        endOfDayType1: 'https://forms.example/ambient?pid={participantId}',
        endOfDayType2: 'https://forms.example/character?pid={participantId}',
        final: 'https://forms.example/final?pid={participantId}',
      });
      await setDoc(
        doc(context.firestore(), 'participants', 'P014', 'schedules', 'day1'),
        { dayId: 'day1', dayNumber: 1, reminders: [] }
      );
    });

    const db = anonDb();
    await assertSucceeds(getDoc(doc(db, 'participants', 'P014')));
    await assertSucceeds(getDoc(doc(db, 'config', 'study')));
    await assertSucceeds(getDoc(doc(db, 'links', 'templates')));
    await assertSucceeds(
      getDoc(doc(db, 'participants', 'P014', 'schedules', 'day1'))
    );
  });

  it('may NOT write participant, config or schedule documents', async () => {
    await seedParticipant();
    const db = anonDb();
    await assertFails(
      setDoc(doc(db, 'participants', 'P015'), { participantCode: 'P015' })
    );
    await assertFails(
      updateDoc(doc(db, 'participants', 'P014'), { styleOrder: 'AMBIENT_FIRST' })
    );
    await assertFails(
      updateDoc(doc(db, 'participants', 'P014'), { activeDay: 2 })
    );
    await assertFails(
      setDoc(doc(db, 'config', 'study'), { protocolVersion: 'hacked' })
    );
    await assertFails(
      setDoc(doc(db, 'links', 'templates'), {
        preStudy: 'https://evil.example',
      })
    );
    await assertFails(
      setDoc(
        doc(db, 'participants', 'P014', 'schedules', 'day2'),
        { dayId: 'day2', dayNumber: 2, reminders: [] }
      )
    );
  });
});

// ── session creation gate (activeDay) ────────────────────────────────

describe('studySessions creation gate', () => {
  it('allows creating only the active day', async () => {
    await seedParticipant({ activeDay: 1 });
    const db = anonDb();
    await assertSucceeds(
      setDoc(
        doc(db, 'participants', 'P014', 'studySessions', 'day1'),
        sessionData(1)
      )
    );
    await assertFails(
      setDoc(
        doc(db, 'participants', 'P014', 'studySessions', 'day2'),
        sessionData(2)
      )
    );
  });

  it('allows day2 once the admin activated it', async () => {
    await seedParticipant({ activeDay: 2 });
    const db = anonDb();
    await assertSucceeds(
      setDoc(
        doc(db, 'participants', 'P014', 'studySessions', 'day2'),
        sessionData(2)
      )
    );
  });

  it('rejects invalid day ids and voided status', async () => {
    await seedParticipant({ activeDay: 1 });
    const db = anonDb();
    await assertFails(
      setDoc(
        doc(db, 'participants', 'P014', 'studySessions', 'day3'),
        sessionData(1)
      )
    );
    await assertFails(
      setDoc(doc(db, 'participants', 'P014', 'studySessions', 'day1'), {
        ...sessionData(1),
        status: 'voided',
      })
    );
  });
});

// ── session update whitelist ─────────────────────────────────────────

describe('studySessions update whitelist', () => {
  it('allows status, completedAt and resumedCount only', async () => {
    await seedParticipant();
    await seedSession('day1');
    const ref = doc(anonDb(), 'participants', 'P014', 'studySessions', 'day1');

    await assertSucceeds(updateDoc(ref, { status: 'completed' }));
    await assertSucceeds(updateDoc(ref, { resumedCount: 1 }));

    await seedSession('day1'); // reset
    await assertFails(updateDoc(ref, { style: 'AMBIENT' }));
    await assertFails(updateDoc(ref, { startedAtLocal: '1999-01-01' }));
    await assertFails(updateDoc(ref, { participantCode: 'P999' }));
  });

  it('denies deleting sessions', async () => {
    await seedParticipant();
    await seedSession('day1');
    await assertFails(
      deleteDoc(doc(anonDb(), 'participants', 'P014', 'studySessions', 'day1'))
    );
  });
});

// ── reminder events ──────────────────────────────────────────────────

describe('reminderEvents', () => {
  it('anonymous may create and update lifecycle fields', async () => {
    await seedParticipant();
    await seedSession('day1');
    const ref = doc(
      anonDb(),
      'participants', 'P014', 'studySessions', 'day1', 'reminderEvents', 'reminder01'
    );

    await assertSucceeds(setDoc(ref, eventData()));
    await assertSucceeds(
      updateDoc(ref, { deliveryStatus: 'DELIVERED', deliveryLatenessMs: 900 })
    );
    await assertSucceeds(
      updateDoc(ref, { outcome: 'COMPLETED', responseLatencyMs: 7120 })
    );
    await assertSucceeds(updateDoc(ref, { cardResponse: 'Done' }));
    await assertSucceeds(updateDoc(ref, { usedFallback: true }));
    await assertSucceeds(updateDoc(ref, { sessionResumed: true }));
  });

  it('anonymous may NOT alter condition or identity fields', async () => {
    await seedParticipant();
    await seedSession('day1');
    const ref = doc(
      anonDb(),
      'participants', 'P014', 'studySessions', 'day1', 'reminderEvents', 'reminder01'
    );
    await setDoc(ref, eventData());

    await assertFails(updateDoc(ref, { placement: 'SYSTEM_TRAY' }));
    await assertFails(updateDoc(ref, { style: 'AMBIENT' }));
    await assertFails(updateDoc(ref, { reminderNumber: 2 }));
    await assertFails(updateDoc(ref, { appVersion: '9.9.9' }));
    await assertFails(deleteDoc(ref));
  });
});

// ── admin claim ──────────────────────────────────────────────────────

describe('admin (researcher) access', () => {
  it('admin may write participants, schedules and config', async () => {
    const db = adminDb();
    await assertSucceeds(
      setDoc(doc(db, 'participants', 'P015'), {
        participantCode: 'P015',
        serial: 15,
        styleOrder: 'AMBIENT_FIRST',
        activeDay: 1,
      })
    );
    await assertSucceeds(
      updateDoc(doc(db, 'participants', 'P015'), { activeDay: 2 })
    );
    await assertSucceeds(
      setDoc(doc(db, 'participants', 'P015', 'schedules', 'day1'), {
        dayId: 'day1',
        dayNumber: 1,
        reminders: [],
      })
    );
    await assertSucceeds(
      setDoc(doc(db, 'config', 'study'), { protocolVersion: '2026-08-v1' })
    );
    await assertSucceeds(
      setDoc(doc(db, 'links', 'templates'), {
        preStudy: 'https://forms.example/pre?pid={participantId}',
        endOfDayType1: 'https://forms.example/ambient?pid={participantId}',
        endOfDayType2: 'https://forms.example/character?pid={participantId}',
        final: 'https://forms.example/final?pid={participantId}',
      })
    );
    await assertSucceeds(
      updateDoc(doc(db, 'links', 'templates'), {
        final: 'https://forms.example/final-v2?pid={participantId}',
      })
    );
  });
});

// ── catch-all ────────────────────────────────────────────────────────

describe('catch-all', () => {
  it('denies access to unknown paths for everyone', async () => {
    await assertFails(getDoc(doc(anonDb(), 'secrets', 'anything')));
    await assertFails(
      setDoc(doc(adminDb(), 'scratch', 'doc1'), { x: 1 })
    );
  });
});
