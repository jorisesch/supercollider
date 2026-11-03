# Single-coil string decay

[Listen to the matched comparison](../../../../audio/rock-single-coil-decay.m4a). Each take starts with a clean E7 and held A4, followed by the same blues riff through June’s rig. The original decay curve starts at 0:00 and the new curve at 0:18. The driven sections start at 0:06 and 0:24. Both takes use the same pickup, note events, gain and 20 oscillators per string.

A real solid-body guitar’s partials can decay at very different rates. The string loses energy internally and to its surroundings. The neck and body also accept energy at particular frequencies, which can shorten a fretted note or selectively damp one of its partials. The pickup changes how much of each mode reaches the output, while the measured losses are mechanical. [Paté, Le Carrou and Fabre, 2014](https://pubmed.ncbi.nlm.nih.gov/24815284/)

The earlier model already gave each mode a different exponential rate through a mode-index-squared term and a palm-contact term. The new curve gives the string frequency and string gauge more influence. Air loss follows a square-root frequency approximation, the high-frequency bending term rises faster, and a broad neck resonance adds loss around 245 Hz on fretted notes. The coefficients and resonance are illustrative. They have yet to be calibrated against measurements from a specific guitar. [Howle and Trefethen, 2001](https://people.maths.ox.ac.uk/trefethen/publication/PDF/2001_93.pdf) · [Le Carrou et al., 2019](https://pubmed.ncbi.nlm.nih.gov/31795689/)

In the isolated fretted A3 probe, measured amplitude loss was approximately:

| Partial | Earlier curve | New curve |
| --- | ---: | ---: |
| 1 | 4.3 dB/s | 20.1 dB/s |
| 3 | 5.1 dB/s | 20.9 dB/s |
| 6 | 7.9 dB/s | 33.3 dB/s |
| 8 | 10.8 dB/s | 42.7 dB/s |

The fundamental and third happen to decay at similar rates in this example because the fundamental is near the modeled neck resonance. The model evaluates the loss at nominal note pitch so bends and vibrato do not reset the decay. The same voice can select either curve at note creation with `modalLoss`. Live Rock uses the revised decay with June’s single coil and with Rook’s and Flint’s humbuckers.

From the repository root, render with:

```sh
sclang -D infinite/experiments/dj/guitar-pickups/render-decay.scd
python3 scripts/verify_audio.py
```

The renderer writes `audio/rock-single-coil-decay.wav` and a separate `rock-single-coil-decay-probe.wav` under SuperCollider’s `Platform.defaultTempDir`. Pass the probe WAV to `python3 infinite/experiments/dj/guitar-pickups/verify-decay.py` to measure the four partials. On macOS, encode the listening copy with `afconvert -f m4af -d aac -b 192000 -q 127 audio/rock-single-coil-decay.wav audio/rock-single-coil-decay.m4a`.


## Power chords through overdrive

[Hear the revised single-coil with hard-picked power chords](../../../../audio/rock-single-coil-power-chords.m4a). Two takes share a Tube Screamer-style pedal and cabinet. The riff moves through E5, G5, A5 and B5 with palm-muted gaps, then leaves an E5 ringing. The guitar plays on its own.

[Hear the vintage series humbucker play the same riff](../../../../audio/rock-humbucker-power-chords.m4a). It uses the same 20-mode decay, performance and pedal settings with the humbucker’s two sensing coils and shared electrical load.

Run `sclang -D infinite/experiments/dj/guitar-pickups/render-power-chords.scd` from the repository root to render the single-coil WAV. Append `humbucker` to render the humbucker WAV.
