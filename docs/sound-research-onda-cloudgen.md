# Sound directions: Onda feedback and CloudGen grains

Source review for the infinite DJ and warm ambient experiments. These are design proposals; no synthesis or playback files were changed, and no human listening review of these references is recorded here.

## What the references do

[Onda's neural synth](https://onda-lang.org/playground/?example=feedback/neural_synth.onda), inspected in playground version 0.8.40, connects 14 nonlinear units with seeded, normalized random weights. Each has resonant feedback; slow modulation and noise keep the system moving. The source uses fourfold oversampling, saturation and DC filtering. Its weights are initialized rather than trained. The useful idea is a sound with internal, interacting motion. A musical adaptation should tie resonances to the harmony and retain a clear pitched core.

[CloudGenMiniBuf by bateslewis](https://sccode.org/1-4Sp) launches short sample fragments with variable position, speed, bend, duration, density, level and pan. Four envelope types and transitions between saved parameter ranges let a source become a changing cloud. The useful idea is to evolve a sound's texture while retaining its identity.

The user's [specific comment anchor](https://sccode.org/1-4Sp#c1096) points to [LFSaw's streamlined fork](https://sccode.org/1-5ii). It moves shared variables into the task's environment to support multiple instances. For our two decks, also provide separate buffers, groups, buses and task names, and pass buffer IDs as synth controls.

## Experiments to prioritize

| Candidate | Musical role | First comparison |
| --- | --- | --- |
| Warm granular cloud | Ambient harmony with more detailed motion | Resample our own sustained chord; scan slowly, overlap grains, and constrain transpositions to the harmony. Retain the existing low foundation. |
| Feedback body | A low drone or character layer on a bass/lead | Keep a clean pitched core and blend in a small amount of filtered feedback. Link motion to note velocity and phrase intensity. |
| Rhythmic resampling | A DJ riff with recognizable texture | Print our own two-bar phrase, then repeat chosen slices with occasional reverse swells or alternate attacks. Keep drums and note arrangement fixed for comparison. |

The current DJ already has FM, Reese, acid, brass and sync palettes. Grains and feedback introduce different signal structures; they are worth testing before another round of oscillator-palette variants.

## SuperCollider implementation notes

- [GrainBuf](https://doc.sccode.org/Classes/GrainBuf.html) provides stereo grain placement, playback rate, position and custom envelopes from a mono buffer. Start with our own rendered material. Grain density and duration jointly determine overlap; cap voices and compensate levels as density rises.
- [LocalIn](https://doc.sccode.org/Classes/LocalIn.html) and LocalOut provide synth-local feedback, with a one-block delay. An ordinary stock-UGen network would be an interpretation of Onda's sample-by-sample oversampled design; tuning and loop response need separate checks.
- [DynKlank](https://doc.sccode.org/Classes/DynKlank.html) provides tunable resonating bodies. Short, damped low modes are another option for adding body without returning to the high bell/harp character previously rejected.

Build each candidate separately. Compare the same notes, rhythm, register and approximately matched level; change one sound role per audition. Save seeds, source buffers, parameter trajectories and feedback before integrating a candidate into the infinite engines. Render and run the repository audio verifier when synthesis changes; keep those measurements separate from listening judgments.
