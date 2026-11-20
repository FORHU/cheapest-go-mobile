#!/bin/bash
# The AirangGo release APK.
#
# The brand substitution has to be undone whatever happens: the .arb files are synced from V2
# and checked for drift in CI, so a branded one left behind fails that check and, worse, looks
# like a deliberate edit. The trap restores them on success, on failure and on Ctrl-C alike.
set -euo pipefail

cd "$(dirname "$0")/.."
# Two things to put back, not one. Restoring the .arb is not enough: the build ran gen-l10n
# against the branded ones, so lib/l10n/generated is left branded while the .arb beside it is
# not. Tests then run against AirangGo copy and fail on English expectations, which reads as a
# code regression rather than a leftover build artifact. Regenerating returns both to the
# committed state.
#
# NOTE: run this from Git Bash or CI, not  from PowerShell — there bash is WSL, which
# sees /mnt/c paths and has no Flutter on PATH (exit 127).
trap 'git checkout -- lib/l10n/ 2>/dev/null || true; flutter gen-l10n >/dev/null 2>&1 || true' EXIT

dart run tool/brand_l10n.dart AirangGo
flutter build apk --release --dart-define-from-file="${1:?pass the dart-define env file}"
