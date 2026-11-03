# Guitar phrasing prototypes

[Listen to the comparison](../../../../audio/rock-phrasing-comparison.m4a).

The same eight-bar E-minor phrase plays four times through the same guitar rig. These studies explore hand gestures and timing. The accepted Rock channel stays at commit `fa608b9`'s sound; none of these prototypes is enabled in the DJ.

| Starts | Performance | Listen for |
| --- | --- | --- |
| 0:00 | [Reference](../../../../audio/rock-phrasing-reference.m4a) | Accepted string instrument with its regular bend/vibrato envelopes. |
| 0:22 | [Restrained](../../../../audio/rock-phrasing-restrained.m4a) | More straight notes, late and gradually widening vibrato, small corrections. |
| 0:44 | [Loose](../../../../audio/rock-phrasing-loose.m4a) | Partial blues curls, a picked pre-bend releasing downward, pauses in vibrato and an intentionally under-bent passing note. |
| 1:06 | [Urgent](../../../../audio/rock-phrasing-urgent.m4a) | Earlier vibrato on selected notes, increasing rate, brief overshoots and a two-stage bend. |

Each excerpt is about 22 seconds. Picking level, written note onsets/durations, string/pickup settings and pedal settings stay fixed. Every version uses a common listening gain. The reference is the accepted instrument performing this comparison phrase, rather than a repeat of the earlier one-minute technique study.

Useful moments **within each excerpt**:

- **0:01.5:** bend from below toward A. The prototypes vary the hesitation, approach, correction and vibrato entrance.
- **0:02.6:** the new performances pick an already bent string, then release downward toward B.
- **0:05.1:** a long E. Restrained leaves it straight; Loose interrupts its vibrato; Urgent enters sooner.
- **0:07.4:** the Loose version leaves an A arrival a little flat. This is a passing expressive bend, not the final root.
- **0:08.5:** a two-stage bend in the prototypes, with a small intermediate plateau.
- **0:17:** the final E. Different vibrato entrances and growth lead to a brief settled root before release.

The pitches, timings and articulation choices are in [events.tsv](events.tsv). [RESEARCH.md](RESEARCH.md) distinguishes published findings from our design choices, explains the physical control path and lists remaining limitations. Human listening review of these prototypes is pending.

## Render again

From the repository folder, with SuperCollider installed:

```sh
sclang -D infinite/experiments/dj/guitar-prototypes/render.scd
python3 infinite/experiments/dj/guitar-prototypes/package.py
python3 scripts/verify_guitar_prototypes.py
python3 scripts/verify_audio.py
```

On macOS, use `/Applications/SuperCollider.app/Contents/MacOS/sclang` if `sclang` is not on your PATH. Rendering exits when complete and does not start live playback. WAVs stay local; the compact M4A files are the listening copies.

Optional macOS encoding, once per `reference`, `restrained`, `loose`, `urgent` and `comparison`:

```sh
afconvert -f m4af -d aac -b 192000 -q 127 audio/rock-phrasing-loose.wav audio/rock-phrasing-loose.m4a
```

`check.scd` validates seeded gesture choices and confirms loading the prototype leaves every accepted SynthDef and the accepted motion function unchanged. The Python check uses the rendered waveform, verifies the intended under-bend and settled phrase root, measures vibrato entrance times and checks the shared string calculation against the accepted body. [verification.json](verification.json) records numerical results separately from listening feedback.
