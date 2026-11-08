# Scales and modes

Leave **Mode** on **Auto / varied songs** to hear a changing mix of scales. Each song keeps its base scale as the chords and sections develop.

| Tension | Available song scales |
| --- | --- |
| 0–60% | Aeolian, Ionian, Dorian and Mixolydian, favoring natural minor and major. |
| Above 60% | Harmonic minor and melodic minor also become possible. |
| Above 85% | Phrygian and Lydian join the choices. |

In EDM and Pop, high Tension can also add a brief modal accent near a phrase ending. Those accents last two bars and leave at least sixteen clear bars between them. Rock’s Tension also controls guitar brightness and drive.

Choose a named mode to keep the set in that scale. **Harmonic minor** raises natural minor’s seventh. **Melodic minor** raises its sixth and seventh. Press **Apply mode** to start a fresh set with your choice.

Check **Pentatonic melodies** for a five-note melody palette within the chosen scale. The backing chords use the full scale.

## Listen

[EDM Tension examples](../../../audio/edm-tension.m4a) · [Pop Tension examples](../../../audio/pop-tension.m4a)

The earlier Tension study contains four short excerpts at full Tension: **Dorian, Phrygian, Mixolydian, Lydian**. Each plays four base bars, two colored bars, then two bars back home, followed by a fade. The examples bring rare events closer together for comparison; a continuous set uses them much less often.

## Start from Terminal

From the repository folder, with SuperCollider on your PATH:

```sh
sclang -D infinite/experiments/c-edm.scd
sclang -D infinite/experiments/pop.scd
```

On macOS, replace `sclang` with `/Applications/SuperCollider.app/Contents/MacOS/sclang` if needed. Close the control window to fade out and exit. To start with simpler melodies, append `melody=pentatonic`.

For fixed-mode studies, rendering and checks, see the [technical notes](TECHNICAL.md#tension-linked-modes-and-melody-palettes). Numerical and muted control checks are separate from listening review.
