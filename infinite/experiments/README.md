# Infinite music experiments

Five EDM variants and a warm ambient prototype to compare with the existing generator. The original composition and instrument sources are preserved; the common launcher routes standard EDM to the DJ. These experiments use their own instruments, playback state, and control window. Live launchers start no recording; the DJ and EDM D/E also have explicit offline preview renderers.

Run the commands below from the SuperCollider repository directory. Close one performance before starting the next so you hear each on its own.

## A: melodic / progressive EDM

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/a-edm.scd
```

Default: 126 BPM, seed 2600. This builds on the original Markov bass, melodic motifs, Euclidean arp, and drums, with:

- A rounded bass, softer pluck lead, and a cleaner FM arpeggio.
- Voice-led chord pads that retain common tones and move nearby voices by small intervals.
- Subtle late offbeats on arp and hats; kick and bass remain on the grid.
- Filtered stereo delays and reverb on musical lanes, with dry drums and gentle kick-driven ducking.
- A 64-bar arc: introduce (8), theme (16), lift (8), breakdown (8), rebuild (8), release (16). The breakdown removes bass and drums; the rebuild brings the kick back gradually.

The original two-bar motifs and minor-key progression remain the musical foundation. Initial macros: Chaos 20%, Density 60%, Mutation 20%, Tension 15%.

## EDM B: more bite

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/b-edm.scd
```

Default: 126 BPM, seed 2600, and the same macro defaults as A. This keeps **four tracks** and retains A's bass pitches, harmony, and 64-bar arrangement. It explores a harder sound before adding more instruments:

- A resonant saw/pulse midrange is saturated while a clean sine anchors the bass fundamental. Accented notes open the filter further.
- Bass articulation alternates between short notes and longer accents. A quiet root pickup answers the end of alternate bars when Density is at least 40%; occupied steps are retained.
- The kick has a faster pitch drop and a short click. The snare has a sharper attack and more body. Hats and the melodic voices remain available from A.
- Bass uses a separate dry bus, ducking under the kick. Pads are quieter and shorter; less reverb and delay leave the bass and drums exposed.

To compare, close A and start B with the same seed and tempo. Both default to 126 BPM, seed 2600, Chaos 20%, Density 60%, Mutation 20%, and Tension 15%. Listen first for the bass attack, its midrange character, and how clearly it separates from the kick. This is not a loudness-matched comparison; adjust your playback volume if needed. B has the same four knobs, fill/mutate/hold controls, and five-second fade.

The original `b-soundscape.scd` filename still launches warm ambient. `b-edm.scd` is the second EDM variant; neither replaces the other.

## EDM D: syncopated detail

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/d-edm.scd
```

Default: 126 BPM, seed 2600, with the same macro defaults as A and B. D keeps A's seeded harmony and phrase memory, then adds detail around it:

- A paired-saw bass with accent-dependent filter opening and occasional offbeat root/fifth pickups.
- A lead with vibrato that fades in after the note attack, plus a short end-of-phrase turnaround.
- A brighter arp with accent-controlled filter motion and a quiet pad tone every four bars.
- Ghost snares, restrained clap layers, and occasional open hats around the existing kick/snare/hat grid.

D still uses four timing lanes (bass, musical voices, arp, drums); the added pad shares the music bus rather than making the control window or mixer more complicated. The standalone preview can be rendered with:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/d-render.scd
```

## Standard EDM: promoted from E

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/e-edm.scd
```

E builds on the current bass-led Infinite DJ. Default: **128 BPM, seed 2600**, Chaos 25%, Density 55%, Mutation 30%, Tension 20%. It is now the default **EDM** in the DJ menu and behind `c-edm.scd`. The previous version is **EDM Classic**. The `e-edm.scd` launcher remains an alias.

- Muted, held and short bass articulations, with occasional brief slides. The clean low fundamental stays present.
- Warm three-note chord stabs on selected offbeats, leaving room for the bass.
- Two-bar shaker phrases and tuned tom answers that enter and leave.
- A small recurring synthesized vowel-like percussion signature.
- An alternate B bass groove in the first half of the drop, then A's return. **Bass hook** requests the B phrase for four bars.
- A brief reverse breath before the drop. Existing quarter-bar pullbacks and occasional half-bar sixteenth stutters remain sparse.

[Listen to the 94-second track edit](../../audio/edm-e-groove.m4a), or [compare individual building blocks](../../audio/edm-e-building-blocks.m4a). The comparison repeats the same eight-bar foundation: baseline at 0.1 seconds, percussion at 15.1, chord stabs at 30.1, bass articulation at 45.1. The [DJ guide](dj/README.md#standard-edm) describes the source, controls and checks.

Render the track, comparison or a longer set excerpt:

```sh
sclang -D infinite/experiments/e-render.scd
sclang -D infinite/experiments/e-render.scd compare
sclang -D infinite/experiments/e-render.scd set
```

The original melodic D remains [d-edm.scd](d-edm.scd), with its preview renderer [d-render.scd](d-render.scd). E uses the DJ engine and compact window.

## EDM C: infinite DJ

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/c-edm.scd
```

Two four-track decks automatically hand over between records. The v6.3 style puts bass and drums first: recognizable bass cells with small answers, evolving filter/drive, subtle shared swing and quiet ghost hits. Percussion enters and leaves; occasional quarter-bar pullbacks and shorter drum spotlights leave longer stretches of groove. Half-bar sixteenth-note stutters occasionally punctuate a phrase. Melodic phrases remain sparse. Four instrument ensembles rotate bass synths, complete drum kits and accent voices; Digital Drive now has a rounder FM lead. Six forms (56–96 bars), changing keys, tempo matching and deck effects shape the set. The compact window shows generated track names with details on hover, a single effect selector with Start/Stop, stereo spectrum displays and track-name recall from a local recipe library. Transport continuation and playable earlier snapshots remain available.

With default seed 2600, the first handover starts around 75 seconds; **Next** queues one at the next four-bar boundary. Optional C arguments are `seed bpm chaos density mutation tension [nogui]`. See the [infinite DJ guide](dj/README.md) for commands, the rendered preview, previous-version playback and verification. A and B remain available unchanged.

## Warm ambient

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/b-soundscape.scd
```

Default: 48 BPM, seed 2600. The four lanes are low foundation, chord clouds, sparse bells, and filtered air. The major-key harmony moves through C, Am, F, and G with voice leading. Harmony changes every eight bars, approximately 40 seconds at the default tempo. Slow envelopes overlap; low-level stereo movement and filtered reflections provide motion without a drum grid.

Give this one at least a minute. The pads take several seconds to open, and the first harmonic change happens around 40 seconds. Initial macros: Chaos 20%, Density 45%, Mutation 15%, Tension 10%.

## Controls and comparison

The A/B/D/ambient panel and the C/E DJ window have Chaos, Density, Mutation, and Tension knobs. This section describes A/B/D/ambient; C and E use the [DJ controls](dj/README.md#controls). In ambient mode, Density adds cloud voices and bell opportunities, Tension adds brightness and optional diatonic extensions, Chaos widens bell placement, and Mutation changes pad placement at harmonic boundaries. Ambient **Hold** keeps the current harmony; EDM **Hold** preserves motif memory while the arrangement continues.

**Fill next bar** adds an EDM drum fill; the ambient **Bloom** button adds three soft bell notes. **Mutate** requests a small change next bar unless held. **Restart seed** restarts the same composition with the current macro values. **STOP** fades the current session and becomes **START**. **START** continues at the next bar with the same composition, knob settings, Hold state, tempo, and experiment variant. **Restart seed** resets the composition instead. The toggle follows starts and stops issued from the IDE as well. Closing a CLI window fades out and exits: five seconds for EDM, eight for ambient. Ctrl+C exits immediately.

The panel uses knobs and buttons rather than radio buttons. Every control callback has a language-post confirmation: knob changes print the four effective macro values; Fill, Mutate, Hold, Restart, STOP, and START print their requested action. These messages appear in the SuperCollider language post window, not in the audio server meter. If the window changes visually but no message appears, confirm that `experiments/controls.scd` is loaded and that the button is the experiment panel, not the baseline `infinite-controls.scd` panel. A message confirms that the callback ran; musical changes still enter on the next bar where noted.

A/B/D/ambient arguments are `seed bpm [nogui]`. C and E accept `seed bpm chaos density mutation tension [nogui]`:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/a-edm.scd 2600 128
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/b-soundscape.scd 2600 48 nogui
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/e-edm.scd 2600 128 0.25 0.55 0.30 0.20 nogui
```

The original is still available with the same command:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/infinite-run.scd edm 0.25 0.55 0.30 0.20 128 2600
```

For an EDM comparison, use 128 BPM and identical knob values in both versions. Listen for groove and phrase identity first, then note where the sound or arrangement improves or gets in the way. For ambient, listen for smooth chord transitions, enough movement, and whether the bells or low end become distracting. These prototypes have not yet received human listening review.

## Editable code and checks

- [bite-engine.scd](bite-engine.scd) and [bite-instruments.scd](bite-instruments.scd): the harder EDM B adapter, instruments, and dry-bass mix.
- [engine.scd](engine.scd): composition adapters, arrangement, and ambient harmony.
- [instruments.scd](instruments.scd): instrument definitions and separate music/drum mix processing; no playback.
- [dj/e-style.scd](dj/e-style.scd), [dj/e-instruments.scd](dj/e-instruments.scd): E's articulated bass, chord voicings, percussion phrases and signature. [d-engine.scd](d-engine.scd) and [d-instruments.scd](d-instruments.scd) retain D.
- [live.scd](live.scd): starts, updates, and gracefully stops experimental sessions.
- [controls.scd](controls.scd): the four-knob window.
- [launch.scd](launch.scd): shared CLI setup. Entry points are [a-edm.scd](a-edm.scd), [b-edm.scd](b-edm.scd), [c-edm.scd](c-edm.scd), [d-edm.scd](d-edm.scd), [e-edm.scd](e-edm.scd), and [b-soundscape.scd](b-soundscape.scd). C and E use their shared [DJ runtime and controls](dj/README.md).

For IDE use, load `live.scd`, then evaluate individual commands:

```supercollider
~startExperiment.value(\edm, 2600, 126);
// Stop the first performance before switching:
~stopExperiment.value;
~startExperiment.value(\soundscape, 2600, 48);
~setExperiment.value(density:0.6, tension:0.15);
~fillExperiment.value; // ambient bloom / EDM fill
~stopExperiment.value;
~resumeExperiment.value; // continue at the next bar without resetting
```

Load `controls.scd` and evaluate `~showExperimentControls.value` for the window. Baseline controls use `~startInfinite`, `~setInfinite`, and `~stopInfinite`; the experiments use their own names. CLI experiments use dedicated local server ports: 57131 for EDM A and D, 57133 for EDM B, 57132 for ambient, and 57134 for the C/E/Pop DJ. Existing sclang startup scripts and global server boot hooks still execute normally. All sound uses stock UGens.

Run A/B/D/ambient composition checks without playback or audio files:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/check.scd
```

Checks cover 128 seeded bars per mode and EDM variant, preservation of A’s bass pitches in B, D's seeded detail and control bounds, six-bus routing and extreme knob settings for B, key membership, event timing, the EDM breakdown, slow ambient harmony, bounded ambient voice lifetimes, and the experiment knob/Fill/Mutate/Hold callbacks. All SynthDefs, the window, macro updates, mode changes, and fade/stop cleanup were also exercised with real-time output muted. This validates code execution, not subjective sound quality. E has its own `dj/e-check.scd` and muted `dj/e-runtime-check.scd`; see the [DJ guide](dj/README.md#standard-edm).


The shared [transport regression check](../transport-check.scd) exercises STOP → START → STOP, retained phrase state, rapid clicks, Restart seed, and window closure in every version. Run it from the repository directory with `sclang -D infinite/transport-check.scd`; it uses a muted server and exports no audio.
