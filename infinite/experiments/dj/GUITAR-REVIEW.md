# Guitar listening review

## Checkpoint — 2026-11-01

Initial listener feedback on the physical guitar study: **“Pretty decent!”** Keep this version as a reference for further listening. This is positive overall feedback, not a calibration against real instruments or individual pedals.

- [Isolated techniques and pedals](../../../audio/rock-guitar-study.m4a): bends at 0:04, finger vibrato at 0:12, fretted slide at 0:16, palm muting at 0:20, pedal phrases from 0:30.
- [Rock with the band](../../../audio/rock-channel.m4a): the first long solo starts around 0:57.
- [Three ensembles](../../../audio/rock-tones.m4a): Garage at 0:00, Jangle at 0:23, Fuzz room at 0:46.
- [Research, equations and approximation boundaries](GUITAR.md).

The reference uses string tension for bends/vibrato, fret positions for slides, a stiff-string modal model with pickup sensing, and a shared stereo guitar rig. Pedal stages use component-derived filters and diode transfer equations. The rig processes guitars before bass and drums join the mix. EDM and Pop retain their existing synthesis and score.

Checks passed for waveform pitch, settled endings, circuit equations, antialiasing, chord interaction, isolated bass/drum routing and the live Riff button. The current source/audio hashes and numerical results are in [the reproduction record](rock-physical-reproduction.json).

## Next listening questions

The current gestures are useful but their timing and intonation are too regular. Explore these as separate prototypes while preserving this reference:

- Vibrato can begin early, late, grow gradually, arrive in short bursts, slow down, accelerate, or be absent. Depth and rate can evolve together across a phrase.
- A bend can scoop partway, start already bent, hang slightly below its destination, overshoot and correct, or release before the note ends. Avoid making every picked note an upward bend.
- Small deviations should have a musical cause and a phrase-level pattern. Independent random pitch jitter is not a substitute for playing technique.
- Keep purposeful phrase-ending chord tones, while allowing passing notes and expressive bends less exact intonation. Preserve the rhythmic space around a solo.
- Compare the same phrase through a fixed guitar/rig so gesture changes can be judged without a tone or loudness change obscuring them.

Detailed listening review and prototype selection remain open. Do not promote a prototype into the default Rock channel merely because numerical checks pass.

## Phrasing prototypes — 2026-11-02

The accepted implementation and these notes were saved in local commit **`fa608b9`**. Nothing was pushed. Subsequent work is kept in the separate [guitar phrasing studies](guitar-prototypes/README.md).

The comparison plays the accepted reference, then **Restrained**, **Loose** and **Urgent** performances of the same phrase. The listening guide gives per-phrase timestamps. [Research notes](guitar-prototypes/RESEARCH.md) connect the sources to the design and distinguish measured behavior from assumptions. Review the chosen vibrato entrances, pre-bend releases, partial curls, held intonation errors, overshoots and final root settlement before selecting any gestures for the DJ.

The new prototypes have not received a listening decision and are not the default Rock sound.

## Picking-hand studies — 2026-11-02

The next request concerns double stops, string-by-string chord attacks, up/down strumming and contact with picks or fingers. The separate [picking-hand listening guide](guitar-contact/README.md) links three studies and a combined clip:

- Direction/timing: simultaneous control, full down/up sweeps, treble-only upstrokes, slower rakes and fast returns.
- Contact: stiff pick, angled edge, flexible pick, finger pad and nail, followed by a level-matched pass.
- Double stops: picked thirds, finger-pinched sixths, one-string bends against a held partner and short two-string chops.

[Research/model notes](guitar-contact/RESEARCH.md) explain the mechanical relationships, sources, illustrative parameters and remaining approximations. The studies keep direction, string coverage and material comparisons identifiable. Numerical checks and per-string event tables support later review. No picking-hand prototype has been selected for the DJ, and nothing has been pushed.

## Chord voicings and accompaniment — 2026-11-02

The [harmony listening guide](guitar-harmony/README.md) adds triad inversions, distinct Amaj7/A7/Am7 colors, Aadd9 versus A9, and slash chords with their specified bass sounding below the harmony. Four studies use the same clean picking-hand guitar:

- Major/minor triads and a root-position versus minimum-motion progression comparison.
- Sevenths and ninths with consistent strums and individually picked notes.
- A/C#, A/E, an E pedal, a descending bass line and a resolving riff.
- One accompaniment progression played as sustained strums, syncopated stabs, bass/treble answers and anticipated arpeggios.

[Research/design notes](guitar-harmony/RESEARCH.md) explain chord spelling, fret shapes, the movement objective, rhythm and diagnostic limits. Numerical checks cover the score, actual string pitches, bass register and audio output. Listening questions: are the colors clear, do the inversions connect, and which patterns should become part of Rock? No harmony experiment is promoted to the DJ. These studies remain uncommitted, and nothing has been pushed.

## Consistent players within songs — 2026-11-02

New direction: limit variation within a Rock song so each guitarist has a recognizable character. Current Rock records now assign **Rook**, **June** or **Flint** for the entire song, including its handover. Each keeps a narrow range of gestures, a fixed rig and a small vocabulary of repeated rhythms and lead ideas. Small phrase-ending answers, section dynamics and chord-aware endings remain available. Names are fictional and appear in the live window.

[Meet the players](PLAYERS.md) and compare the [new set](../../../audio/rock-player-set.m4a) with the [three-player tour](../../../audio/rock-player-comparison.m4a). Review whether repetition feels intentional, whether a player's verse and solo belong together, and whether the fixed fuzz character retains enough dynamics. Numerical checks are separate from this pending listening decision.

The earlier accepted previews and all standalone technique/harmony clips remain unchanged. Their reproduction records describe earlier source snapshots. New live Rock uses the player policy; older saved recipes keep the previous policy, and EDM/Pop retain their behavior. Nothing has been committed or pushed for this change.

## Pickup study — 2026-11-02

The [humbucker listening guide](guitar-pickups/README.md) compares a centered single coil, vintage series/parallel/split wiring and a hotter series model. The same picking phrase feeds all five. The clean pass matches listening levels; the drive pass keeps the natural level difference going into one pedal. [Model notes](guitar-pickups/RESEARCH.md) separate spatial sensing, electrical loading and hum cancellation, with measured checks and approximation limits.

Listen for harmonic color in the clean pass and changes in attack/compression in the drive pass. The pickup model is a standalone experiment; it is not assigned to the DJ's players. Human listening review is pending.
