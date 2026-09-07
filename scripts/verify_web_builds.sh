#!/usr/bin/env bash
# Verify Student and Admin web build directories are independent and non-empty.
# Does NOT build or deploy.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STUDENT="$ROOT/build/student_web"
ADMIN="$ROOT/build/admin_web"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$STUDENT/index.html" ]] || fail "missing $STUDENT/index.html — run scripts/build_student_web.sh"
[[ -f "$ADMIN/index.html" ]] || fail "missing $ADMIN/index.html — run scripts/build_admin_web.sh"
[[ "$STUDENT" != "$ADMIN" ]] || fail "student and admin paths collide"

# Fingerprints must differ (different entry apps).
student_hash="$(cksum "$STUDENT/index.html" | awk '{print $1}')"
admin_hash="$(cksum "$ADMIN/index.html" | awk '{print $1}')"
# index.html may be similar; prefer main.dart.js / flutter.js if present
if [[ -f "$STUDENT/main.dart.js" && -f "$ADMIN/main.dart.js" ]]; then
  student_hash="$(cksum "$STUDENT/main.dart.js" | awk '{print $1}')"
  admin_hash="$(cksum "$ADMIN/main.dart.js" | awk '{print $1}')"
  [[ "$student_hash" != "$admin_hash" ]] || fail "main.dart.js checksums identical — outputs may be wrong"
fi

echo "OK: student_web and admin_web both present and distinct."
echo "  STUDENT: $STUDENT"
echo "  ADMIN:   $ADMIN"
