# Double stops, strumming and pick contact

[Listen to all three studies](../../../../audio/rock-hand-comparison.m4a).

| Starts in the combined clip | Study |
| --- | --- |
| 0:00 | [Strum direction and timing](../../../../audio/rock-strum-study.m4a) |
| 0:41 | [Pick angle, flexibility, finger pad and nail](../../../../audio/rock-contact-study.m4a) |
| 1:41 | [Double stops and independent bends](../../../../audio/rock-double-stops.m4a) |

These are separate prototypes for listening. The accepted Rock, EDM and Pop channels are unchanged. Source and audio remain local; nothing has been pushed.

## Strum study

Times within the strum clip:

- **0:00:** an ideal simultaneous chord, as a control.
- **0:08:** full downstrokes, low strings first.
- **0:16:** full upstrokes over exactly the same strings and voicings, high strings first.
- **0:24:** alternating full downstrokes and shorter upstrokes over the treble strings.
- **0:32:** slower downstroke rakes alternating with fast upstrokes.

The same chord sequence repeats. String spacing, hand speed and acceleration determine each note's onset. The ordinary full sweeps span about 35 ms; the slower/faster examples change that spread. Changing the participating strings is shown separately from reversing direction.

## Contact study

The same single-note phrase and chord repeat with:

| Raw pass | Matched-level pass | Contact |
| --- | --- | --- |
| 0:00 | 0:30 | Stiff pick with a square edge |
| 0:06 | 0:36 | The same pick rotated to a 45° edge angle |
| 0:12 | 0:42 | Flexible pick at half the thickness |
| 0:18 | 0:48 | Soft finger pad |
| 0:24 | 0:54 | Fingernail edge |

The first pass preserves relative loudness for the same modeled hand travel. The second matches levels after rendering so the release and harmonic differences are easier to compare. An overall listening gain is common to the entire clip.

Pick flex, string stiffness, contact width and release time determine the initial string modes. The pickup and output rig stay the same. Material properties are illustrative model parameters, not measurements of named picks or fingers.

## Double-stop study

- **0:00:** adjacent-string thirds, with the small delay of a pick crossing two strings.
- **0:08:** sixths on nonadjacent strings, pinched with fingers.
- **0:16:** one string bends toward a held partner, followed by a pre-bend release and a staged bend. The partner does not follow the bend.
- **0:24:** short two-string chops alternating with ringing answers.

The two notes have separate string models and finger gestures, then enter a shared overdrive rig. Their beating and nonlinear interaction emerge from the two signals sounding together.

## Recreate

From the repository folder:

```sh
sclang -D infinite/experiments/dj/guitar-contact/render.scd
python3 infinite/experiments/dj/guitar-contact/package.py
python3 scripts/verify_guitar_contact.py
python3 scripts/verify_audio.py
```

On macOS, use `/Applications/SuperCollider.app/Contents/MacOS/sclang` if needed. Rendering exits automatically. The packaging step builds the matched pass and combined comparison from local WAVs. The public listening copies are M4A files; WAVs remain ignored by Git.

See [research and limitations](RESEARCH.md), [per-string events](events.tsv), [diagnostic events](probes.tsv) and [numerical results](verification.json). Listening review of these studies is pending.
