#!/usr/bin/env bash
# Convert Clip Studio Paint .clip files to Krita .kra files.
#
#   .clip --(clip_to_psd.py)--> .psd --(krita --export)--> .kra
#
# Usage:
#   chdraw/scripts/clip2kra.sh [--keep-psd] [--psd-only] INPUT OUTPUT_DIR
#
#   INPUT       a .clip file, or a folder searched recursively for .clip files
#   OUTPUT_DIR  where .kra files go; subfolders mirror INPUT
#   --keep-psd  also keep the intermediate .psd next to each .kra
#   --psd-only  stop after .psd (no Krita needed)
#
# Environment overrides:
#   KRITA        path to the krita binary
#   CLIP_TO_PSD  path to clip_to_psd.py (otherwise downloaded, pinned, and
#                hash-checked into ~/.cache/chdraw/)
#
# Written for the bash 3.2 that ships with macOS.

set -euo pipefail

CLIP_TO_PSD_COMMIT="e8db68c768f52ec91ba7530820f52537261cbad0"
CLIP_TO_PSD_SHA256="f4a9f3519fdc5974e164023a4bb771488e187370b770d825a28a3a4def33ab29"
CLIP_TO_PSD_URL="https://raw.githubusercontent.com/dobrokot/clip_to_psd/${CLIP_TO_PSD_COMMIT}/clip_to_psd.py"

die() { echo "clip2kra: $*" >&2; exit 1; }

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

keep_psd=0
psd_only=0
while [ $# -gt 0 ]; do
    case "$1" in
        --keep-psd) keep_psd=1; shift ;;
        --psd-only) psd_only=1; shift ;;
        -h|--help) usage 0 ;;
        --) shift; break ;;
        -*) die "unknown option: $1" ;;
        *) break ;;
    esac
done
[ $# -eq 2 ] || usage 2

input=$1
out_dir=$2
[ -e "$input" ] || die "input not found: $input"

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1
    else
        shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

find_clip_to_psd() {
    if [ -n "${CLIP_TO_PSD:-}" ]; then
        [ -f "$CLIP_TO_PSD" ] || die "CLIP_TO_PSD not found: $CLIP_TO_PSD"
        echo "$CLIP_TO_PSD"
        return
    fi
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/chdraw"
    local script="$cache/clip_to_psd-${CLIP_TO_PSD_COMMIT:0:12}.py"
    if [ ! -f "$script" ]; then
        mkdir -p "$cache"
        echo "Downloading clip_to_psd.py (${CLIP_TO_PSD_COMMIT:0:12})..." >&2
        curl -fsSL "$CLIP_TO_PSD_URL" -o "$script.tmp" || die "download failed: $CLIP_TO_PSD_URL"
        mv "$script.tmp" "$script"
    fi
    [ "$(sha256_of "$script")" = "$CLIP_TO_PSD_SHA256" ] \
        || die "hash mismatch for $script; delete it and retry"
    echo "$script"
}

find_krita() {
    if [ -n "${KRITA:-}" ]; then
        [ -x "$KRITA" ] || die "KRITA is not executable: $KRITA"
        echo "$KRITA"
    elif command -v krita >/dev/null 2>&1; then
        command -v krita
    elif [ -x /Applications/krita.app/Contents/MacOS/krita ]; then
        echo /Applications/krita.app/Contents/MacOS/krita
    else
        die "krita not found; install it or set KRITA=/path/to/krita"
    fi
}

command -v python3 >/dev/null 2>&1 || die "python3 not found"
clip_to_psd=$(find_clip_to_psd)
krita=""
[ "$psd_only" -eq 1 ] || krita=$(find_krita)

# Pillow is optional; without it, skip the PSD thumbnail.
preview_flag=""
python3 -c 'import PIL' >/dev/null 2>&1 || preview_flag="--blank-psd-preview"

mkdir -p "$out_dir"
log="$out_dir/clip2kra.log"
: > "$log"
work=$(mktemp -d "${TMPDIR:-/tmp}/clip2kra.XXXXXX")
trap 'rm -rf "$work"' EXIT

if [ -d "$input" ]; then
    in_root=${input%/}
else
    in_root=$(dirname "$input")
fi

ok=0
failed=0

convert_one() {
    local clip=$1
    local rel=${clip#"$in_root"/}
    local base=${rel%.*}
    local psd kra
    kra="$out_dir/$base.kra"
    if [ "$psd_only" -eq 1 ] || [ "$keep_psd" -eq 1 ]; then
        psd="$out_dir/$base.psd"
    else
        psd="$work/$base.psd"
    fi
    mkdir -p "$(dirname "$psd")" "$(dirname "$kra")"

    echo "== $rel" >> "$log"
    # shellcheck disable=SC2086  # preview_flag is empty or a single word
    if ! python3 -I "$clip_to_psd" $preview_flag --log-level WARNING \
            "$clip" -o "$psd" >> "$log" 2>&1; then
        echo "FAIL (clip -> psd): $rel" | tee -a "$log" >&2
        return 1
    fi
    if [ "$psd_only" -eq 1 ]; then
        echo "ok: $rel -> ${psd#"$out_dir"/}"
        return 0
    fi
    if ! "$krita" "$psd" --export --export-filename "$kra" >> "$log" 2>&1 \
            || [ ! -s "$kra" ]; then
        echo "FAIL (psd -> kra): $rel" | tee -a "$log" >&2
        return 1
    fi
    echo "ok: $rel -> ${kra#"$out_dir"/}"
}

while IFS= read -r -d '' clip; do
    if convert_one "$clip"; then
        ok=$((ok + 1))
    else
        failed=$((failed + 1))
    fi
done < <(
    if [ -d "$input" ]; then
        find "$in_root" -type f -iname '*.clip' -print0
    else
        printf '%s\0' "$input"
    fi
)

[ $((ok + failed)) -gt 0 ] || die "no .clip files found in $input"
echo "Done: $ok converted, $failed failed. Log: $log"
[ "$failed" -eq 0 ]
