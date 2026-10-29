#!/usr/bin/env bash
#
# Local mirror of .github/workflows/ci.yml. Runs the identical quality gates in
# the identical order, so a green run here means a green CI run. Fails on the
# first gate that exits non-zero.
#
# Run from the repository root:  bash tool/check.sh
set -euo pipefail

banner() { printf '\n==> %s\n' "$1"; }

banner "Install dependencies (flutter pub get)"
flutter pub get

banner "Verify committed generated files are not stale (build_runner)"
dart run build_runner build --delete-conflicting-outputs
if ! git diff --quiet; then
  echo "Committed generated files are stale. Run 'dart run build_runner build --delete-conflicting-outputs' and commit the result." >&2
  git --no-pager diff --stat >&2
  exit 1
fi

banner "Static analysis (flutter analyze --no-fatal-infos)"
flutter analyze --no-fatal-infos

banner "Run tests with coverage (flutter test --coverage)"
flutter test --coverage

banner "Enforce file-length policy (tool/check_file_length.sh)"
bash tool/check_file_length.sh

banner "All gates passed."
