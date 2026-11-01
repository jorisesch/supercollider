# EDM C: infinite DJ

A separate eight-track prototype: two four-track decks generate their own records and hand over automatically. The original generator, EDM A, EDM B, and warm ambient remain available.

Run from the SuperCollider repository directory:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/c-edm.scd
```

Default seed: 2600. Starting tempo: 128 BPM. Optional arguments are `seed initial-bpm [nogui]`; initial BPM is clamped to 118–140. Subsequent record tempos move within 122–136 BPM.

No recording or WAV export takes place. Close the window for a three-second fade and exit. Ctrl+C exits immediately.

## Hear a set unfold

At the default tempo, expect the first full hook around 30 seconds, a breakdown around 45 seconds, a buildup around 60 seconds, and a drop around 75 seconds. The first automatic handover starts around 90 seconds and finishes around two minutes. Later timings vary with tempo.

Use **Hook** to bring the current motif forward for four bars. **NEXT record** queues a handover at the next eight-bar boundary, so you can audition another record sooner. The button is disabled during an active handover. A handover lasts 16 bars.

C's bass has a fixed oscillator pitch, a softer attack, a sustained body, and gentle low-pass movement. It avoids B's sharp resonant filter sweep. The four timbre families cover rounded saw, hollow pulse, FM, and saw/triangle basses, paired with different hook sounds.

## Eight tracks, two decks

| Deck | Tracks | Musical roles |
| --- | --- | --- |
| A | 1–4 | Bass, hook melody, arpeggio/chords, drums |
| B | 5–8 | Bass, hook melody, arpeggio/chords, drums |

Each deck has a key, a major or minor scale, a progression, a chord-duration pattern, a hook, and a variation profile. Bass phrases repeat; hook motifs return in the hook and drop sections. One motif position can mutate at a phrase boundary. Chord pads and arpeggios share a lane, and kick, snare, hats, and buildup gestures share the drum lane.

The window shows each deck's record name, key, section, progression degrees, and chord lengths. Its three meters show **mix gains** for music, bass, and drums, rather than measured audio levels.

## Handover without a key clash

Both decks run on one beat clock. Over a handover, the clock moves gradually toward the incoming record's target tempo, at most four BPM away. The scheduler updates tempo every sixteenth note. Notes keep their pitch as tempo changes.

Drums crossfade across the full 16 bars. Outgoing melody and bass fade away around the midpoint; incoming pitched parts enter afterward. This leaves a short drum bridge for changing keys. Deck gains sit after delay and reverb, so the outgoing key's effect tails fade with its music.

Bass has a separate dry path and ducks under its own deck's kick. The final stereo mix is limited. Records alternate deck slots; this is a continuous generated set with no audio files to load.

## A larger musical library

The editable [library](library.scd) contains:

- **32 named variation profiles:** eight rhythm families crossed with four timbre families, including different arp directions and swing amounts.
- **32 chord progressions:** sixteen in natural minor and sixteen in major.
- **20 chord-duration patterns:** holds from one to eight bars, with uneven and mixed-length patterns as well as regular loops.
- **16 hook templates**, combined with eight melodic rhythms.
- **12 key centres**, with major and minor records alternating.

Shuffle bags visit every variation, duration pattern, hook template, and key centre before refilling. Progressions use a separate bag for each mode. Consecutive records change key centre. The same seed and control actions reproduce the same choices.

Each record follows an 80-bar structure: 16 intro, 16 groove, 8 hook, 8 breakdown, 8 buildup, 16 drop, and 8 outro. Records overlap by 16 bars, giving a new handover every 64 bars. The first record begins at its groove, so the set starts with music rather than a long intro. Chord lengths vary inside that structure; the arrangement spine is currently shared by all profiles.

## Controls

**Chaos** adds sparse diatonic passing notes and omissions. **Density** changes bass subdivisions, arp pulses, and pad activity. **Mutation** controls small changes to the remembered hook. **Tension** controls brightness and the chance of passing movement; notes remain in their deck's scale.

**Hold record** keeps the current record's identity and holds motif mutations while its harmony and arrangement continue. **NEXT record** overrides Hold for one handover. **Mutate motif** requests a small change unless held.

**STOP / START** fades out and continues the same set at its next bar, retaining both deck plans and control settings. **Restart seed** resets the set and clears Hold. Closing the window ends CLI playback.

For IDE use, load all of `live.scd`, then evaluate individual commands:

```supercollider
~djStart.value(2600, 128);
~djHook.value;
~djNext.value;
~djSet.value(density:0.7, tension:0.25);
~djHold.value(true); // false to allow automatic record changes again
~djStop.value;
~djResume.value;
```

Load `controls.scd`, then evaluate `~djShow.value` to open the window. The CLI uses its own server on localhost port 57134; IDE playback uses `s` unless a server is supplied. Existing sclang startup scripts and global server hooks still run. All synthesis uses stock UGens, with no sample or extension dependencies.

## Code and verification

[library.scd](library.scd) holds the musical catalog. [engine.scd](engine.scd) plans records, note events, and handovers. [instruments.scd](instruments.scd) only defines voices and mix processing. [live.scd](live.scd) owns playback and cleanup. [controls.scd](controls.scd) supplies the window; [launch.scd](launch.scd) supplies CLI setup.

```sh
# Pure composition checks; no playback.
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/dj/check.scd

# Real-time GUI/transport/handover check on a muted server; approximately 45 seconds.
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/dj/runtime-check.scd
```

The pure check covers 2,112 seeded bars and visits the full catalog, checking timing, eight-track routing, key membership, gradual tempo changes, planned isolation of different-key pitched parts, hooks, buildups, Hold/NEXT behavior, and bounded voice lifetimes. The real-time check exercises a complete key/tempo handover, the window, all four knobs, Hook/Hold, STOP/START continuation, internal signal levels, and node/bus cleanup.

These are numerical and runtime checks. C still needs human listening review. No new WAVs or entries in `audio/verification.json` were generated.
