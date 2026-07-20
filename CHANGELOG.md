# Changelog

## 2026.7.20a

- `nudge.sh` now fires only on recall-unreliable trigger-class prompts
  (version/API/current-state/exact-number/long-tail/code) instead of every
  turn, via `hooks/lib/detect.py`; a light per-session cooldown suppresses a
  back-to-back same-session repeat so it steers without nagging.
- Added `scripts/run-python.sh`, a thin-PATH Python ≥3.10 resolver; both hooks
  route every Python invocation through it (Claude's hook spawn PATH is thin).
- Added the `/flip-the-script:check` slash command (`commands/check.md`) for
  manual, on-demand self-distrust checks on a claim.

## 2026.7.20

- Initial release: standing self-distrust prior for Claude Code. A `SessionStart`
  hook (`prime.sh`) injects the posture once per session; a `UserPromptSubmit`
  hook (`nudge.sh`) keeps it live every turn. The `flip-the-script` skill carries
  the recall-reliability map and the source-routing procedure. No MCP server, no
  database, no dependencies beyond `python3`.
