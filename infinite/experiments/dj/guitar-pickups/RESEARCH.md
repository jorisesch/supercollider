# Humbucker model notes — 2026-11-02

The prototype separates the string, the magnetic sensing positions, the loaded electrical response and the pedal. The existing picking-hand model supplies the same released string displacement, damping and phase in every pass. The pickup model changes how that motion becomes voltage.

## Two coils sense one string

Magnetic induction converts changes in flux into voltage. In a small-signal pickup model with a local flux gradient, the result follows string velocity. [Daniel Russell's pickup research](https://www.acs.psu.edu/drussell/guitars/pickups.html) explains the velocity distinction. Pickup position and sensing width are separate parts of the model, as discussed in [Paiva, Pakarinen and Välimäki's pickup modeling paper](https://aes.org/publications/journal-online/?num=10&vol=60).

For mode `n` on a speaking length `L`, the mode shape is `sin(kx)` where `k = nπ/L` and `x` is measured from the bridge. A coil averages that shape across its effective sensing width. For a coil wholly under the speaking string, its contribution is `g sin(kx) sinc(kw/2)`, where `g` is sensitivity, `w` is aperture width, and `sinc(z) = sin(z)/z`. The implementation integrates over the actual overlap with the string. A pickup extending beyond the fret therefore loses that part of its aperture rather than sensing an imaginary vibrating segment.

The bridge pickup is centered 45 mm from the bridge, with illustrative 18 mm coil spacing and 6 mm effective apertures. Both coils sample the same oscillators. Their weights can add, reduce or flip the sign of a partial. In the G4 diagnostic, the 23rd mode is around 9.25 kHz and the vintage series pickup reduces it by about 29.9 dB relative to the centered single coil. That high mode is a useful geometry test; the overdrive pass also rolls off high frequencies, and the position of a spatial dip depends on the string and fret.

Sensing weights are computed when the note is built. The rendered voice has **52 audio-rate modal oscillators**, the same count as the picking-hand prototype. It adds a shared electrical filter per guitar, without creating a second string voice for the second coil. Real-time CPU cost has not been benchmarked for this prototype.

## Wiring and hum

The second coil has both an opposite magnetic polarity and an opposite electrical sign. The two signs multiply for string motion, so the two local string voltages sum in series. A shared interfering magnetic field has no pickup-magnet sign and is subtracted. [Seymour Duncan's wiring explanation](https://www.seymourduncan.com/blog/latest-updates/guitar-wiring-explored-humbucker-internals) illustrates this distinction.

Matched parallel wiring averages the two source voltages and keeps the cancellation. Splitting keeps only the bridge-side coil, including its location, its own electrical load and its share of hum. It is a distinct comparison from the single coil centered between the two humbucker positions. In the diagnostic, the same 50 or 60 Hz field with two harmonics feeds both coils. Matched series and parallel outputs cancel below the PCM floor. A 3% second-coil sensitivity mismatch leaves a residual **30.46 dB below the split coil** in this pre-load test. The musical previews omit injected mains noise.

## Loaded circuit

The pickup is a source behind winding resistance `R` and effective inductance `L`. It drives a parallel load consisting of winding/cable capacitance, volume and amplifier resistance, a lumped loss resistance and a tone pot in series with a tone capacitor. This follows the loaded-source approach in [Helmuth Lemme's pickup measurements and circuit notes](https://buildyourguitar.com/resources/lemme/).

```text
C = winding capacitance + cable capacitance
G = 1/R_volume + 1/R_amp + 1/R_loss
Y_load(s) = G + s C + s C_tone / (1 + s R_tone C_tone)
H(s) = 1 / (1 + (R + s L) Y_load(s))
```

The matched series case uses twice the coil resistance and inductance when coupling is zero. Matched parallel uses half. The source model accepts a signed mutual coupling parameter, referenced to the connected coil terminals, but the published presets use zero. The winding capacitance is a lumped approximation: two equal coil capacitances combine in series or parallel. The load is 470 pF cable, 500 kΩ volume, 1 MΩ amplifier input, and a 500 kΩ tone setting with 22 nF tone capacitance. These are shared across the comparison. Effective loss resistance differs by pickup profile.

The circuit's third-order denominator factors into a real pole and a quadratic. The code applies the bilinear transform and realizes it with one `FOS` and one `SOS` per channel. The coefficients adapt to the actual synthesis sample rate. All strings sum before this filter and before the pedal. For listening, a narrow stereo spread uses the same circuit on both channels; the single-chord live audition centers all the strings.

## Comparison and checks

The clean pass matches whole-phrase RMS to −24 dBFS per pickup. The drive pass uses the same Tube Screamer model, cabinet approximation and common gain throughout. Relative to the single coil, the vintage series and hot series deliver **+2.83 dB** and **+5.37 dB** respectively in the unmatched clean path. After the same pedal, the differences are **+1.08 dB** and **+2.20 dB**. This measures the simulated phrase and settings; it is not a general pickup output specification.

The independent verifier compares 50 measured circuit responses against direct complex impedance calculations, including phase. It compares 28 measured harmonic ratios/signs against finite-aperture predictions, checks the G4 fundamental and hum cancellation, and verifies levels, format, headroom and quiet tails. The clean RMS spread is below 0.05 dB. A separate muted live audition checks that each string starts and that stop/natural release free the audition's nodes.

The five presets are illustrative, not fits to measured pickups. The model omits nonlinear flux versus string distance, distributed winding resonances, magnetic pull, coil microphonics and nonuniform interference. The spatial weights assume a fixed fret during each note; vibrato changes tension, while a full fretted slide would need updated sensing weights. Parallel wiring currently requires matched coils. The studio comparison received a positive listening review. A hardware-matched comparison remains open.


## Live Rock implementation

Rock uses 20 audio-rate string modes per note. Both coils read the same mode bank, with 18 mm between their centers and a 6 mm aperture. Their positions are evaluated against the current speaking length, so the pickup response moves during fretted slides. The vintage series load is shared by the guitar voices on each deck and runs before its pedal rig. The 52-oscillator studio model remains the reference for the clean, drive, wiring and hum comparisons. In a muted 48 kHz, 64-sample-block test with 24 sustained strings across two decks, the server reported 33,620 UGens for the humbucker and 39,770 for the earlier 28-mode voice. The median reported average CPU was 37.4% and 35.8%, respectively, across two passes per voice. The smaller graph did not show a CPU saving in this test. The audible effect of the mode reduction has yet to be isolated.

Blues records voice the major third, fifth and flat seventh on guitar, with the bass supplying the root. The standard and quick-change forms alternate over full 12-bar sections. The blues preview renders both forms through the same engine and SynthDefs used by the Rock launcher.
