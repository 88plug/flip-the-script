---
name: flip-the-script
description: >-
  Use when about to assert a fact that has an exact external answer and the
  answer came from memory rather than a checked source — a library/API version
  or signature, a current-state or "latest/recommended" claim, an exact
  number/price/stat/date, a niche or long-tail detail, or a "yes that works /
  I already checked" you cannot point to evidence for. Also use whenever you
  notice felt-certainty standing in for a source, or you are about to declare
  something fixed/done/correct without a re-run. The move: treat unverified
  recall as stale + overconfident by default, classify whether the claim is in
  a reliable or unreliable recall domain, and route the unreliable ones to
  EXTERNAL ground truth (read-the-damn-docs, search, read the source, measure,
  or a fresh-context check) before asserting — not to internal second-guessing.
  Reach for it by default before any version/API/current-state/exact claim;
  skip it for stable well-known facts and settled, already-verified things
  (re-litigating those is its own failure mode).
---

# Flip The Script

The default posture is inverted: **assume your own unverified recall is wrong
until an external source says otherwise.** Not because everything you know is
false — because the class of thing engineering work most often needs (a version,
an API signature, a current default, an exact number) is exactly the class where
training-cutoff drift and overconfidence bite hardest, and where a confident
wrong answer is expensive. The companion plugin fires this prior every turn; this
skill is the procedure when the prior actually catches something.

**The whole point — read this first, it is measured.** Internal self-doubt
*alone* does not fix a wrong recall — it can make it worse. Huang et al., *LLMs
Cannot Self-Correct Reasoning Yet* (ICLR 2024), found intrinsic self-correction
without external feedback **degrades** accuracy: GPT-4 on GSM8K went
95.5 → 91.5 → 89.0% over two "reconsider" rounds — but rose to 97.5% with
*external/oracle* feedback. The mechanism: the context that made the error shares
its blindspot, confidence *correlates* with the error, and "are you sure?" biases
toward changing already-correct answers. The repair is **external ground truth**:
the docs, the source, a search, a measurement, or a fresh context that never saw
your first answer. Distrust routed inward is measurably worse than useless;
distrust that triggers external retrieval is the whole gain — FreshPrompt lifted
current-events accuracy +32.6–49.0%, and grounded error is 1.8–5% vs >60%
closed-book. Route to a source, don't re-question yourself.

## The procedure

1. **Notice the tell.** You are about to state something as fact and the source
   is *memory*, not a thing you just checked. Tells: a version number, a flag, an
   API shape, "the latest is…", "X supports Y", an exact figure, "that should
   work", "I already verified this earlier". Felt-certainty is the loudest tell —
   confidence is not evidence and is poorly calibrated, so a *strong* feeling of
   knowing is a reason to check, not a reason to skip.

2. **Classify the recall domain** (this keeps the skill calibrated, not
   paralytic — see the reliability map below). Unreliable domain → distrust hard,
   go to step 3. Reliable domain (stable well-known fact, classic algorithm, math
   identity) → proceed, do not stall.

3. **Route to the RIGHT external source** — match the source to the claim:
   - version / API / library / config / "latest" → `read-the-damn-docs`
     (official docs + the installed version) or `context7`.
   - current state of a file/system/process/repo → read it / run the probe now
     (don't recall what it "was").
   - a performance / behavior / correctness claim → **measure it** (bench, test,
     repro) — the number, not the intuition.
   - a fact about the wider world / recent events → search (cite the source +
     date).
   - your own prior "I checked / it's fixed" → re-run the real check this turn;
     a fix is not done until a fresh run proves it.
   - a judgment call you can't ground in a source → hand it to a **fresh-context
     agent** (a refuter / independent reviewer), not to yourself re-reading your
     own reasoning.

4. **State the result as evidence, not feeling.** After grounding: assert with the
   source. Before grounding, if you must speak: mark it *provisional / unverified*
   explicitly. "The default is X (verified against the v2.3 docs)" or "I believe X
   but haven't checked — treat as provisional."

## Recall reliability map (measured)

Where ungrounded recall is trustworthy vs where it is not — with the measured
wrong-rate that sets the posture. In the slice engineering actually lives in —
versions, APIs, current-state, exact numbers, niche entities, code — ungrounded
recall is wrong **60–88% of the time** (SimpleQA >60%, FreshQA 68%+, legal case
law 58–88%). That is the regime this skill defends. Recall is only reliable on
stable, high-frequency facts (classic algorithms, math, well-known head facts) —
so distrust in proportion, hard where the numbers below are bad.

| Recall domain | Measured error (ungrounded) | Posture |
|---|---|---|
| Library/API versions, signatures, flags, defaults | ~20% API misuse; 19.7% phantom packages | Verify — docs/installed version, *before* writing |
| Current state / "latest" / prices (post-cutoff) | 68%+ wrong; drops **below** 50% random as time passes | Read/probe/search now; never recall |
| Exact numbers, stats, dates, citations | SimpleQA regime: GPT-4o <40% correct (>60% wrong) | Verify the figure at its primary source |
| Niche / long-tail / rarely-seen entities | accuracy ∝ training-doc count (collapses on the tail) | Verify; long-tail recall is weakest |
| Generated code calling external APIs/packages | ~20% API-knowledge-conflict; ~20% phantom imports | Confirm the symbol/package exists before shipping |
| Your own earlier "checked / fixed / works" | self-review corrupted by shared blindspot + self-preference | Re-run the real check this turn |
| Stable, widely-known facts | TriviaQA/NQ saturate ~90%+ | Proceed |
| Classic algorithms, data structures, math identities | benchmark-saturated | Proceed |
| Grounded against a provided source | 1.8–5% (HHEM) | Trust the grounded answer |

The rule behind the map: recall fails where the truth *changes* (versions,
current state, prices) or is *rarely seen* (long-tail, niche), and holds where
the truth is *stable and frequent*. The gap is ~15–30× (2–5% grounded vs >60%
closed-book) — so the error is **retrieval failure, not reasoning failure**,
which is why the fix is retrieval, not rumination.

## Citations (the numbers above)

| Finding | Source | Number |
|---|---|---|
| Short fact-seeking recall | SimpleQA — Wei et al., arXiv 2411.04368 (2024) | GPT-4o <40% correct |
| Current/fast-changing facts | FreshQA/FreshLLMs — Vu et al., arXiv 2310.03214 (2023) | 0.8–32% strict; +32.6–49% with search |
| Self-correction hurts | Huang et al., ICLR 2024, arXiv 2310.01798 | GSM8K 95.5→91.5→89.0% (external → 97.5%) |
| Phantom packages | Spracklen et al., USENIX Sec 2025, arXiv 2406.10279 | 19.7% nonexistent |
| API-knowledge conflict | ISSTA 2025, arXiv 2409.20550 | 20.4% |
| Long-tail collapse | Kandpal et al., ICML 2023, arXiv 2211.08411 | accuracy ∝ doc count |
| Grounded error floor | Vectara HHEM leaderboard | 1.8–5% |
| Overconfidence post-RLHF | GPT-4 Technical Report (2023) | ECE 0.007 → 0.074 |
| Verify-don't-ruminate | Chain-of-Verification — Dhuliawala et al., arXiv 2309.11495 (2023) | Wikidata precision 0.17→0.36 |

Bottom line: distrust only pays when it **triggers external retrieval**. Route,
don't ruminate — and don't stall on settled facts.

## When NOT to flip (the guard against paralysis)

Distrust is a tool, not a tic. Over-verifying has real cost — latency, and
re-litigating settled facts erodes trust as much as a confident-wrong answer.

- **Stable / well-known / version-insensitive** → answer directly.
- **Already verified this session** → don't re-verify the same fact; cite the
  earlier check.
- **Low-stakes and easily reversible** → a provisional answer marked as such is
  fine; don't gate everything.
- **The user explicitly wants a quick take, not a researched answer** → give it,
  labeled as unverified.

A flat "I'm always wrong" is itself a dogma — it produces paralysis and buries
the real signal. The skill is *calibrated* distrust: hard where recall fails,
quiet where it doesn't.

## Composes with

- `read-the-damn-docs` — the primary external-verification route for anything
  version/API/library.
- `break-dogma` — that tests *inherited external* assumptions; this tests *your
  own internal* recall. Sibling priors, both routing to measured ground truth.
- `scientific-method` — a distrusted performance/correctness claim becomes a
  falsification probe: measure it.

## Summary

Assume unverified recall is stale, classify the claim, and for the unreliable
classes (versions, APIs, current-state, exact numbers, niche, code) get an
external source before asserting. Certainty is not evidence.
