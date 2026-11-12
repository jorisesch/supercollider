# EDM compression listening test

Compare two EDM excerpts: **E Aeolian / Brass Circuit** and **G Ionian / Wired House**. These are new performances using the favorite palettes and tonalities, rather than exact replays of previously heard songs.

Each excerpt uses one rendered performance for all four versions. Open `audio/listening-round/edm-compression/listen.html` after rendering and packaging. Switch versions during playback to keep the same listening position, then copy your feedback into the chat.

| Version | Processing |
| --- | --- |
| A | No mix-bus compression |
| B | Previous EDM compressor: about 1.82:1, 6 ms attack, 120 ms release |
| C | Gentle stereo-linked compression: 2.5:1, 20 ms attack, 160 ms release |
| D | Stronger Pop setting: 4:1, 4 ms attack, 180 ms release |

At the time of this comparison, EDM used the light compressor in B. This comparison bypasses the master safety limiter and retains the deck's kick ducking in every version. B reproduces the previous compressor's independent channel detectors at the usual input drive, then removes that constant drive before level matching. C and D use the shared Pop compression function, with a stereo-linked detector high-passed at 110 Hz. Their thresholds are 0.035 and 0.027 respectively.

The package matches average levels and checks headroom, waveform preservation in bypass, and measured gain reduction. Diagnostic renders have a third channel containing the gain envelope. The report and listening files stay in the locally ignored listening folder. The listener selected **D · Stronger** for both excerpts on 2026-11-12. EDM now uses this strong setting too; Pop already used it. B remains a reference for the previous EDM processing.

From the repository root on macOS:

```sh
mkdir -p audio/listening-round/edm-compression
/Applications/SuperCollider.app/Contents/MacOS/sclang -D \
  infinite/experiments/dj/edm-compression/render.scd "$PWD/audio/listening-round/edm-compression"
python3 infinite/experiments/dj/pop-compression/package.py audio/listening-round/edm-compression
```

The Pop and EDM comparisons share the packaging script. An optional `comparison.json` selects the track IDs, title and feedback storage key; the original Pop comparison works without it.
