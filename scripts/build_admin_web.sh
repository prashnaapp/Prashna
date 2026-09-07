#!/usr/bin/env bash
# Build the Admin Flutter Web app into build/admin_web.
# Does NOT deploy. Does NOT touch build/student_web.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT="$ROOT/build/admin_web"
echo "Building ADMIN web → $OUT"
echo "Entry: lib/main_admin.dart"
flutter build web \
  -t lib/main_admin.dart \
  --output="$OUT"

test -f "$OUT/index.html"
test -d "$OUT/assets" || test -d "$OUT/flutter_assets" || test -f "$OUT/main.dart.js" || test -f "$OUT/flutter_bootstrap.js"
echo "ADMIN web build OK: $OUT"
