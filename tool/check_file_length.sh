#!/usr/bin/env bash
# Enforces the file-length policy from .kiro/steering/flutter-rules.md:
# ~300 lines soft (warn), ~500 hard (fail). Scans lib/**/*.dart, excluding
# generated files (*.g.dart, *.freezed.dart).
set -uo pipefail

SOFT=300
HARD=500
root="${1:-lib}"
fail=0

while IFS= read -r file; do
  case "$file" in
    *.g.dart|*.freezed.dart) continue ;;
  esac
  lines=$(wc -l < "$file")
  if [ "$lines" -gt "$HARD" ]; then
    echo "FAIL  $file: $lines lines (> $HARD hard ceiling)"
    fail=1
  elif [ "$lines" -gt "$SOFT" ]; then
    echo "warn  $file: $lines lines (> $SOFT soft ceiling)"
  fi
done < <(find "$root" -name '*.dart' | sort)

if [ "$fail" -ne 0 ]; then
  echo "Length check failed: files exceed the $HARD-line hard ceiling."
  exit 1
fi
echo "Length check passed (no file over $HARD lines)."
