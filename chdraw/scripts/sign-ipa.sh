#!/usr/bin/env bash
# Re-sign LibrePaint's unsigned IPA with an Apple Developer account and
# optionally install it on a connected iPad. Replaces LibrePaint's
# AltStore/LiveContainer path. macOS only (codesign, security, devicectl).
#
# Usage:
#   chdraw/scripts/sign-ipa.sh --ipa IN.ipa --profile P.mobileprovision \
#       --identity "Apple Development: Name (ID)" [--out OUT.ipa] [--install DEVICE]
#
#   --ipa       unsigned IPA, e.g.
#               build-ios/nix-results/librepaint-ios-ipa/LibrePaint-iOS-unsigned.ipa
#   --profile   development or ad hoc provisioning profile that includes the
#               iPad's UDID; its App ID becomes the bundle identifier
#   --identity  signing identity name or SHA-1, from:
#               security find-identity -v -p codesigning
#   --out       signed IPA path (default: next to the input, *-signed.ipa)
#   --install   device ID or name from `xcrun devicectl list devices`
#
# Written for the bash 3.2 that ships with macOS.

set -euo pipefail

die() { echo "sign-ipa: $*" >&2; exit 1; }
usage() { sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

ipa="" profile="" identity="" out="" device=""
while [ $# -gt 0 ]; do
    case "$1" in
        --ipa) ipa=$2; shift 2 ;;
        --profile) profile=$2; shift 2 ;;
        --identity) identity=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        --install) device=$2; shift 2 ;;
        -h|--help) usage 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done
[ -n "$ipa" ] && [ -n "$profile" ] && [ -n "$identity" ] || usage 2
[ -f "$ipa" ] || die "IPA not found: $ipa"
[ -f "$profile" ] || die "profile not found: $profile"
[ "$(uname -s)" = Darwin ] || die "needs macOS"
[ -n "$out" ] || out="${ipa%.ipa}-signed.ipa"
out_abs="$(cd "$(dirname "$out")" && pwd)/$(basename "$out")"

plist() { /usr/libexec/PlistBuddy -c "$1" "$2"; }

work=$(mktemp -d "${TMPDIR:-/tmp}/sign-ipa.XXXXXX")
trap 'rm -rf "$work"' EXIT

# Entitlements and bundle ID come from the profile.
security cms -D -i "$profile" > "$work/profile.plist"
plist 'Print :Entitlements' "$work/profile.plist" >/dev/null \
    || die "cannot read entitlements from profile"
/usr/libexec/PlistBuddy -x -c 'Print :Entitlements' "$work/profile.plist" \
    > "$work/entitlements.plist"
app_id=$(plist 'Print :Entitlements:application-identifier' "$work/profile.plist")
team_id=${app_id%%.*}
bundle_id=${app_id#*.}
case "$bundle_id" in
    *'*'*) die "profile has wildcard App ID ($app_id); use an explicit App ID" ;;
esac

# Nix outputs are read-only; make the copy writable before editing.
ditto -x -k "$ipa" "$work/x"
chmod -R u+w "$work/x"
app=$(find "$work/x/Payload" -maxdepth 1 -name '*.app' -type d | head -n 1)
[ -n "$app" ] || die "no .app inside $ipa"

echo "Bundle ID: $bundle_id (team $team_id)"
plist "Set :CFBundleIdentifier $bundle_id" "$app/Info.plist"
cp "$profile" "$app/embedded.mobileprovision"
rm -rf "$app/_CodeSignature"

# Sign nested code first, deepest paths first, then the app itself.
find "$app" -mindepth 1 \( -name '*.dylib' -o -name '*.framework' -o -name '*.appex' \) -print \
    | awk '{ print length, $0 }' | sort -rn | cut -d' ' -f2- \
    | while IFS= read -r item; do
        codesign --force --sign "$identity" --timestamp=none "$item"
    done
codesign --force --sign "$identity" --timestamp=none \
    --entitlements "$work/entitlements.plist" "$app"
codesign --verify --deep --strict "$app"
echo "Signature OK"

rm -f "$out_abs"
(cd "$work/x" && zip -qry "$out_abs" Payload)
echo "Signed IPA: $out"

if [ -n "$device" ]; then
    xcrun devicectl device install app --device "$device" "$app"
    echo "Installed on $device"
fi
