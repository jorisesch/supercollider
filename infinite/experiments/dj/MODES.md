# Musical color with Tension

EDM and Pop stay grounded in normal major and minor harmony. Turning **Tension** up keeps its brightness and drive, and adds occasional modal accents near phrase endings.

## Start with Auto

Leave **Mode** on **Auto / follows Tension** and move the **Tension** knob. The music keeps playing; there is no Apply step for the knob.

| Tension | Harmony |
| --- | --- |
| 0–60% | Normal major/minor scales. |
| Above 60% | Occasional Dorian accents in minor tracks, or Mixolydian in major tracks. |
| Above 85% | Rarer Phrygian accents in minor, or Lydian in major, also become possible. |

Each accent lasts **two bars**, then returns home. At least sixteen clear bars separate accents. Intros, handovers and Pop choruses keep their familiar harmony. Even at full Tension, the set spends most of its time in the base scale. Lowering Tension lets a current accent finish before returning to the normal scale.

| Base | More open color | Rarer color |
| --- | --- | --- |
| Minor / Aeolian | **Dorian:** raised sixth | **Phrygian:** flat second |
| Major / Ionian | **Mixolydian:** flat seventh | **Lydian:** raised fourth |

## Other choices

**Minor** or **Major** keeps that base family. A named mode narrows the preferred accent; it still enters sparsely at the appropriate Tension level in EDM/Pop. Press **Apply mode** after changing this menu; it restarts with a fade.

Check **Pentatonic melodies (five notes)** for simpler lead phrases, then press **Apply mode**. Backing chords retain the full active scale. Saved track names remember these choices and the harmony policy.

Rock keeps its fixed mode choices. Its Tension knob continues to control brightness and drive.

## Listen

[EDM Tension examples](../../../audio/edm-tension.m4a) · [Pop Tension examples](../../../audio/pop-tension.m4a)

These are four short excerpts selected from actual sets at full Tension: **Dorian, Phrygian, Mixolydian, Lydian**. Each plays four base bars, two colored bars, then two bars back home, followed by a fade. The examples bring rare events closer together for comparison; a continuous set uses them much less often.

## Start from Terminal

From the repository folder, with SuperCollider on your PATH:

```sh
sclang -D infinite/experiments/c-edm.scd
sclang -D infinite/experiments/pop.scd
```

On macOS, replace `sclang` with `/Applications/SuperCollider.app/Contents/MacOS/sclang` if needed. Close the control window to fade out and exit. To start with simpler melodies, append `melody=pentatonic`.

For fixed-mode studies, rendering and checks, see the [technical notes](TECHNICAL.md#tension-linked-modes-and-melody-palettes). Numerical and muted control checks are separate from listening review.
