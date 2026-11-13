# Anthem lead register comparison

A new **Gb Ionian / Anthem** excerpt compares the original melody register with the same notes one octave lower. This is a fresh seeded performance, rather than a replay of the unidentified browser song.

Only `edmAnthemLead` notes change, by exactly **−12 semitones**. Timing, backing instruments, expression, effects and the approved strong master compression are identical. The render checks the note transformation before writing the scores. Both excerpts are sixteen bars at 134 BPM, with an ending tail.

From the repository root on macOS:

```sh
mkdir -p audio/listening-round/anthem-register
/Applications/SuperCollider.app/Contents/MacOS/sclang -D \
  infinite/experiments/dj/anthem-register/render.scd "$PWD/audio/listening-round/anthem-register"
python3 infinite/experiments/dj/anthem-register/package.py audio/listening-round/anthem-register
```

The package verifies the stereo WAV files and matches their average playback levels before writing M4A previews. The files and numerical report stay in the locally ignored listening folder.

The listener approved the lower octave on 2026-11-13: “one octave lower is much better for that track.” The production Anthem lead now uses this register in every key. The comparison reconstructs the previous high register for A; B is the current production register.
