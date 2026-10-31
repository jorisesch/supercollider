# Infinite DJ — evolving grooves

Two four-track decks play an ongoing set with changing keys, recurring hooks, fills and tempo-matched handovers. This revision takes its compositional foundation directly from the original generator: its Markov bass, remembered lead motifs, Euclidean arpeggio and probabilistic drums. It adds different song forms and a changing performance around those phrases.

From the repository directory:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/c-edm.scd 2600 128 0.25 0.55 0.30 0.20
```

Arguments are `seed bpm chaos density mutation tension [nogui]`. With no arguments, the command uses the values above. The older `seed bpm [nogui]` form still works. The window opens automatically; close it to fade out and exit. Ctrl+C exits immediately. Live playback records no audio.

## What changes as it plays

- **Song length and form:** six arrangements, 56–96 bars long, with different amounts and ordering of groove, hook, space, breakdown, buildup, drop and outro. The first record skips its intro. Incoming records are cued so a short handover does not leave a long intro afterward.
- **Pattern memory:** the original two-bar Markov bass and melodic memory continue underneath the arrangement. A repeated bass answer changes the fourth bar; new rhythm choices and motif mutations happen at phrase boundaries. Hooks return in stronger sections, with a lower-volume call and response in the groove.
- **Intensity and macros:** each record has its own energy, density and adventurousness. Section envelopes and small four-bar changes move effective Density, Chaos, Mutation and Tension around the knob settings. Drops become busier; space sections thin out. Some breakdowns keep a quiet low-end pulse. The window shows current intensity, effective Chaos and effective Density for each deck.
- **Groove and articulation:** accented hats, probabilistic sixteenths, short percussion ghosts, fills and occasional deliberate kick omissions. Small velocity and timing variations affect supporting parts; bass and kick retain their grid anchors. Swung profiles and repeated answer rhythms create character without reselecting every note.
- **Sound:** warmer pulse/triangle lead and filtered saw arpeggio replace the brighter FM-like voices. Bass keeps a steady oscillator pitch. Rhythmic chord stabs complement pads used in spacious sections. The master has more gain, gentle compression and a limiter; this is gain staging, not perceptual loudness normalization.

The opening record deliberately uses C minor, the original `[0,5,2,6]` progression, two bars per chord, and the baseline groove profile. Subsequent records rotate 32 profiles, 32 progressions, 20 chord-duration patterns, 16 hook templates and 12 key centres, using shuffle bags. Consecutive records change key centre. Note choices remain inside the current deck's scale even when Chaos rises.

Handovers last eight or sixteen bars. Both decks follow one beat grid while tempo gradually moves to the new record's target. Outgoing music and bass clear before the incoming key arrives, with percussion bridging the gap. Post-effect gains also clear the old reverb. Logical tracks 1–4 belong to deck A, tracks 5–8 to deck B; drums contain multiple subvoices within their lane.

## Controls

The four knobs set the centre of the evolving performance. **Chaos** affects omissions, fills and passing movement; **Density** controls subdivisions and arp/chord activity; **Mutation** controls phrase changes; **Tension** controls brightness and melodic adventure. Zero still gives zero for that effective macro; the engine does not silently add chaos to a zero setting.

**Hook** calls up four bars of the motif. **Fill** requests a drum fill for the next generated bar. **Mutate motif** requests a phrase/rhythm change unless held. **Hold record** retains the current record and freezes motif/rhythm mutations while harmony, sections and percussion continue. **NEXT record** overrides Hold and queues a handover on the next four-bar boundary.

**STOP / START** fades and continues the same set at its next bar, retaining deck plans, phrases and settings. **Restart seed** resets the set with the current macro settings and clears Hold.

For IDE playback, load [live.scd](live.scd), then evaluate individual lines:

```supercollider
~djStart.value(2600, 128);
~djSet.value(chaos:0.25, density:0.55, mutation:0.30, tension:0.20);
~djFill.value;
~djHook.value;
~djNext.value;
~djHold.value(true); // false to allow automatic record changes
~djStop.value;
~djResume.value;
```

Load [controls.scd](controls.scd) and evaluate `~djShow.value` to open the window. CLI playback uses its own server on port 57134; IDE playback uses `s` unless supplied a server. Existing local SuperCollider startup hooks still execute. All synthesis uses stock UGens and no samples.

## Listen and compare

[112-bar AAC preview](../../../audio/dj-evolving-v2.m4a) · [listening notes](NOTES.md)

The preview uses the default seed and settings, follows the live tempo automation, includes an automatic handover and reaches the second record's drop. It is an excerpt of the ongoing set with an ending fade. [preview-timeline.tsv](preview-timeline.tsv) records each bar's scheduled start, tempo, section and effective macros for both decks.

The previous DJ is preserved as a playable [v1 snapshot](revisions/v1/ABOUT.md):

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/dj/revisions/v1/run.scd 2600 128
```

The original generator is also still available with the user's reference settings:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/infinite-run.scd edm 0.25 0.55 0.30 0.20 128 2600
```

Close one performance before starting another. Compare phrase identity, groove, energy changes, hook returns and whether transitions feel too empty. Human judgments and implementation hypotheses are kept in [NOTES.md](NOTES.md).

## Rendering and checks

[library.scd](library.scd) holds the catalog and song forms. [engine.scd](engine.scd) wraps the baseline composition engine, plans records and handovers, and supplies adapters shared by live playback and rendering. [instruments.scd](instruments.scd) defines sounds without playback. [live.scd](live.scd) owns transport/resources; [controls.scd](controls.scd) owns the window; [launch.scd](launch.scd) handles CLI setup.

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/dj/check.scd
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/dj/runtime-check.scd
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/dj/render.scd
python3 verify_audio.py

# Optional compact listening copy on macOS:
afconvert -f m4af -d 'aac ' -b 192000 -q 127 audio/dj-evolving-v2.wav audio/dj-evolving-v2.m4a
```

The pure check covers 8,192 seeded bars, the full catalog, six forms, varying length/intensity/macros, root/fifth bass bias, density response, valid timing and eight-track routing, key membership, continuous tempo, pitched-key isolation, Hold/NEXT/hooks and bounded voice lifetimes. Another 2,048 bars check macro extremes, including high Chaos/Tension; explicit Fill/Mutation requests and incoming intro cues are also checked. The muted runtime check covers the handover, window, all knobs, Hook/Fill/Hold, STOP/START continuation, internal signal and node/bus cleanup. It takes about 30 seconds.

The standalone renderer exits after writing a local WAV and timeline. WAV output is ignored by Git; the AAC preview is the committed listening artifact. `verify_audio.py` checks committed Quindar previews; local DJ WAVs can be inspected separately. [preview.json](preview.json) and [reproduction.json](reproduction.json) retain settings and source/audio checksums. These numerical and runtime checks are separate from human listening review of this revision, which is pending.
