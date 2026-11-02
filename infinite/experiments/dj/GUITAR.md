# Guitar model and listening study

[Listen to the isolated guitar study](../../../audio/rock-guitar-study.m4a) · [Hear it with the band](../../../audio/rock-channel.m4a)

[Listening feedback and next experiments](GUITAR-REVIEW.md).

The one-minute study makes the playing and processing easy to hear:

| Time | Demonstration |
| --- | --- |
| 0:00 | Picked, ringing reference note |
| 0:04 | Whole-tone bend, hold and release |
| 0:08 | Bend from below into the written note |
| 0:12 | Delayed finger vibrato, settling before release |
| 0:16 | Fretted slide from E to A on the high E string |
| 0:20 | Four open attacks, then four palm-muted attacks |
| 0:24 | Clean phrase and chord |
| 0:30 | Blues Driver family of gain stages |
| 0:36 | Tube Screamer feedback overdrive |
| 0:42 | DS-1 family of distortion stages |
| 0:48 | Two-stage Muff-family fuzz |
| 0:54 | Clean phrase with chorus |

Each pedal example uses the same notes, picking, phrase and chord. Levels retain the rigs' response; this is a listening study, not a loudness-matched hardware shootout.

## What the hands do

A bend stretches a string sideways against a fret. The additional length increases tension; pitch rises approximately with the square root of tension. Releasing the bend lowers it again. Finger vibrato in this rock model repeatedly bends and releases the fretted string, so an unbent note moves sharp and returns to its anchor. Vibrato on an already bent note modulates the added tension. Classical longitudinal vibrato and bridge-arm vibrato use different motions. Yamaha demonstrates [bends, vibrato, hammer-ons, pull-offs and bridge-arm techniques](https://www.yamaha.com/en/musical_instrument_guide/electric_guitar/play/).

The implementation derives extra tension from a finger's lateral displacement `d`:

```
extraLength = sqrt(L*L + d*d) - L
            + sqrt(R*R + d*d) - R
extraTension = E*A*extraLength / totalElasticLength
```

`L` is the speaking length and `R` represents the remaining elastic string. The code uses the numerically stable equivalent of each square-root subtraction. Half- and whole-tone bend targets determine the displacement. The bend's hand-motion envelope controls that displacement, while vibrato contributes to the same tension calculation. The depth envelope starts after the attack and returns to zero before the note ends. Arrival bends start from a lower fret and hold the target.

A fretted finger slide moves the stopping point along the neck. The speaking length changes as successive frets take over, with brief contact transitions and quiet friction transients. The model follows those fret positions; it does not model a bottleneck slide. Each fret `f` sets `L = 0.648 * 2^(-f/12)` metres. The planner assigns a playable string and keeps connecting slides on that string. The physical distinction between clamping, horizontal friction and string elongation is described in Evangelista's [string–fret interaction model](https://www.dafx.de/paper-archive/2011/Papers/96_e.pdf).

Palm muting adds loss near the bridge. A mode moving strongly at that contact point loses more energy. This changes the decay and brightness together. Picking location also changes the modal excitation; picking harder increases the initial displacement and the pickup voltage delivered to the pedal.

## String and pickup

`rock-physical-instruments.scd` computes 28 modes of a stiff steel string. Core diameters and effective mass densities distinguish the six strings; wound strings use separate effective mass and core stiffness. For each mode:

```
f_n = n/(2*L) * sqrt(T/mu + (E*I/mu)*(n*pi/L)^2)
```

The initial displacement is triangular. Its modal coefficients follow the pluck location, and higher modes decay more quickly. A finite pickup aperture averages their motion. Mode amplitudes are converted to velocity at the pickup position, then filtered by a simplified pickup/cable resonance. Magnetic pickups sense velocity through electromagnetic induction; [Penn State's pickup research](https://www.acs.psu.edu/drussell/guitars/pickups.html) explains the distinction from displacement and force sensors. The initial-condition and stiffness treatment follows Smith's [ideal plucked string](https://www.dsprelated.com/freebooks/pasp/Ideal_Plucked_String.html) and [stiff string](https://www.dsprelated.com/freebooks/pasp/Stiff_String.html) treatments.

The triangular pluck's strain energy also supplies a small temporary tension increase. Its decay uses an explicit two-time-scale approximation. Bank's [energy-based tension-modulation research](https://home.mit.bme.hu/~bank/publist/dafx09.pdf) motivates relating the pitch glide to string energy. The current patch does not calculate the full nonlinear, coupled string motion.

## Pedal circuits and signal order

Each deck processes its summed guitars through a shared stereo rig: compression, the selected drive/fuzz, chorus and a speaker filter. Bass and drums join afterward. The notes of a chord interact in each side's nonlinear stages, producing compression and intermodulation.

For the diode stages, Kirchhoff's current law and the antiparallel Shockley diode equation give:

```
x = y + 2*R*Is*sinh(y/(n*VT))
```

The implementation solves this equation with four Newton steps. It derives the transfer function's integral analytically and uses first-order antiderivative antialiasing. That method reduces high-frequency foldback by averaging the nonlinear response between successive input samples. See Parker, Zavalishin and Le Bivic's [ADAA paper](https://www.dafx.de/paper-archive/2016/dafxpapers/20-DAFx-16_paper_41-PN.pdf).

The drive paths have distinct topologies:

- **Tube Screamer:** a 4.7 kΩ / 47 nF feedback branch emphasizes upper frequencies before its diode pair. The input signal survives alongside the limited feedback voltage. The 51 pF feedback capacitor is represented by a conditioning filter; the active tone network uses its derived second-order transfer function.
- **DS-1:** transistor preamplification and a gain-dependent amplifier stage precede the shunt diodes. Its tone control blends low-pass and high-pass branches, creating the characteristic mid scoop.

Those component-derived reductions follow Yeh, Abel and Smith's [physically informed pedal models](https://www.dafx.de/paper-archive/2007/Papers/p189.pdf). The live implementation approximates nonlinear capacitor memory with linear conditioning filters plus the static circuit solution; it is not a sample-by-sample solution of the full circuit ODE.

- **Blues Driver:** two separate, rail-limited gain blocks, interstage filtering, and a subsequent diode stage with two series junctions in each direction follow the structure in the [BOSS BD-2 service schematic, page 3](https://stompboxelectronics.com/wp-content/uploads/2023/01/BOSS-BD2_ServiceNotes.pdf). Differential-pair saturation is reduced to a bounded transfer curve; individual transistor currents and feedback dynamics are not solved.
- **Fuzz:** two AC-coupled, feedback-diode clipping stages feed a passive-style tone blend. The family reference is the builder's [Halo/Muff schematic](https://aionfx.com/app/files/docs/halo_documentation.pdf). Transistor loading and every historical Muff component variant are outside this reduction.
- **Chorus:** a common low-frequency clock varies a 1024-stage BBD-equivalent delay, `delay = stages/(2*clock)`. Bandwidth filtering surrounds the delay and the wet signal is mixed with dry guitar. The [Azure/CE-2 circuit documentation](https://aionfx.com/app/files/docs/azure_documentation.pdf) provides the circuit reference. Clock feedthrough, noise and charge-transfer nonlinearities are omitted.
- **Compressor:** an envelope detector with separate 6 ms attack and 120 ms release drives a soft-knee gain computer in decibels. A higher input above threshold produces proportionally less output growth. This is an explicit dynamics processor, without claiming a particular compressor pedal's OTA or optical circuit.

The loudspeaker stage supplies broad low resonance and high-frequency rolloff. It is a synthetic filter, not a measured cabinet impulse response or a complete valve-amplifier model.

## Scope and verification

The source is editable, uses stock SuperCollider UGens and needs no recordings or third-party plugins. These are reduced physical models. Two string polarizations, fret collisions, continuous modal-state transfer between separate notes and a full amplifier/cabinet model remain future work. Connecting slides reduce the pick transient and continue their modes through the slide event; they still initialize a new modal state at that event's start. Hammer-ons and pull-offs are not currently generated.

New Rock sessions use tone version 2. Earlier saved tracks retain their earlier instrument and routing. EDM and Pop keep their existing synthesis and musical events.

From the repository folder:

```sh
sclang -D infinite/experiments/dj/rock-physical-render.scd
python3 scripts/verify_rock_physical.py
sclang -D infinite/experiments/dj/rock-physical-check.scd
```

The signal checks measure actual waveform pitch and settled endings, fixed frets during bends, intermediate frets during slides, the diode solution against an independent bisection solver, ADAA against the analytical integral, alias reduction, chord intermodulation, compression and PCM-identical bass/drums. The score checks cover playable string assignments, unchanged written music, guitar-only controls and saved-track replay. These checks establish the implementation's behavior. Listening review remains separate.
