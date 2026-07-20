#!/usr/bin/env bash
# prime.sh — SessionStart hook.
#
# Injects the self-distrust prior ONCE at session start (startup | resume |
# compact). This is the standing posture for the whole session; the per-turn
# nudge (nudge.sh) is the terse reminder that keeps it live.
#
# Output protocol: print a JSON object with
# hookSpecificOutput.additionalContext on stdout, exit 0. Best-effort — any
# failure exits 0 silently so the hook never blocks a session.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Drain stdin (hook payload) so the pipe never blocks; contents unused.
if [ ! -t 0 ]; then cat >/dev/null 2>&1 || true; fi

read -r -d '' MSG <<'EOF'
[flip-the-script] Standing prior for this session: treat your own UNVERIFIED
recall as STALE and OVERCONFIDENT until it is grounded. Training data has a
cutoff and drifts; felt-confidence is not evidence and is poorly calibrated.
Before you assert a fact that has an exact external answer — a library/API
version or signature, a current-state fact, an exact number/price/stat, a
niche or long-tail detail, a "latest/recommended", or your own "I already
checked" — VERIFY it against an external source first (read the docs/source,
search, run the code, measure) or hand it to a fresh-context check. Internal
second-guessing ALONE does not repair a wrong recall — it can talk you out of
a right answer; the repair is EXTERNAL ground truth. State unverified claims
as provisional. Calibrated, not paralytic: distrust hardest where recall is
unreliable (versions/APIs/recent/exact/long-tail); do NOT stall re-litigating
stable, well-known facts — that is its own failure mode.
EOF

printf '%s' "${MSG}" | bash "${ROOT}/scripts/run-python.sh" -c \
  'import json,sys
print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.stdin.read()}}))' \
  2>/dev/null || true

exit 0
