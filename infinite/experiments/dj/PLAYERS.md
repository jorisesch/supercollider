# Rock guitarist characters

Listen to the [three-player comparison](../../../audio/rock-player-comparison.m4a): **Rook 0:00, June 0:23, Flint 0:46**. The [longer set](../../../audio/rock-player-set.m4a) follows a player through sections and into a handover. Start the Rock channel using the [normal launcher](ROCK.md#start); the player's name appears below the track title.

## Design

The aim is a recognizable player throughout a song. GarageBand's Drummer is a useful product reference for virtual performers with their own styles and a small set of performance controls; [Apple describes its session-player approach here](https://www.apple.com/mac/garageband/). Our three fictional guitarists are original score policies, with no attempt to imitate a particular person or reproduce Apple's engine.

Each Rock record selects its player when the ensemble is chosen. Garage gets Rook, Jangle gets June, and Fuzz room gets Flint. The profile is copied into the record once; the verse, chorus, solo, Hold, knob movements and deck handover do not select a different player. Different songs can share a player while having different keys, progressions, forms and lead motifs. June uses a single coil. Rook and Flint use vintage series humbuckers. A song keeps the player’s pickup across both rhythm takes and the lead.

| Habit | Rook | June | Flint |
| --- | --- | --- | --- |
| Rhythm | Clipped eighth notes | More space between ringing chords | Short, heavy riffs with gaps |
| Lead | Compact repeating idea | Fewer, more separated notes | Spaced riffs and a related answer |
| Pick distance from bridge | 112 ± 2 mm | 140 ± 2.5 mm | 102 ± 2 mm |
| Vibrato rate | 5.00 ± 0.08 Hz | 5.80 ± 0.08 Hz | 4.60 ± 0.07 Hz |
| Preferred bend | Semitone | Occasional semitone | Whole tone |
| Rig | Feedback overdrive | Two-stage overdrive, compression and chorus | Diode distortion with a fixed fuzz blend |

These are authored musical choices, not measurements of real players. Vibrato remains conditional on a sufficiently long note, and chord-ending notes retain their settling rule. Connecting slides require a nearby note on the same playable string. Both pickups use the same 20-mode string decay model. [Pickup and decay study](guitar-pickups/DECAY.md)

## What varies within a song

The main accompaniment rhythm repeats. Mutation can introduce one related answer on the final bar of an eight-bar phrase; Hold suppresses that answer. Quiet sections keep the sparse backing treatment. Low Density uses fewer attacks. Chorus sections use a consistent, more open companion rhythm. A control change can alter the arrangement while keeping the same player's vocabulary.

Each player has a distinct call rhythm and contour. The lead answers the call in the second bar, climbs in the third and bends into a held chord tone in the fourth. Its pitches follow the current chord and selected scale. Final bars and handover cadences retain the existing chord-tone landing rules. The player does not cycle through the whole contour catalog on successive bars. Short replies outside a long solo retain the song's existing hook identity.

Pick placement and vibrato rate vary only inside the narrow ranges above. Each player has a distinct vibrato depth and favors different bends and slides in short replies. The four-bar solo reserves a semitone bend for the held target. Every song keeps its pedal topology, compressor, chorus amount and fuzz blend. Section dynamics, solos and Tension make small gain changes within a bounded range; Tension no longer drives a player through a wide range of rigs. Manual DJ effects remain available on top.

Bass and drum events are preserved exactly, including timing, velocities and seeds. Guitar rhythm replacement happens after the original backing score is built, using its own deterministic variation stream. This avoids consuming random choices that belong to the rhythm section.

## Scope and listening

The current model is one guitarist double-tracking rhythm and overdubbing lead through a shared rig. It does not assign two independent personalities to the stereo sides. The experimental picking-hand, variable-gesture and extended-harmony studies remain separate; their complete technique catalogs have not been added to every song. The player’s pickup and pedal are applied on that song’s deck.

The recorded comparison predates the new solo phrasing. It plays eight bars per player at the same tempo and key, with a requested four-bar solo followed by backing. It demonstrates both rig and score differences and is not a level-matched tone comparison. Human listening review is pending: check that repetition establishes identity without becoming static, that the phrase-ending answers feel related, and that Flint's quieter passages retain useful dynamics.

## Source and checks

Profiles and bounded rhythm replacement are in [rock-players.scd](rock-players.scd). [rock-style.scd](rock-style.scd) applies the lead vocabulary; [rock-physical-style.scd](rock-physical-style.scd) applies personal gestures and rig settings. `engine.scd` assigns a profile once per record. The live status, tooltip and track announcement identify the player.

Current sessions save recipe schema 8 with `rockPlayerVersion`. Physical Rock defaults to policy 1. Earlier recipes need the generator version that created them. EDM and Pop receive no player profile. Historical reproduction records for the earlier studies describe their source at the time they were rendered; the new policy does not rewrite those snapshots or their audio.

From the repository folder:

```sh
sclang -D infinite/experiments/dj/rock-players-check.scd
sclang -D infinite/experiments/dj/guitar-players/render.scd
python3 infinite/experiments/dj/guitar-players/package.py
python3 scripts/verify_audio.py
```

Use your installed `sclang` path where needed. Rendering exits automatically. The [render folder](guitar-players/README.md) explains preview encoding, timelines and the reproduction record. The score checks cover stable profiles across sections/handovers, repeated rhythm vocabulary, bounded gestures/rigs, chord endings, identical bass/drum events and old/new recall. The native channel runtime check verifies visible names/tooltips, live audio with hardware output muted, channel switches, Riff, effects and cleanup.
