---
name: infinite-dj
description: Load before reading, changing, running or rendering anything in infinite/experiments/dj/ (the Infinite DJ - EDM, Pop, Rock, London Dubstep channels). Covers running sclang safely, sclang gotchas, the check suite and its known failing baseline, the listening-round render/package/feedback workflow, and every place a new source file or song must be registered.
---

# Infinite DJ

All paths are relative to the repository root. The DJ lives in `infinite/experiments/dj/`; the browser build (WebAssembly) is `site/` + `scripts/build_site.py`.

## Running sclang

```bash
perl -e 'alarm 240; exec @ARGV' /Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/dj/check.scd
```

- **sclang does not exit after an error**; it sits in the interpreter forever. Always wrap with the `perl alarm` line (macOS has no `timeout`). Exit code 142 = killed by the alarm.
- Scripts must exit themselves: wrap the body in `try { ...; 0.exit } { |error| error.reportError; 1.exit }` (see the end of `check.scd`). Server/UI scripts also schedule a watchdog, e.g. `SystemClock.sched(110,{ ...; 1.exit; nil })`.
- Scripts find siblings with `root=thisProcess.nowExecutingPath.dirname` and pass output dirs as an absolute argument (`"$PWD/audio/..."`).
- Language gotchas:
  - All `var` declarations must come before any statement in a block/function (a `var` after a statement is a parse error). Group them at the top, or open a nested `{ var ...; }.value`.
  - `Integer` has no `inject`; use `(1..n).inject(0,{...})` or `n.do`.
  - A parse error in a `.load`ed file only prints and returns nil — checks assert `File.readAllString(f).compile.notNil` for that reason.

## Check suite

`.claude/skills/infinite-dj/run-checks.sh [name ...]` runs `infinite/experiments/dj/<name>.scd` (default: `check.scd` plus every `*-check.scd`) sequentially under the alarm and prints PASS/FAIL, seconds and the thrown error. Full logs go to `$TMPDIR/infinite-dj-checks/<name>.log`. `TIMEOUT=300` changes the per-check limit.

```bash
.claude/skills/infinite-dj/run-checks.sh check pop-check song-styles-check
```

Kinds (first-line comment of each file says which):
- Pure engine checks (no server, seconds): `check`, `channels-check`, `e-check`, `interaction-check`, `pop-check`, `modes-check`, `variety-check`, `tension-check`, `song-styles-check`, `rock-check`, `rock-expression-check`, `rock-physical-check`, `rock-players-check`, `rock-solo-check`.
- Offline NRT signal probes: `bass-check`, `stutter-check`, `manual-fx-check`, `rock-stutter-check`, `rock-guitar-signal-check`.
- Muted native UI/server checks (boot a private server, open windows): `deck-view-check`, `spectrum-check`, `runtime-check`, `*-runtime-check`.

**Baseline: every check passes** (all 29, verified 2026-11-14; a full run takes about 10 minutes). Any failure is a regression, or a check made stale by an intended change. When a check fails, find the commit that broke it (`DJ=<other checkout>/infinite/experiments/dj run-checks.sh ...` against a `git worktree add --detach` of older commits) before editing it. Then fix either the code or the check's expectation, with a comment saying why. Never loosen a check without finding the cause.

Things that made checks stale before, worth knowing when writing new ones:
- Generated songs (EDM, Pop, Rock, Dubstep with `tonality:\original` and no pinned `palette`) open with a **drums-only intro**: 8 bars for the first EDM/Pop record, 4 otherwise. Request hooks/riffs or expect pitched parts only after `section!=\intro`. A pinned `palette:` skips the intro (`render.scd e compare` relies on this).
- Notes follow `plan.scale` (base scale, or a flagged two-bar `plan.modalAccent` colour), not a hardcoded major/minor scale.
- A chosen mode is pinned (`modalPolicy:\fixed`). Only `tonality:\original` EDM/Pop use `\tension`.
- Recall accepts only schema 8 with the current source fingerprint. Older names are rejected on purpose, so don't write replay tests for older schemas.
- Round 04 song styles are appended to the EDM/Pop palettes. Grammar checks pass `songStyles:false` to leave them out.
- Every pitched event in lanes 0–2 must stay in `plan.scale` (`check` and `tension-check` enforce this). Write melodies and bass as diatonic degrees, not fixed semitone offsets.
- Runtime waits must cover real musical time (a 16-bar Rock handover at 102 BPM is about 38 s). Compare OSC addresses with `msg[1].asString=="/d_load"`: a Symbol never equals a String. The user's startup file boots SuperDirt, so a `/d_load` failure for `superfm` and "Could not open UDP port 57120" are environment noise.
- Kill your own leftover `sclang`/`scsynth` (`ps -ef | grep -E 'sclang|scsynth'`) before rerunning runtime checks.

## Listening rounds

The user judges music by ear in fixed rounds; checks cannot replace this. Workflow (see `infinite/experiments/dj/FEEDBACK.md` for every past round's commands):

1. Render WAV + `A.json`, `B.json`... recipe files into `audio/listening-round/NN` (gitignored; it lives in the **main checkout** `/Users/eschj/Documents/SuperCollider/audio/listening-round/`, not in a worktree):
   ```bash
   mkdir -p audio/listening-round/NN
   /Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/dj/<render-script>.scd "$PWD/audio/listening-round/NN"
   ```
   Render scripts: `song-audition*.scd`, `dubstep-audition.scd`, `melodic-round/render.scd <dir> [instrumental]`, `render.scd`, `*-render.scd`.
2. Package: `python3 infinite/experiments/dj/package-audition.py audio/listening-round/NN NN[-letters]` (e.g. `04-instrumental`). It verifies 48 kHz/24-bit stereo WAVs against each recipe's `seconds`, encodes m4a and writes `listen.html`.
3. The user opens `audio/listening-round/NN/listen.html`, rates, and pastes the summary/export into chat.
4. Record verdicts as a `| ID | Song | Decision |` table under a `## Listening round NN` / `### Round NN decisions` heading in `FEEDBACK.md`, quoting the user's words where they matter.
5. Save the exact comments with the heard recipes in `audio/listening-round/NN/round-NN-feedback.json`: `{"round": "infinite-dj-listening-NN", "date": "YYYY-MM-DD", "results": [{"recipe": {...}, "vote": "approved", "comment": "..."}]}`.

Live deck 👍/👎 votes are separate: they go to `infinite/experiments/dj/feedback/` (gitignored).

## Adding a source file or song

A new `.scd` source used by the live engine must be added in **all** of:

- `infinite/experiments/dj/engine.scd` — the `(root +/+ "x.scd").load` list at the top (style/generator code). Instrument files load from `instruments.scd` instead.
- `scripts/build_site.py` — `DJ_SOURCES` (otherwise the browser build lacks it).
- `infinite/experiments/dj/recall.scd` — the fingerprint file list near the top. Saved recipes embed this hash; changing any listed file invalidates old recipe names (expected; don't "fix" it by removing files).
- SynthDefs: append to `~djDefs` (`~djDefs=~djDefs++[...]`, see `pop-instruments.scd`), or `live.scd` won't send them and renders won't include them. Instrument files outside the top folder are loaded from `instruments.scd` (e.g. `melodic-round/neon-leads/instruments.scd`) and also need the `DJ_SOURCES` and fingerprint entries.

Song styles: the approved round 04 songs (specs in `infinite/experiments/dj/melodic-round/recipes.scd`, leads in `~djSongStyleLeadChoices`, groove-free breakdowns in `~djSongStyleBareSpace`) become grammars in `song-styles.scd`. `~djSongStylePalettes` appends them to the EDM/Pop palettes in `engine.scd`, and `~djSongStyleLiveBar` generates their bars in any key, mode, form and tempo. Pass `(songStyles:false, ...)` in generator checks that must not draw those palettes. `song-styles-check` covers the styles themselves.

After changes: run the relevant checks, compare against the baseline above, then render a listening round if the sound changed.
