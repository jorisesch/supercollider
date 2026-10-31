# SuperCollider experiments

Generative music, synthesized sound design, and a reusable skill for creating both. The repository includes editable SuperCollider code, live controls, and rendered examples.

| Project | Explore |
| --- | --- |
| **Infinite music** | An evolving four-track generator with EDM and soundscape modes. [Guide and code](infinite/README.md). |
| **Sound design** | A pod-racer engine built from synthesis, with ignition, gear changes, flybys, and canyon echoes. [Sound-design guide](docs/sound-design.md). |
| **SuperCollider skill** | A reusable workflow for composing music, designing instruments, and rendering and verifying audio. [Skill instructions](skill/supercollider-music/SKILL.md). |

## Infinite music

Four interacting musical lanes share harmony, tempo, and phrase structure. EDM combines a Markov bassline, repeating lead motifs, a Euclidean arpeggio, and probabilistic drums. Soundscape mode uses a low foundation, harmonic clouds, sparse melodic notes, and air.

Run from the repository directory on macOS with SuperCollider installed:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/infinite-run.scd edm 0.25 0.55 0.30 0.20 128 2600
```

The window exposes **Chaos**, **Density**, **Mutation**, and **Tension**, plus fill, mutate, hold, restart, and stop buttons. Close it to fade out and exit. Playback continues until stopped and does not export audio.

See the [infinite music guide](infinite/README.md) for soundscape mode, parameters, IDE controls, and composition checks. All generator code lives in [`infinite/`](infinite/).

## Sound design: pod racer

A 30-second vehicle scene moves from reluctant twin-piston ignition through warm-up, gear transitions, canyon passes, and a short maximum-speed burst. Two detuned sawtooths and an accelerating filter form the core, with supporting mechanical textures and spatial effects. The sound is synthesized without film samples.

- [Listen to the rendered scene](audio/pod-racer.wav).
- [Play the self-contained patch](audio/pod-racer.scd): open it in SuperCollider, select all, and evaluate with **Cmd+Return** on macOS (**Ctrl+Return** on Windows/Linux).
- [Use the live controls](pod-racer-live.scd) to adjust speed, filter motion, gear changes, flybys, and canyon reflections.
- Read the [research brief](POD_RACER_RESEARCH.md) and [sound-design guide](docs/sound-design.md) for synthesis details, other sound studies, and rendering instructions.

The collection also includes a rocket launch and clean and vinyl-textured Quindar signals. Sound-effect WAVs are stereo, 48 kHz, 24-bit. Their standalone playback patches live alongside them in [`audio/`](audio/).

## SuperCollider skill

[`skill/supercollider-music/`](skill/supercollider-music/) contains a portable skill for turning a musical or sound-design brief into editable instruments, playable arrangements, and rendered audio. It covers stock UGens, voice lifetimes, live controls, reproducible rendering, and numerical verification, with human listening review treated separately.

To install it for Codex, run from the repository directory:

```sh
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R skill/supercollider-music "${CODEX_HOME:-$HOME/.codex}/skills/"
```

Refresh skills, then invoke `$supercollider-music`. The [skill source](skill/supercollider-music/SKILL.md) is also readable as a standalone workflow.
