/**
 * Grants the `admin: true` custom claim to a Firebase Auth user by email.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node tooling/set_admin.js researcher@example.com
 *
 * Prerequisites:
 *   npm install firebase-admin
 *   The user must already exist in Firebase Auth.
 */

const admin = require('firebase-admin');

const email = process.argv[2];
if (!email) {
  console.error('Usage: node set_admin.js <email>');
  process.exit(1);
}

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.warn(
    'WARNING: GOOGLE_APPLICATION_CREDENTIALS is not set. ' +
      'This script needs a service-account key for the keti project.',
  );
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'keti-fcfd6',
});

async function main() {
  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    console.log(`SUCCESS: admin claim set for ${user.email} (${user.uid}).`);
  } catch (e) {
    console.error(`ERROR: ${e.message}`);
    process.exit(1);
  }
  process.exit(0);
}

main();
