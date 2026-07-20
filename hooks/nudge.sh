#!/usr/bin/env bash
# nudge.sh — UserPromptSubmit hook.
#
# Keeps the self-distrust prior live before the model answers a new prompt, but
# only when the prompt is in a recall-unreliable trigger class
# (version/API/current-state/exact-number/long-tail/code). The claim-shape
# decision + a light per-session anti-nag cooldown live in hooks/lib/detect.py;
# this hook just hands it the prompt and the raw payload. The full doctrine is
# in the flip-the-script skill; this is the standing one-liner.
#
# Output protocol: detect.py prints JSON with
# hookSpecificOutput.additionalContext on stdout (or nothing, when silent);
# we exit 0. Reads (and forwards) the hook payload from stdin so the pipe never
# blocks. Best-effort — any failure exits 0 silently.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Drain stdin (hook payload) so we never block; forward it to the detector.
INPUT=""
if [ ! -t 0 ]; then INPUT="$(cat 2>/dev/null || true)"; fi
MSG="${INPUT}"

bash "${ROOT}/scripts/run-python.sh" "${ROOT}/hooks/lib/detect.py" "${MSG}" "${INPUT}" \
  2>/dev/null || true

exit 0
