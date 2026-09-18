/**
 * Shared config for the Firebase admin tooling.
 *
 * The Firebase project id is a PUBLIC identifier, not a secret — it ships
 * inside every client build. The tooling reads it from the local, gitignored
 * ../.firebaserc (copy ../.firebaserc.example first), so it can never drift
 * from whatever `firebase use` / `firebase deploy` target.
 *
 * Point the scripts at another project without editing any file, e.g. a fork:
 *   KETI_FIREBASE_PROJECT_ID=my-other-project node tooling/export.js
 */

const fs = require('node:fs');
const path = require('node:path');

/** Reads the default project id from the repo-root `.firebaserc`. */
function fromFirebaserc() {
  try {
    const raw = fs.readFileSync(path.join(__dirname, '..', '.firebaserc'), 'utf8');
    const parsed = JSON.parse(raw);
    return parsed?.projects?.default;
  } catch {
    return undefined;
  }
}

const projectId = process.env.KETI_FIREBASE_PROJECT_ID || fromFirebaserc();

if (!projectId) {
  console.error(
    'ERROR: no Firebase project id. Create .firebaserc (copy ' +
      '.firebaserc.example) with projects.default set, or export ' +
      'KETI_FIREBASE_PROJECT_ID.',
  );
  process.exit(1);
}

module.exports = { projectId };
