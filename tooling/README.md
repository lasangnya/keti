# keti tooling

Firebase-side tooling for the study prototype.

## Firestore rules tests (Emulator Suite)

Validates every branch of `../firestore.rules` (participant vs admin access,
activeDay gate, session/event field whitelists, catch-all).

Requirements: Java **21+** (firebase-tools emulators refuse older JDKs) and
`npm install` once.

```sh
npm install
# Homebrew JDK example — any JDK >= 21 works:
export JAVA_HOME=/opt/homebrew/opt/openjdk@26/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"

npm run test:rules
```

`test:rules` wraps `firebase emulators:exec --only auth,firestore`, so the
emulators start and stop around the suite automatically.

## Console setup status

- Firestore database `(default)` created in **europe-west3** via
  `firebase firestore:databases:create "(default)" --location europe-west3`.
- `firestore.rules` deployed via `firebase deploy --only firestore:rules`.
- **Manual step remaining:** enable the Anonymous sign-in provider in the
  Firebase console (Authentication → Sign-in method → Anonymous → Enable).
  The CLI cannot toggle auth providers. Needed before any real-device run.
