#!/usr/bin/env bash
# smoke.sh — verify the hooks behave:
#   * prime.sh injects a valid SessionStart additionalContext;
#   * nudge.sh FIRES on a trigger-class prompt (valid UserPromptSubmit JSON);
#   * nudge.sh stays SILENT on a mechanical prompt (no output);
#   * a back-to-back same-session repeat is SUPPRESSED by the cooldown.
# Python is resolved via scripts/run-python.sh (thin-PATH safe).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY="${ROOT}/scripts/run-python.sh"
fail=0

# Isolate cooldown state in a fresh dir so runs are deterministic + leave no /tmp
# residue. detect.py prefers CLAUDE_PLUGIN_DATA over XDG_RUNTIME_DIR / /tmp.
DATA_DIR="$(mktemp -d 2>/dev/null)"
export CLAUDE_PLUGIN_DATA="${DATA_DIR}"
unset GROK_PLUGIN_DATA 2>/dev/null || true
cleanup() { [ -n "${DATA_DIR:-}" ] && [ -d "${DATA_DIR}" ] && rm -rf "${DATA_DIR}"; }
trap cleanup EXIT

run_hook() { printf '%s' "$2" | bash "${ROOT}/hooks/$1" 2>/dev/null; }

# assert a hook emitted valid JSON with the expected event + non-empty context
assert_fires() {
  local name="$1" script="$2" event="$3" stdin="$4"
  local out rc
  out="$(run_hook "${script}" "${stdin}")"; rc=$?
  if [ "${rc}" -ne 0 ]; then echo "FAIL ${name}: exit ${rc}"; fail=1; return; fi
  printf '%s' "${out}" | bash "${PY}" -c '
import json,sys
d=json.load(sys.stdin)
o=d["hookSpecificOutput"]
assert o["hookEventName"]==sys.argv[1], o.get("hookEventName")
ctx=o["additionalContext"]
assert isinstance(ctx,str) and len(ctx)>40, "context too short"
assert "flip-the-script" in ctx
' "${event}" 2>/dev/null \
    && echo "PASS ${name}" \
    || { echo "FAIL ${name}: bad JSON/context: ${out}"; fail=1; }
}

# assert a hook stayed silent (exit 0, no stdout)
assert_silent() {
  local name="$1" script="$2" stdin="$3"
  local out rc
  out="$(run_hook "${script}" "${stdin}")"; rc=$?
  if [ "${rc}" -ne 0 ]; then echo "FAIL ${name}: exit ${rc}"; fail=1; return; fi
  if [ -z "${out}" ]; then echo "PASS ${name}"; else echo "FAIL ${name}: expected silence, got: ${out}"; fail=1; fi
}

# prime injects once at session start
assert_fires "prime (SessionStart)" prime.sh SessionStart \
  '{"session_id":"smoke-prime","hook_event_name":"SessionStart"}'

# nudge fires on a trigger-class (version) prompt — fresh session id
assert_fires "nudge fires on trigger class" nudge.sh UserPromptSubmit \
  '{"session_id":"smoke-fire","prompt":"what version of react is latest"}'

# nudge stays silent on a mechanical prompt — fresh session id
assert_silent "nudge silent on mechanical" nudge.sh \
  '{"session_id":"smoke-mech","prompt":"reformat this paragraph and rename the file"}'

# back-to-back same-session trigger prompt is suppressed by the cooldown.
# first fire primes the marker...
assert_fires "nudge fires (repeat setup)" nudge.sh UserPromptSubmit \
  '{"session_id":"smoke-repeat","prompt":"which api signature does the sdk default to"}'
# ...second same-session trigger prompt must be suppressed.
assert_silent "nudge suppresses back-to-back repeat" nudge.sh \
  '{"session_id":"smoke-repeat","prompt":"what is the latest default flag value"}'

# jq-free manifest sanity: hooks + skills keys present
bash "${PY}" -c '
import json,sys
m=json.load(open(sys.argv[1]))
assert m["name"]=="flip-the-script"
assert "SessionStart" in m["hooks"] and "UserPromptSubmit" in m["hooks"]
assert m["skills"]=="./skills"
print("PASS manifest")
' "${ROOT}/.claude-plugin/plugin.json" || fail=1

exit "${fail}"
