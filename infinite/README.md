# Infinite four-track music generator

Start the improved EDM engine from the SuperCollider repository directory (macOS, SuperCollider installed):

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/infinite-run.scd edm 0.25 0.55 0.30 0.20 128 2600
```

This plays live and opens a four-knob window. It does not record or export audio. Close the window to fade out over three seconds and exit; Ctrl+C in the terminal exits immediately. Arguments are `mode chaos density mutation tension bpm seed [nogui]`. The four macros use values from 0 to 1, not percentages. Omitted arguments use the defaults above. For the slower soundscape mode, use `sclang -D infinite/infinite-run.scd soundscape` (60 BPM by default). Add `nogui` after the seed to run without a control window; Ctrl+C stops that process.

| Control | Default | Musical effect |
| --- | --- | --- |
| Chaos | 25% | More adventurous weak-beat melody and rhythmic omissions; Tension still constrains pitch choices. |
| Density | 55% | Adds bass subdivisions, Euclidean arp hits, and drum ghost notes while retaining the core groove. |
| Mutation | 30% | Chance of changing one bass position and one lead position at each four-bar boundary; 0 preserves motif memory. |
| Tension | 20% | Allows diatonic passing motion, rising across four bars; chromatic notes require both high Tension (>70%) and high Chaos (>50%). |

EDM has **four logical lanes**: bass, lead, arpeggio, and drums. The drum lane contains kick, snare, and hats. The default harmony is C natural minor with Cm–Ab–Eb–Bb, two bars per chord. Short sixteenth-note articulations replace the previous slow note stream:

- **Bass:** a Markov chain strongly favors root and fifth, occasionally jumps an octave, and resolves approach notes. Its generated two-bar phrase is remembered and repeated, with roots anchored on strong beats.
- **Lead:** a two-bar call-and-response motif follows the chord tones, leaves space at the end of each four-bar phrase, and resolves to the chord root on every fourth-bar boundary. Small mutations preserve its identity.
- **Arpeggio:** a rotated 16-step Euclidean rhythm uses 3–14 pulses as Density rises, with chord-tone cycling and probabilistic omissions. To adjust its hit probability separately in the IDE, set `~infiniteEngine.controls.arpProbability=0.9`.
- **Drums:** stable four-on-the-floor, snare backbeats, accented offbeat hats, optional ghost notes, and short end-of-section fills. Deliberate kick omissions are restricted to the last beat of an eight-bar section.

All lanes share key, scale, progression, tempo, and tension. A dense bass reduces lead activity. Eight-bar groove, lift, space, and return sections create a 32-bar cycle; the lift adds bass subdivisions and an arp pulse, the space section thins lead and arp while keeping the rhythmic foundation, and the return rotates the arp rhythm. Seeded random decisions sit inside these musical constraints. **Fill next bar**, **Mutate**, **Hold motifs**, **Restart seed**, and **Stop** are available in the control window. Hold preserves bass/lead motif memory; drum variations and omissions continue. Explicit mutation takes effect next bar unless held; automatic mutation happens only at four-bar boundaries.

For IDE use, open `infinite/infinite-live.scd` and evaluate the whole file to define the controls, then evaluate these lines individually:

```supercollider
~startInfinite.value(\edm, 2600, 128);
~setInfinite.value(chaos:0.25, density:0.55, mutation:0.30, tension:0.20);
~setInfinite.value(density:0.8); // partial updates work; applied from the next bar
~fillInfinite.value;
~mutateInfinite.value;
~holdInfinite.value(true);      // false to resume motif changes
~stopInfinite.value;            // three-second fade; only this generator stops
```

To open the window from the IDE, evaluate the whole `infinite/infinite-controls.scd` file, then `~showInfiniteControls.value`. Loading definitions starts no playback. Repeated starts fade the old performance and cancel pending starts. The CLI launcher uses its own server on localhost port 57130; IDE playback uses `s` by default. Existing SuperCollider startup scripts still run when sclang starts.

`infinite-engine.scd` emits abstract events (`track`, `voice`, `beat`, `midinote`, `duration`, `amp`, `pan`); beat and duration are in musical beats. The audio adapter converts durations to seconds. Seed and settings reproduce the composition. `infinite-instruments.scd` contains SynthDefs only. `infinite-live.scd` owns the playback clock, group, and bus. Future MIDI/CV output can consume these events through a different adapter. The shared state is accessible as `~infiniteEngine.state`; for example, set `.key=38` for D minor at the next bar (MIDI key 36 is C).

Run the composition checks without playback or audio exports:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/infinite-check.scd
```

The checks cover seeded reproducibility across 128 bars, key membership, bass root/fifth bias, lead resolution, motif repetition, Euclidean pulse counts, density, fills, and macro bounds. Synthesis and GUI controls were also exercised with real-time output muted. This is structural/runtime validation, not a human listening review.

No WAV previews are included with this version. Any local `audio/infinite-*.wav` previews from the earlier engine do not demonstrate the current composition. `infinite-render.scd` remains an optional batch renderer for a future explicitly requested export; it renders the current sources at their factory tempos (120/60 BPM), writing to the repository’s `audio/` directory. This reorganization did not change synthesis or create new renders.
