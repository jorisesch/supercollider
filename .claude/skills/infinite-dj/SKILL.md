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

`.claude/skills/infinite-dj/run-checks.sh [name ...]` runs `infinite/experiments/dj/<name>.scd` (default: `check.scd` plus every `*-check.scd`) sequentially under the alarm and prints PASS/FAIL, seconds and the first `ERROR`/`FAIL` line. Full logs go to `$TMPDIR/infinite-dj-checks/<name>.log`. `TIMEOUT=300` changes the per-check limit.

```bash
.claude/skills/infinite-dj/run-checks.sh check pop-check fixed-songs-check
```

Kinds (first-line comment of each file says which):
- Pure engine checks (no server, seconds): `check`, `channels-check`, `e-check`, `interaction-check`, `pop-check`, `modes-check`, `variety-check`, `tension-check`, `fixed-songs-check`, `rock-check`, `rock-expression-check`, `rock-physical-check`, `rock-players-check`, `rock-solo-check`.
- Offline NRT signal probes: `bass-check`, `stutter-check`, `manual-fx-check`, `rock-stutter-check`, `rock-guitar-signal-check`.
- Muted native UI/server checks (boot a private server, open windows): `deck-view-check`, `spectrum-check`, `runtime-check`, `*-runtime-check`.

**Known baseline at commit 5024e31** (verified 2026-11-14; failures predate later work, so only a *new* failure or a changed message is a regression):

| Check | Baseline error |
| --- | --- |
| `check` | Tempo jumped during handover |
| `channels-check` | London Dubstep did not open with acid |
| `channels-runtime-check` | Duplicate/missing channel |
| `e-check` | A component comparison changed its foundation |
| `interaction-check` | EDM Classic groove changed |
| `rock-check` | Channel menu must have one EDM |
| `rock-expression-check` | Recipe lost the guitar tone version |
| `rock-physical-check` | This track was made with a different music source version |
| `rock-players-check` | Recipe lost player policy |
| `rock-solo-check` | Requested riff lost its call, answer, climb or arrival |
| `tension-runtime-check` | Tension runtime timeout |

All other checks pass: bass, deck-view, e-runtime, fixed-songs, manual-fx, modes, modes-runtime, pop, pop-runtime, rock-guitar-signal, rock-solo-runtime, rock-stutter, runtime, spectrum, stutter, tension, variety, variety-runtime. A full run takes about 9 minutes; the pure checks take seconds each. Runtime checks boot servers. A stray `sclang`/`scsynth` (`ps -ef | grep -E 'sclang|scsynth'`) can cause port errors, so kill leftovers from your own runs first. "Could not open UDP port 57120" alone is harmless noise.

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
- SynthDefs: append to `~djDefs` (`~djDefs=~djDefs++[...]`, see `pop-instruments.scd`), or `live.scd` won't send them and renders won't include them.

Approved fixed songs: specs (id, name, `channel`, style, bpm, ...) live in `infinite/experiments/dj/melodic-round/recipes.scd`; `fixed-songs.scd` turns them into live bars. `engine.scd` `chooseSong` makes half of a channel's slots fixed songs for that channel. Grammar/generator checks must construct engines with `(fixedSongs:false, ...)` so the rotation does not replace generated records; `fixed-songs-check` covers the rotation itself.

After changes: run the relevant checks, compare against the baseline above, then render a listening round if the sound changed.
