# Sound design

The pod racer is the main sound-design study: a synthesized vehicle scene with a distinct engine character, gear changes, and canyon reflections. Rocket launch and Quindar signals are additional experiments.

All file paths and terminal commands below are relative to the repository root.

- `audio/quindar-in.wav`: 2525 Hz, 250 ms signal with 2 ms softened edges.
- `audio/quindar-out.wav`: 2475 Hz, 250 ms signal with 2 ms softened edges.
- `audio/quindar-in-noisy.wav`: separate IN with LP-style groove noise, sparse sharp pops and fine crackle.
- `audio/quindar-out-noisy.wav`: separate OUT with the vinyl treatment, a separate random seed, and explicitly different pop timings.
- `audio/quindar-in-out.wav` (optional combined preview): the two signals separated by one second of silence.
- `audio/rocket-launch.scd`: source for the 43-second stereo rocket launch: five short countdown beeps spaced one second apart, a higher ignition beep at 5.1 seconds, then three uneven startup surges that settle 4.2 seconds after ignition, low combustion rumble, subdued dark sand texture, irregular load drift, engine failure and recovery. Original synthesis; no film samples. Not a seamless loop. Its rendered WAV is local-only.
- `audio/pod-racer.scd`: source for the 30-second research-based pod racer scene that moves from reluctant twin-piston ignition through warm-up, gear transitions, canyon reflections, a short maximum-speed burst, and release. Its core is two slightly detuned sawtooths through an accelerating LFO-controlled filter, with restrained grit, rare casing clanks, and slow Doppler passes. Its rendered WAV is local-only.

Committed Quindar WAVs are 48 kHz, stereo, 24-bit. Clean single-tone files include 50 ms leading silence and approximately 100 ms trailing silence. Noisy files last 900 ms: a 750 ms vinyl-textured channel starts after 50 ms, with the 250 ms tone starting 180 ms into that channel. Both noisy files are mono signals duplicated to stereo. Larger rendered WAVs are generated locally and ignored by Git. This is an LP-inspired effect, not a historical recording.

## Standalone source for each sound

Each sound has a matching self-contained `.scd` beside it in `audio/`:

- [quindar-in.scd](../audio/quindar-in.scd)
- [quindar-out.scd](../audio/quindar-out.scd)
- [quindar-in-out.scd](../audio/quindar-in-out.scd)
- [quindar-in-noisy.scd](../audio/quindar-in-noisy.scd)
- [quindar-out-noisy.scd](../audio/quindar-out-noisy.scd)
- [rocket-launch.scd](../audio/rocket-launch.scd)
- [pod-racer.scd](../audio/pod-racer.scd)

Each file includes all required SynthDefs and its complete timed arrangement, with no project-file or sample dependencies. Open one in SuperCollider, select all, and press **Cmd+Return** (Ctrl+Return on Windows/Linux). It boots the default server if needed and plays once. **Cmd+.** stops playback on macOS. No paths, command-line flags, or separate setup blocks are needed, and execution does not render files or quit the IDE.

To export local WAVs, use `patches/render.scd` as described below. Rendered WAVs are intentionally not committed.

The standalone files are editable snapshots of the sounds. The shared instruments and render scripts below remain available; keep both versions consistent when editing synthesis.

The pod racer source is also available as [pod-racer.scd](../patches/pod-racer.scd), with its arrangement in [pod-racer-render.scd](../patches/pod-racer-render.scd) and live controls in [pod-racer-live.scd](../patches/pod-racer-live.scd). The source follows the sound-design approach described in the StarWars.com interviews linked below: a collage of familiar vehicle textures, distinct gear transitions, and a dry close engine with sparse canyon echoes. `speed` raises the engine pitch, `lfoRate` controls the acceleration cue, `gear` triggers a transition, `flyby` triggers a slow stereo pass, `canyon` sends transient material to the wall echoes, and `clankRate` controls rare mechanical strikes.


## Play and control

Open `patches/live.scd` in SuperCollider. Evaluate the first parenthesized block to load definitions, boot the server, and start a five-second countdown followed by the rocket engine. Evaluate the remaining lines individually to trigger the Quindar tones, change throttle/grit/pan, or release the rocket. `patches/instruments.scd` only defines instruments and does not start audio. The rocket releases over 2.5 seconds.

The rocket has three unequal startup surges, then settles to steady combustion 4.2 seconds after ignition. There is no repeating whomp trigger or pitched oscillator in the engine. `motion` sets the depth of slow irregular load drift and `cycle` its approximate timescale. `throttle` controls average speed and noise brightness. `sand` controls the subdued, low-pass-filtered sand layer (default 0.28, range 0–1.5). `malfunction` introduces engine dropouts and sputter; return it to 0 to recover. The rendered arrangement fails at 20 seconds, recovers at 24 seconds, briefly stumbles again at 34 seconds, and recovers at 35.2 seconds.

## Re-render

From the repository directory on macOS with SuperCollider installed:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D patches/render.scd
python3 scripts/verify_audio.py
```


`patches/render.scd` is a standalone batch script for the Quindar and rocket renders and exits sclang when all six renders finish. To render the pod racer separately, run `/Applications/SuperCollider.app/Contents/MacOS/sclang -D patches/pod-racer-render.scd`. Run batch renderers from the terminal rather than loading them into an IDE session you want to keep open. All use stock UGens and offline synthesis. Substitute your installation’s sclang path where needed.

`audio/verification.json` records measured levels, durations and tone frequencies for the committed Quindar previews. Larger local renders are excluded from the public tree.

## References

Quindar specifications: [NASA speech research paper, Sangwan et al.](https://personal.utdallas.edu/~jxh052100/Publications/CP-Interspeech13-SangwanKaushikYuHansenOard-NSF_NASA-IS131434.PDF). The 2 ms edge shaping here is an intentional click-reduction choice.

Pod-racer sound design: [Ben Burtt on The Phantom Menace](https://www.starwars.com/news/ben-burtt-the-phantom-menace) and [Matthew Wood on The Phantom Menace](https://www.starwars.com/news/matthew-wood-the-phantom-menace).

Offline rendering: [SuperCollider Score documentation](https://doc.sccode.org/Classes/Score.html).
