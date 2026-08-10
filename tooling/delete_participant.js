/**
 * Recursively deletes a participant and all their subcollections from
 * Firestore (withdrawal / GDPR right to erasure — plan §8).
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node tooling/delete_participant.js P014
 */

const admin = require('firebase-admin');

const code = process.argv[2];
if (!code) {
  console.error('Usage: node delete_participant.js <participantCode>');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'keti-fcfd6',
});

const db = admin.firestore();

async function main() {
  const doc = db.collection('participants').doc(code);
  const snap = await doc.get();
  if (!snap.exists) {
    console.error(`Participant ${code} does not exist.`);
    process.exit(2);
  }
  await db.recursiveDelete(doc);
  console.log(`Deleted ${code} and all subcollections.`);
  process.exit(0);
}

main();
