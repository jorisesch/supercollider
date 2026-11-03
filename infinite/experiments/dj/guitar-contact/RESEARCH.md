# Picking-hand research and model notes

Research date: **2026-11-02**. Accepted sound checkpoint: **`fa608b9`**. These studies extend the separate [phrasing prototypes](../guitar-prototypes/README.md); they do not replace the live DJ instruments.

## Research findings

**Double stops need separate strings and selective articulation.** Fender's [double-stop lesson](https://www.fender.com/play/courses/slides-and-double-stops/lessons/lead-guitar-double-stops) covers adjacent and nonadjacent string pairs. A pick can cross neighboring strings with a short delay; a thumb/finger pinch can select nonadjacent strings directly. We use both cases, plus independent finger motion for an oblique bend. The untouched partner supplies a pitch reference and can beat against the approaching bent note.

**Strum direction has an audible signature.** [Murgul, Schimper and Heizmann's strumming-transcription research](https://publikationen.bibliothek.kit.edu/1000184108/164087225) studies direction and chord recognition from acoustic-guitar recordings. It supports treating a stroke as more than a chord label. It does not provide a universal inter-string delay or prove that every upstroke has one particular timbre. Fender's [strumming guidance](https://www.fender.com/articles/techniques/how-to-strum-beginner-guitar-tips) also treats speed, wrist motion, pick angle and position as playing variables.

**Pick contact affects the string before amplification.** Smith's [pluck-modeling treatment](https://www.dsprelated.com/freebooks/pasp/Pluck_Modeling.html) describes a spring/damper contact that disengages, with its response related to the string's wave impedance. Germain and Evangelista's [2009 publisher abstract](https://ieeexplore.ieee.org/document/5346502/) describes a beam-based plectrum model with a release condition. We used that mechanical approach as motivation; the full beam-contact algorithm was not reproduced from the abstract.

**Contact shape matters.** Woodhouse's [plucked-string explanation](https://euphonics.org/5-3-synthesising-plucked-strings/) connects a sharp or rounded initial string shape to its modal content. His [guitar-synthesis paper](https://euphonics.org/wp-content/uploads/2022/03/Guitar_I.pdf) also examines coupled string/body behavior and damping. These models motivate finite contact width and release-dependent modal amplitudes rather than a material-specific output EQ.

**Material, geometry and playing depth interact.** Pluta and colleagues' [robotic-plucking study](https://vibsys.put.poznan.pl/_journal/2025-36-2/articles/vps_2025205.pdf) varies attack depth in small steps and tests several plectra. Both material and depth affect the sound, and mounting/repeatability matter. Its acoustic-guitar results do not directly calibrate our electric-guitar model. They argue against interpreting a pick-material comparison without controlling the hand trajectory.

## What is modeled

### A stroke crosses physical string positions

The planner uses 10.5 mm string spacing. For a constant-speed stroke, crossing time is distance divided by speed. With constant acceleration:

```
crossingTime = 2*distance / (initialSpeed + sqrt(initialSpeed^2 + 2*acceleration*distance))
```

Downstrokes visit the selected strings from low E toward high E. Upstrokes reverse that order. The first controlled comparison uses the same voicings, coverage, depth and speed in both directions. The next condition deliberately narrows the upstroke to treble strings; this makes the contribution of coverage explicit. A final condition contrasts a slower rake with a fast return.

String deflection polarity also reverses with the stroke. Polarity alone would not change the magnitude spectrum of a linear system. The audible contrasts here come chiefly from the order and spread of onsets, which strings are involved, and how their signals combine. No blanket “upstroke treble EQ” is applied.

The selected voicings assign one pitch to each actual string with a valid fret. Pair pinches can omit intervening strings. Repeated strokes use a fresh release event; continuous re-plucking of an already vibrating string remains a limitation.

### Pick flexibility and string stiffness share the hand travel

The pick is reduced to a cantilever with effective modulus `E`, width `w`, thickness `t` and free length `l`:

```
pickStiffness = E*w*t^3 / (4*l^3)
stringStiffness = tension * (1/pluckDistance + 1/(length-pluckDistance))
stringDisplacement = handTravel * pickStiffness / (pickStiffness+stringStiffness)
```

The pick's flex and the string's displacement therefore share the travel. Halving thickness changes bending stiffness by a factor of eight for the same material and free length. Material hardness, elastic modulus, thickness and grip length are distinct concepts; the preset labels should not be read as interchangeable physical quantities.

For the edge-angle case, the model resolves the rectangular beam's two bending compliances along the rotated direction. Rotation also lengthens the modeled bevel traversal and contact footprint. It consequently changes the release time, modal phase and harmonic amplitudes together. The attack-plane tilt remains at 20° in these contact comparisons; edge rotation and plucking-plane orientation are separate controls. This is a reduction of contact geometry; sliding friction, edge rasp and detailed 3D tip curvature are not solved.

The finger-pad preset uses an effective contact stiffness and a broad footprint. The nail uses a thinner, shorter beam with its own footprint. Their numerical properties are illustrative choices, not population measurements of skin or nail mechanics. Finger players can compensate with greater displacement or another trajectory; the equal-travel experiment is not a loudness ranking of playing techniques.

### Release determines the modal initial conditions

The string wave impedance is `Z = sqrt(tension*massPerLength)`. A spring-coupled release supplies a characteristic time scale `2*Z/pickStiffness`. We add a geometric bevel-traversal term and, for pad/nail contact, an effective additional release term.

The resulting first-order release kernel modifies each modal initial condition by:

```
amplitudeFactor = 1 / sqrt(1 + (angularFrequency*releaseTime)^2)
phase = -atan(angularFrequency*releaseTime)
```

This uses the spring/impedance response as a **release-smoothing approximation**. It is not a full time-domain solution of contact, slip and separation. Averaging force over a finite contact width adds a spatial sinc factor. The initial triangular displacement supplies the remaining modal coefficients.

`contact.scd` computes those coefficients before creating each voice. It retains displacement and phase information, not just a brightness number. `instruments.scd` then evolves 40 primary string modes and 12 modes of a second transverse polarization, sensing their velocity at the same magnetic pickup. The second polarization has a small illustrative end-compliance difference, separate loss and weaker pickup sensitivity. It is not a measured bridge/fret admittance.

The stored string energy also supplies a small decaying tension increase. An optional finger gesture can subsequently bend just that string using the earlier physical tension model. The two double-stop voices stay independent until their pickup signals meet in the shared rig.

## How to interpret the experiments

The raw contact pass keeps hand travel fixed and lets the mechanics determine amplitude. The matched pass applies a constant gain to each already-rendered material example. This preserves the modeled excitation and any dynamics through the rig while making tone easier to compare. The three public studies also receive recorded overall listening gains. There is no adaptive per-note gain normalization.

The studies use the existing pickup/rig with no new material-specific output filters. Strum and contact comparisons use the clean path. Double stops use shared feedback overdrive, so simultaneously sounding notes can generate intermodulation. No measured pedal or amplifier calibration is claimed.

## Verification and remaining work

The pure SuperCollider check covers contact states across all six strings, five contacts, several depths and speeds. It checks force equilibrium, finite modal energy, cubic thickness dependence, valid string order and double-stop independence. It also verifies that loading the study leaves the accepted motion function and every existing instrument graph unchanged.

The dry render gives each string a separate channel. The Python check measures actual onset order and spread, compares measured upper partials with the release/footprint prediction for the **same string and fret**, and tracks the bending and held voices independently. Separate note-level and probe tables preserve the actual contact parameters, since changing the string changes its impedance and release response. The matched pass is checked for equal levels, and all WAVs are checked for format, duration, non-silence, headroom and quiet tails.

The current dry full-stroke measurements span **34.69 ms downward** and **34.67 ms upward**, with the individual string onsets in the expected order. The simultaneous control's threshold crossings span about **0.02 ms**. The measured upper-partial changes agree with the selected release/footprint model within **0.04 dB**; that validates the implementation against its equations, not against a recorded guitar. The held partner's modeled fundamental spans about **0.26 cents** during the independent bend, and waveform periodicity checks confirm separate pitch motion. The matched contact pass has equal segment RMS levels within the recorded numerical precision.

The model still omits full nonlinear slip/contact dynamics, measured tip geometry, bridge-mediated string coupling, continuous state through re-strikes and realistic body/fret collision noise. These are controlled synthesis experiments, not a finished instrument-identification model. Detailed listening review is pending.

See [verification.json](verification.json), [events.tsv](events.tsv), [probes.tsv](probes.tsv) and [reproduction.json](reproduction.json) for results and hashes. The [listening guide](README.md) gives all comparison timestamps.
