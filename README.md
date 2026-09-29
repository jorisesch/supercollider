# SuperCollider: space signals and rocket launch

- `audio/quindar-in.wav`: 2525 Hz, 250 ms signal with 2 ms softened edges.
- `audio/quindar-out.wav`: 2475 Hz, 250 ms signal with 2 ms softened edges.
- `audio/quindar-in-noisy.wav`: separate IN with LP-style groove noise, sparse sharp pops and fine crackle.
- `audio/quindar-out-noisy.wav`: separate OUT with the vinyl treatment, a separate random seed, and explicitly different pop timings.
- `audio/quindar-in-out.wav` (optional combined preview): the two signals separated by one second of silence.
- `audio/rocket-launch.wav`: 43-second stereo rocket launch: five short countdown beeps spaced one second apart, a higher ignition beep at 5.1 seconds, then three uneven startup surges that settle 4.2 seconds after ignition, low combustion rumble, subdued dark sand texture, irregular load drift, engine failure and recovery. Original synthesis; no film samples. Not a seamless loop.

WAVs are 48 kHz, stereo, 24-bit. Clean single-tone files include 50 ms leading silence and approximately 100 ms trailing silence. Noisy files last 900 ms: a 750 ms vinyl-textured channel starts after 50 ms, with the 250 ms tone starting 180 ms into that channel. Both noisy files are mono signals duplicated to stereo. This is an LP-inspired effect, not a historical recording.

## Standalone source for every WAV

Each WAV has a matching self-contained `.scd` beside it in `audio/`:

- [quindar-in.scd](audio/quindar-in.scd)
- [quindar-out.scd](audio/quindar-out.scd)
- [quindar-in-out.scd](audio/quindar-in-out.scd)
- [quindar-in-noisy.scd](audio/quindar-in-noisy.scd)
- [quindar-out-noisy.scd](audio/quindar-out-noisy.scd)
- [rocket-launch.scd](audio/rocket-launch.scd)

Each file includes all required SynthDefs and its complete timed arrangement, with no project-file or sample dependencies. Open one in SuperCollider, select all, and press **Cmd+Return** (Ctrl+Return on Windows/Linux). It boots the default server if needed and plays once. **Cmd+.** stops playback on macOS. No paths, command-line flags, or separate setup blocks are needed, and execution does not render files or quit the IDE.

To export WAVs, use `render.scd` as described below.

The standalone files are editable snapshots of the sounds. The shared instruments and render scripts below remain available; keep both versions consistent when editing synthesis.

## Play and control

Open `live.scd` in SuperCollider. Evaluate the first parenthesized block to load definitions, boot the server, and start a five-second countdown followed by the rocket engine. Evaluate the remaining lines individually to trigger the Quindar tones, change throttle/grit/pan, or release the rocket. `instruments.scd` only defines instruments and does not start audio. The rocket releases over 2.5 seconds.

The rocket has three unequal startup surges, then settles to steady combustion 4.2 seconds after ignition. There is no repeating whomp trigger or pitched oscillator in the engine. `motion` sets the depth of slow irregular load drift and `cycle` its approximate timescale. `throttle` controls average speed and noise brightness. `sand` controls the subdued, low-pass-filtered sand layer (default 0.28, range 0–1.5). `malfunction` introduces engine dropouts and sputter; return it to 0 to recover. The rendered arrangement fails at 20 seconds, recovers at 24 seconds, briefly stumbles again at 34 seconds, and recovers at 35.2 seconds.

## Re-render

From the repository directory on macOS with SuperCollider installed:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D render.scd
python3 verify_audio.py
```

`render.scd` is a standalone batch script and exits sclang when all six renders finish; do not load it into an IDE session you want to keep open. It uses stock UGens and offline synthesis, without requiring an audio device. A different installation may need its sclang executable path substituted.

`audio/verification.json` records measured levels, durations and tone frequencies. All six files rendered with exit code 0, have headroom and silent endings. Verification is numerical, not a listening review.

## Reusable skill

`skill/supercollider-music/` contains the portable skill source. To install for Codex, copy that folder into `${CODEX_HOME:-$HOME/.codex}/skills/`. Invoke it as `$supercollider-music` after skills are refreshed.

## References

Quindar specifications: [NASA speech research paper, Sangwan et al.](https://personal.utdallas.edu/~jxh052100/Publications/CP-Interspeech13-SangwanKaushikYuHansenOard-NSF_NASA-IS131434.PDF). The 2 ms edge shaping here is an intentional click-reduction choice.

Offline rendering: [SuperCollider Score documentation](https://doc.sccode.org/Classes/Score.html).
