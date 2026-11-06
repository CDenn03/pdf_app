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
dart run build_runner build
# Scoped to generated files on purpose: this script is meant to be run before
# committing, so the working tree is normally dirty and an unscoped `git diff`
# would fail here on unrelated edits.
if ! git diff --quiet -- '*.g.dart' '*.freezed.dart'; then
  echo "Committed generated files are stale. Run 'dart run build_runner build' and commit the result." >&2
  git --no-pager diff --stat -- '*.g.dart' '*.freezed.dart' >&2
  exit 1
fi

banner "Static analysis (flutter analyze --fatal-infos)"
flutter analyze --fatal-infos

banner "Run tests with coverage (flutter test --coverage)"
flutter test --coverage

banner "Enforce file-length policy (tool/check_file_length.sh)"
bash tool/check_file_length.sh

banner "All gates passed."
