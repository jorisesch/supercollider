# Neon Gravity — lead replacements

The listener loves Neon Gravity's backing but rejects the original brass melody sound: “wet fart meets nails screeching on a blackboard.” This is approval of the groove and a rejection of the lead tone, not an overall approval of the original mix.

These auditions retain the same E minor melody notes, phrase timing, bass, drums, chords, effects and strong master compression. Only the lead instrument and its gain change. There is no new melody or octave change.

| ID | Version |
| --- | --- |
| A | Rounded lead: a fundamental with a few quiet, exact harmonics |
| B | Soft keys: a gentle struck tone whose upper harmonics fade quickly |
| C | Clean pluck: a shorter, smooth pluck without a sharp click |
| D | No lead: drums, bass and chord bed as a reference |

The replacement voices use no distortion, sub-octave oscillator, detuned stack, resonant filter or filter sweep. The live playlist is unchanged. The renderer asserts identical backing events and identical melody notes/timings across all four versions; D omits the lead at score export without changing later event seeds. The shared compressor responds naturally to the different mix, so the final backing waveform can differ through gain reduction.

From the repository root on macOS:

```sh
mkdir -p audio/listening-round/04-neon
/Applications/SuperCollider.app/Contents/MacOS/sclang -D \
  infinite/experiments/dj/melodic-round/render.scd "$PWD/audio/listening-round/04-neon" neon
python3 infinite/experiments/dj/package-audition.py audio/listening-round/04-neon 04-neon
```

Open `audio/listening-round/04-neon/listen.html`. The main melody enters around 15 seconds. Audio checks and human listening preferences are recorded separately.
