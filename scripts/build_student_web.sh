#!/usr/bin/env bash
# Build the Student Flutter Web app into build/student_web.
# Does NOT deploy. Does NOT touch build/admin_web.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT="$ROOT/build/student_web"
echo "Building STUDENT web → $OUT"
echo "Entry: lib/main.dart"
flutter build web \
  -t lib/main.dart \
  --output="$OUT"

test -f "$OUT/index.html"
test -d "$OUT/assets" || test -d "$OUT/flutter_assets" || test -f "$OUT/main.dart.js" || test -f "$OUT/flutter_bootstrap.js"
echo "STUDENT web build OK: $OUT"
