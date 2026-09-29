# SuperCollider: space signals and desert racer

- `audio/quindar-in.wav`: 2525 Hz, 250 ms signal with 2 ms softened edges.
- `audio/quindar-out.wav`: 2475 Hz, 250 ms signal with 2 ms softened edges.
- `audio/quindar-in-noisy.wav`: separate IN with LP-style groove noise, sparse sharp pops and fine crackle.
- `audio/quindar-out-noisy.wav`: separate OUT with the vinyl treatment, a separate random seed, and explicitly different pop timings.
- `audio/quindar-in-out.wav` (optional combined preview): the two signals separated by one second of silence.
- `audio/desert-pod-racer.wav`: 38-second stereo racer: 0.8–1.2-second whomps, continuous acceleration/deceleration, pitch rising with speed, engine failure and recovery. Original synthesis; no film samples. Not a seamless loop.

WAVs are 48 kHz, stereo, 24-bit. Clean single-tone files include 50 ms leading silence and approximately 100 ms trailing silence. Noisy files last 900 ms: a 750 ms vinyl-textured channel starts after 50 ms, with the 250 ms tone starting 180 ms into that channel. Both noisy files are mono signals duplicated to stereo. This is an LP-inspired effect, not a historical recording.

## Play and control

Open `live.scd` in SuperCollider. Evaluate the first parenthesized block to load definitions, boot the server, and start the racer. Evaluate the remaining lines individually to trigger the Quindar tones, change throttle/grit/pan, or release the racer. `instruments.scd` only defines instruments and does not start audio. The racer releases over 2.5 seconds.

The racer whomp interval is controlled by `whompPeriod` (0.8–1.2 seconds). `motion` sets the depth of continuous speed changes and `cycle` their duration. `throttle` sets average speed; pitch and brightness follow speed. `malfunction` introduces engine dropouts, sputter and pitch instability; return it to 0 to recover. The rendered arrangement fails at 15 seconds, recovers at 19 seconds, briefly stumbles again at 29 seconds, and recovers at 30.2 seconds.

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

## Review policy

All changes to skills, synthesis code, audio, and documentation require pull-request review before merging. Rendered audio should receive a listening review as well as numerical verification. Do not commit local logs or temporary OSC score files.

## References

Quindar specifications: [NASA speech research paper, Sangwan et al.](https://personal.utdallas.edu/~jxh052100/Publications/CP-Interspeech13-SangwanKaushikYuHansenOard-NSF_NASA-IS131434.PDF). The 2 ms edge shaping here is an intentional click-reduction choice.

Offline rendering: [SuperCollider Score documentation](https://doc.sccode.org/Classes/Score.html).
