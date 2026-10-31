# Infinite DJ listening notebook

Keep human listening judgments separate from structural, runtime and audio measurements. Preserve a playable source snapshot when changing the experiment's direction.

## Before this revision

The user said the DJ mechanism “kind of works” but the music was “really lame.” Five composed studies and lower, warmer lead revisions explored alternatives. A subsequent Dafunk Lounge-inspired disco study was described as “Not quite there.” Those studies, source snapshots and recordings remain available separately.

## 2026-10-31 — evolving grooves v2

User feedback: “The songs are too sterile.” Requested variation in length, patterns, intensity and chaos, taking inspiration from the original generator at these settings, described as “actually pretty decent”:

```sh
sclang -D infinite/infinite-run.scd edm 0.25 0.55 0.30 0.20 128 2600
```

Source diagnosis: the old DJ gave every record the same 80-bar form and 16-bar transition. Most drums and bass used fixed rhythm lists. Chaos affected few note decisions, so the four macro controls had little influence on the performed groove. This is an implementation-based explanation to test, not an additional listening judgment.

Changes to evaluate:

- Reuse the original composition engine directly for Markov bass, motif memory, Euclidean arp and probabilistic drums; retain its original files.
- Give records six song forms, different lengths, energy/density/chaos personalities, eight/sixteen-bar transitions and incoming intro cues matched to the mix length.
- Keep two-bar phrase identity; add recurring fourth-bar bass answers, small phrase-boundary mutations and melodic calls/responses with space at phrase endings.
- Let section intensity and four-bar motion vary effective macros around the user's settings. Display effective levels in each deck rather than implying the knobs are the entire state.
- Add ghost percussion, accents, small velocity/timing differences and deliberate omissions. Keep kick/bass anchors; retain quiet low-end pulses in some breakdowns.
- Use a warmer lead and saw-based arp, rhythmic chord comping, and fuller master gain with compression/limiting.

Preservation: the earlier DJ is frozen in [revisions/v1](revisions/v1/ABOUT.md), with hashes. Existing infinite baseline and A/B/ambient versions and all listening-study recordings are retained.

Candidate: [evolving DJ preview](../../../audio/dj-evolving-v2.m4a), default seed 2600 at 128 BPM, macros 0.25/0.55/0.30/0.20. [The timeline](preview-timeline.tsv) records scheduled bar starts and effective intensity/chaos/density. [The reproduction record](reproduction.json) retains source and audio hashes.

Human listening review of **this revision: pending**. Evaluate whether the groove feels more alive, whether repeated phrases stay recognizable, whether the energy range works, and whether key handovers leave too much empty space. Passing tests does not establish musical improvement.

Numerical/runtime results: 8,192 seeded bars and 2,048 macro-extreme bars passed; muted live handover, GUI controls, STOP/START and cleanup passed. The preview rendered successfully and `verify_audio.py` passed: 216.1227 seconds, stereo 48 kHz / 24-bit, peak -3.14 dBFS, active-music RMS -19.22 dBFS, quiet boundaries and activity in every bar. The final default re-render was PCM-identical across the whole excerpt. Previous DJ snapshot hashes and original-five recording preservation checks passed. These results are not a listening judgment.
