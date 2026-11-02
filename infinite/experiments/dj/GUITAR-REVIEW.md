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
