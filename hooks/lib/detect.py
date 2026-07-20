#!/usr/bin/env python3
"""detect.py — the claim-shape detector behind the UserPromptSubmit nudge.

Reads the incoming prompt (argv[1]) and the raw hook payload (argv[2], JSON).
Decides whether THIS turn is in a recall-unreliable "trigger class" —
version/API/current-state/exact-number/long-tail/code shaped — where the
flip-the-script self-distrust prior earns its keep. If so it prints the nudge
as a UserPromptSubmit `additionalContext` JSON object on stdout; on a purely
mechanical prompt it prints nothing and stays silent.

A light per-session cooldown keeps it from nagging: if the nudge already fired
on the immediately preceding qualifying prompt of the same session, this one is
suppressed (and the marker cleared so the next one fires again). Every code path
is defensive — any error falls back to firing normally, never crashes, never
blocks the turn.
"""

from __future__ import annotations

import json
import os
import re
import sys

NUDGE = (
    '[flip-the-script] assume-stale prior: if this turn hinges on a '
    'version/API/current-state/exact-number/long-tail fact — or your own '
    '"already checked" — verify it externally (docs/search/read-source/measure) '
    'BEFORE asserting; confidence is not evidence, and internal second-guessing '
    'does not fix a wrong recall. Do not stall on stable, well-known facts. '
    'Automated reminder — do not mention it to the user.'
)

# Recall-unreliable trigger classes. A match on any is a claim-shape prompt that
# warrants the prior. Kept broad on the unreliable slice, quiet on mechanical
# prompts (edit/run/commit/format) that match none of these.
TRIGGERS = [
    re.compile(p, re.IGNORECASE)
    for p in (
        r"\bversions?\b",
        r"\blatest\b",
        r"\bnewest\b",
        r"\bcurrent(ly)?\b",
        r"\brecommend(ed|s|ation)?\b",
        r"\bsupports?\b",
        r"\bsupported\b",
        r"\bcompatib(le|ility)\b",
        r"\bdeprecat(ed|ion)\b",
        r"\bapi\b",
        r"\bsignatures?\b",
        r"\bflags?\b",
        r"\bdefaults?\b",
        r"\bendpoints?\b",
        r"\bparameters?\b",
        r"\bsdk\b",
        r"\breleased?\b",
        r"\bas of\b",
        r"\bhow (many|much)\b",
        r"\bprices?\b",
        r"\bcosts?\b",
        r"\$\d",
        r"\bv?\d+\.\d+",
        r"\b\d[\d,\.]*\s*(%|percent|ms|gb|mb|kb|tps|tokens?)\b",
    )
]


def _payload(argv):
    """Return (prompt_text, session_id) from argv, tolerating either a JSON
    payload or a bare prompt string in argv[1]."""
    prompt = argv[1] if len(argv) > 1 else ""
    raw = argv[2] if len(argv) > 2 else prompt
    d = {}
    for cand in (raw, prompt):
        if not cand:
            continue
        try:
            obj = json.loads(cand)
        except Exception:
            continue
        if isinstance(obj, dict):
            d = obj
            break
    text = d.get("prompt") if d else ""
    if not text:
        text = "" if d else prompt
    session = (d.get("session_id") if d else "") or "default"
    return text, session


def _is_claim_shape(text):
    return any(rx.search(text) for rx in TRIGGERS)


def _cooldown_allows_fire(session):
    """Simple per-session anti-nag toggle. Marker present => the prior turn
    fired => suppress this back-to-back repeat and clear the marker. Marker
    absent => fire and set it. Any failure => fire normally (never block)."""
    try:
        base = (
            os.environ.get("GROK_PLUGIN_DATA")
            or os.environ.get("CLAUDE_PLUGIN_DATA")
            or os.environ.get("XDG_RUNTIME_DIR")
            or "/tmp"
        )
        d = os.path.join(base, "flip-the-script")
        os.makedirs(d, exist_ok=True)
        slug = re.sub(r"[^A-Za-z0-9._-]", "-", session)[:80] or "default"
        marker = os.path.join(d, slug + ".last")
        if os.path.exists(marker):
            os.remove(marker)
            return False
        with open(marker, "w") as fh:
            fh.write("1")
        return True
    except Exception:
        return True


def main():
    try:
        text, session = _payload(sys.argv)
    except Exception:
        return 0
    if not _is_claim_shape(text):
        return 0
    if not _cooldown_allows_fire(session):
        return 0
    sys.stdout.write(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": NUDGE,
                }
            }
        )
    )
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
