#!/usr/bin/env bash
# Build the Admin Flutter Web app into build/admin_web.
# Does NOT deploy. Does NOT touch build/student_web.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT="$ROOT/build/admin_web"
echo "Cleaning ADMIN web output → $OUT"
rm -rf "$OUT"

echo "Building ADMIN web → $OUT"
echo "Entry: lib/main_admin.dart"
flutter build web \
  -t lib/main_admin.dart \
  --output="$OUT"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "FAIL: required Admin web output missing: $path" >&2
    exit 1
  fi
}

require_file "$OUT/index.html"
require_file "$OUT/main.dart.js"
require_file "$OUT/flutter_bootstrap.js"
require_file "$OUT/assets/FontManifest.json"
require_file "$OUT/assets/fonts/MaterialIcons-Regular.otf"

asset_count="$(find "$OUT/assets" -type f | wc -l | tr -d ' ')"
if [[ "$asset_count" -eq 0 ]]; then
  echo "FAIL: $OUT/assets contains no files" >&2
  exit 1
fi

echo "ADMIN web build OK: $OUT"
echo "  assets: $asset_count file(s), MaterialIcons + FontManifest present"
