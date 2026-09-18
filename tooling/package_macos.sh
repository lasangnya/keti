#!/usr/bin/env bash
#
# Builds a distributable macOS disk image (DMG) for keti.
#
# Basic (no Apple certificate):
#   tooling/package_macos.sh
#   → dist/keti-<version>.dmg
#
# The default build is re-signed *ad-hoc*: the team's development provisioning
# profile is stripped, so the app carries no device list and never expires, and
# participants only have to clear the download quarantine flag once (see README
# "Packaging / distribution").
#
# Signed + notarized (recommended when participants install on their own Macs;
# requires an Apple Developer Program membership and a "Developer ID
# Application" certificate):
#
#   # one-time: store notarization credentials in the login keychain
#   xcrun notarytool store-credentials "keti-notary" \
#     --apple-id "<you@example.com>" --team-id "HSGB29ANBA" \
#     --password "<app-specific-password>"
#
#   MACOS_SIGN_IDENTITY="Developer ID Application: <Your Name> (HSGB29ANBA)" \
#   MACOS_NOTARY_PROFILE="keti-notary" \
#   tooling/package_macos.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="keti"
APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
ENTITLEMENTS="macos/Runner/Release.entitlements"
DIST_ENTITLEMENTS="macos/Runner/Distribution.entitlements"
INSTALL_DOC="docs/participant-install.md"
DIST_DIR="dist"

VERSION="$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)"
DMG_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}.dmg"

echo "==> Building macOS release (${APP_NAME} ${VERSION})…"
flutter build macos --release

if [ ! -d "$APP_PATH" ]; then
  echo "error: expected app bundle at $APP_PATH" >&2
  exit 1
fi

if [ ! -f "$INSTALL_DOC" ]; then
  echo "error: expected participant install guide at $INSTALL_DOC" >&2
  exit 1
fi

# ── Code-sign the app ───────────────────────────────────────────────────
# Developer ID → hardened runtime + timestamp, ready for notarization.
# No Developer ID → re-sign ad-hoc.
#
# `flutter build macos --release` signs with the team's *development*
# provisioning profile. That profile only authorises the Macs registered to the
# team, and on a free personal team it expires every 7 days. Once it expires
# macOS refuses to spawn the process at all — the app launches on nobody's Mac
# ("Launchd job spawn failed", POSIX error 163). Stripping the profile and
# re-signing ad-hoc drops both the device list and the expiry.
if [ -n "${MACOS_SIGN_IDENTITY:-}" ]; then
  echo "==> Signing app with: ${MACOS_SIGN_IDENTITY}"
  # --deep is acceptable here; for a stricter build, sign nested binaries
  # inside-out instead (or use `xcodebuild -exportArchive`).
  codesign --deep --force --options runtime --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$MACOS_SIGN_IDENTITY" "$APP_PATH"
  codesign --verify --deep --strict --verbose=2 "$APP_PATH"
else
  echo "==> No Developer ID — re-signing ad-hoc for distribution."
  # Distribution.entitlements omits the team-scoped keys from
  # Release.entitlements; an ad-hoc signature cannot carry a provisioning
  # profile, and those keys require one.
  rm -f "$APP_PATH/Contents/embedded.provisionprofile"
  codesign --force --deep --sign - \
    --entitlements "$DIST_ENTITLEMENTS" "$APP_PATH"
  codesign --verify --deep --strict --verbose=2 "$APP_PATH"
  # `spctl --assess` will report "rejected" for an ad-hoc signature. That is
  # expected: Gatekeeper only consults spctl for quarantined downloads, which
  # participants clear once (README "Packaging / distribution").
fi

# ── Build the DMG with the standard drag-to-Applications layout ─────────
echo "==> Creating ${DMG_PATH}"
mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
ditto "$APP_PATH" "$STAGE/${APP_NAME}.app"
ln -s /Applications "$STAGE/Applications"
cp "$INSTALL_DOC" "$STAGE/Install keti.md"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE" \
  -ov -format UDZO \
  "$DMG_PATH"

# Ship a checksum next to the dmg so a truncated transfer is distinguishable
# from a signing problem before anyone starts debugging codesign.
( cd "$DIST_DIR" && shasum -a 256 "$(basename "$DMG_PATH")" > "$(basename "$DMG_PATH").sha256" )

# ── Optional: sign the dmg, notarize it, and staple the ticket ─────────
if [ -n "${MACOS_NOTARY_PROFILE:-}" ]; then
  if [ -z "${MACOS_SIGN_IDENTITY:-}" ]; then
    echo "error: MACOS_NOTARY_PROFILE requires MACOS_SIGN_IDENTITY" >&2
    exit 1
  fi
  echo "==> Signing the dmg"
  codesign --force --timestamp --sign "$MACOS_SIGN_IDENTITY" "$DMG_PATH"

  echo "==> Notarizing (this can take a few minutes)…"
  xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$MACOS_NOTARY_PROFILE" --wait

  echo "==> Stapling the notarization ticket"
  xcrun stapler staple "$DMG_PATH"
  spctl --assess --type open --context context:primary-signature -v "$DMG_PATH" || true
fi

echo
echo "Done: ${DMG_PATH}"
if [ -n "${MACOS_NOTARY_PROFILE:-}" ]; then
  echo "  Signed + notarized — participants can open it with a double-click."
elif [ -n "${MACOS_SIGN_IDENTITY:-}" ]; then
  echo "  Signed with a Developer ID but NOT notarized — participants must still"
  echo "  approve it once (README 'Packaging / distribution')."
else
  echo "  Ad-hoc signed — participants must clear the quarantine flag once"
  echo "  (README 'Packaging / distribution')."
fi
echo "  Install guide in the dmg: 'Install keti.md'"
echo "  Checksum beside the dmg: $(basename "$DMG_PATH").sha256"
