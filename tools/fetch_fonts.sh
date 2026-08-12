#!/usr/bin/env bash
# Net Ninja — font fetcher (macOS / Linux)
# See tools/fetch_fonts.ps1 for the why. Requires curl.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="$root/assets/fonts"
mkdir -p "$dest"

base='https://raw.githubusercontent.com/google/fonts/main/ofl'

fetch() {
  local url="$1" out_name="$2"
  local out="$dest/$out_name"
  if [[ -f "$out" ]]; then
    echo "skip  $out_name (already present)"
    return
  fi
  if curl -fsSL -o "$out" "$url"; then
    echo "ok    $out_name"
  else
    echo "warn  failed $out_name" >&2
    rm -f "$out"
  fi
}

fetch "$base/nunitosans/NunitoSans%5BYTLC%2Copsz%2Cwdth%2Cwght%5D.ttf" 'NunitoSans-Variable.ttf'
fetch "$base/spacemono/SpaceMono-Regular.ttf" 'SpaceMono-Regular.ttf'

echo
echo 'Done. Open the project in Godot once so the fonts are imported.'
