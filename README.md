<div align="center">

# Flip The Script

**A standing self-distrust prior for Claude Code** — treats unverified recall as stale and overconfident, and routes any version/API/current-state/exact-number/long-tail claim to external ground truth before asserting.

[![plugin-validate](https://github.com/88plug/flip-the-script/actions/workflows/plugin-validate.yml/badge.svg)](https://github.com/88plug/flip-the-script/actions/workflows/plugin-validate.yml)
[![License: FSL-1.1-ALv2](https://img.shields.io/badge/license-FSL--1.1--ALv2-blue?style=flat)](LICENSE)
[![Docs](https://img.shields.io/badge/docs-online-blue?style=flat)](https://88plug.github.io/flip-the-script/)
[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-8A2BE2?style=flat)](https://github.com/88plug/claude-code-plugins)
[![DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/88plug/flip-the-script)

</div>

Flip The Script inverts the default posture: assume your own unverified recall is
wrong until an external source says otherwise. Not because everything the model
knows is false — because the class of fact engineering work most often needs (a
version, an API signature, a current default, an exact number) is exactly the
class where training-cutoff drift and overconfidence bite hardest, and where a
confident-wrong answer costs the most.

## Install

### Claude Code

```text
/plugin marketplace add 88plug/claude-code-plugins
/plugin install flip-the-script@88plug
```

### Grok Build

```text
grok plugin marketplace add 88plug/claude-code-plugins
grok plugin install flip-the-script@88plug --trust
```

The hooks and skill load automatically from the manifest once the plugin is
enabled. No MCP server, no database, no dependencies beyond `python3` (already
present with Claude Code).

## What it does

Two hooks install the prior; the skill is the procedure when the prior catches
something.

| Hook | Event | What it does |
|---|---|---|
| `prime.sh` | `SessionStart` | Injects the full self-distrust posture once per session |
| `nudge.sh` | `UserPromptSubmit` | Terse per-turn reminder that keeps the prior live |

The deep procedure — the recall-reliability map and the source-routing rules —
lives in the bundled **`flip-the-script` skill**, which triggers when you are
about to assert something from memory.

## The one idea that makes it work

Internal self-doubt *alone* does not fix a wrong recall. Measured: intrinsic
self-correction without external feedback degrades accuracy (Huang et al.,
*LLMs Cannot Self-Correct Reasoning Yet*, ICLR 2024 — GPT-4 on GSM8K
95.5 → 91.5 → 89.0% over two "reconsider" rounds, then 97.5% with external
feedback). "Are you sure?" with no new input biases the model toward changing an
already-correct answer. The fix is **external**: read the docs/source, search,
measure, or hand it to a fresh context. Distrust only pays when it triggers
external retrieval.

## Calibrated, not paralytic

A flat "I'm always wrong" is its own failure mode — it stalls on the obvious and
buries the real signal. This plugin distrusts *in proportion*: hard on
versions/APIs/current-state/exact-numbers/long-tail and your own "already
checked", quiet on stable well-known facts and things already verified this
session.

## Composes with

- **read-the-damn-docs** — the primary verification route for version/API/library claims.
- **break-dogma** — tests *inherited external* assumptions; flip-the-script tests *your own internal* recall.
- **scientific-method** — a distrusted performance/correctness claim becomes a probe to measure.

## Test

```bash
bash tests/smoke.sh   # verifies both hooks emit valid hook JSON
```

## License

FSL-1.1-ALv2.
