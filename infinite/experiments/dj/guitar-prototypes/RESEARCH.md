# Phrasing research and design notes

Research/review date: **2026-11-02**. Accepted reference checkpoint: **`fa608b9`**, committed locally; no push was requested. These prototypes are for comparison and have not been promoted into the live DJ.

## What the sources support

**Bend placement depends on the phrase.** D'Hooge, Bigo and Déguernel's [Modeling Bends in Popular Music Guitar Tablatures](https://arxiv.org/abs/2308.12307) studies 932 lead tablatures. Their representation includes the neighboring pitches, durations, beat strength and fret/string positions. Their corpus contains upward, downward and held bends, with many ordinary notes. This supports contextual ornament selection. It does not establish the probabilities or intonation errors used in these prototypes.

**Vibrato has temporal structure.** Desain and colleagues' [Rhythmic Aspects of Vibrato](https://www.mcg.uva.nl/mcg-2023/papers/dhat-2/dhat-2.html) considers rate, extent, shape and their relation to note transitions and tempo. They observed performer-dependent behavior and changing rates within notes. Their participants played cello, oboe, violin, theremin and voice; this is cross-instrument evidence, not measured electric-guitar timing data. Our use of delayed entrances, growth and selective acceleration is an inference for this instrument.

**Finger vibrato and a bridge arm are different mechanisms.** Grimes's [String Theory: The Physics of String-Bending and Other Electric Guitar Techniques](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0102088) derives models of bending, fretting and vibrato, with experimental validation of string-bending behavior. It supports keeping pitch related to the speaking length and tension. These prototypes continue to model lateral finger motion on a fretted string; they do not add a whammy-bar simulation.

**A bent note can vibrate around, above or below its held pitch.** The instructor's [Applying Vibrato with Bends lesson](https://www.infiniteguitar.com/guitar-lessons/vibrato-technique-applying-vibrato-with-bends) discusses those alternatives as playing choices. This supports different directions of pressure change around a pre-bend, rather than always adding more sharp vibrato above the peak.

These findings motivate the design. The three profiles, their constants and their curated phrase are our experiments, not fitted models of a named guitarist or numerical claims about how all players perform.

## Implementation choices

`gestures.scd` writes the hand trajectory separately from the synthesis. The same phrase has 19 notes, including short connectors, held statements, passing ornaments and a final E. A deterministic stream chooses small timing/intonation differences. Held errors persist coherently through a gesture; independent audio-rate pitch jitter is not used.

| Profile | Notes without a finger bend | Notes with vibrato | Character |
| --- | --- | --- | --- |
| Restrained | 15 of 19 | 6 of 19 | Delayed entrances, gradual growth and one deliberately straight held statement. |
| Loose | 10 of 19 | 9 of 19 | Curls, pressure relaxation, interrupted vibrato and a slightly flat passing bend. |
| Urgent | 13 of 19 | 9 of 19 | Selected early entrances, faster hand motion, overshoot/correction and staged bends. |

Vibrato delays are chosen in seconds and constrained by the note's available duration. They are not all a fixed fraction of a note. Most raw delays in this seeded phrase range from roughly 0.02 to 0.51 seconds; the first clearly measurable oscillation follows the depth envelope's rise. Arrival bends often wait until the initial pitch approach is complete. Rate and depth then evolve independently, with modest slow cycle variation. Some Loose gestures briefly relax their depth while the hand's oscillator continues, preserving phase on resumption.

The seed is reproducible. A different seed can alter the expressive details without changing the written phrase. The intentionally ornament-rich study makes differences easy to compare; its bend density is not a proposed setting for every DJ solo.

### Pitch comes from the string

`instruments.scd` obtains the accepted string's length, mass, stiffness and unbent tension. A hand-gesture envelope specifies the intended bend in semitones above that fret. The required additional tension is:

```
extraTension = (T + E*I*pi^2/L^2) * (2^(2*bendSemitones/12) - 1)
```

The code finds a lateral finger displacement that produces that extra tension through geometric string elongation. Two Newton corrections refine the small-deflection estimate. The resulting tension drives the same 28 stiff-string modes and magnetic-pickup model as the accepted guitar.

An arrival can start two frets below its target. A pre-bend can start with pressure already applied, then release toward its fret. An unbent finger vibrato can pull sharp and return to its anchor. On an already bent string, the hand can relax below the held bend or oscillate around it. Total bend tension never falls below the unbent fret's tension.

The Loose version's second A arrival intentionally remains about **14 cents flat** in the rendered probe. Other passing bends can overshoot and correct or make only a partial blues inflection. The final E stays on its fret and lets vibrato relax before note release. These choices distinguish expressive inflection from accidentally losing the harmonic destination.

### Keep the comparison interpretable

The voice hoists common terms out of its 28-mode calculation to fit a portable OSC definition. A separate render compares the optimized calculation with the accepted body, with gestures disabled. The measured relative waveform difference after the pick transient is about **0.003%**, attributable to floating-point evaluation order.

All four listening versions use the accepted two-stage overdrive rig at the same settings, without chorus, reverb or an accompanying band. The same note onsets, durations, nominal picking level, pickup location and common output gain are retained. Differences in pitch/pressure can naturally affect the nonlinear rig's response. This study makes no new claim about pedal calibration.

## What remains approximate

- Hand-motion envelopes are designed trajectories. They do not solve muscles, finger inertia or neuromotor feedback and have not been fitted to recorded gestures.
- The vibrato rate/depth distributions are design choices informed by the sources, not population statistics for electric guitar.
- Separate notes initialize fresh modal state. These prototypes do not yet solve continuous string state through legato, hammer-ons, pull-offs or simultaneous-string sympathetic coupling.
- Notes have deliberately stable picking and timing for comparison. A later performance study can coordinate accents, note length and microtiming with the gestures.
- The accepted rig still uses reduced circuit models and synthetic speaker filtering; measured amplifier/cabinet responses and full circuit dynamics remain open work.

## Review next

Use the [timestamped listening guide](README.md) to compare the same phrase. Listen for whether the restrained version leaves enough space, whether Loose sounds expressive or merely inaccurate, and whether Urgent's rate growth becomes tiring. Good individual gestures can be combined later with a sparser phrase-level selection policy. No automatic promotion is implied by a numerical pass.

The final signal check includes **93 waveform pitch measurements**, with a maximum discrepancy of **2.77 cents** from the model on the measured portions. Steep transitions are excluded from the short-window periodicity bound; their control paths and settled endpoints are checked separately. The probe confirms the intentionally flat passing note and the final root. Whole-clip levels differ by about **0.02 dB**, so loudness provides little advantage to any candidate.

The numerical records are [verification.json](verification.json), [events.tsv](events.tsv) and [probes.tsv](probes.tsv). Source and audio hashes are recorded in [reproduction.json](reproduction.json). Detailed human listening review and a preferred prototype are still pending.
