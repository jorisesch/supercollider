---
name: supercollider-music
description: Compose music and design synthesized sounds in SuperCollider, delivering editable .scd instruments, playable arrangements, and rendered audio. Use for SuperCollider composition, drones, sci-fi effects, synthesis patches, and WAV exports.
---

# SuperCollider music

Translate the brief into a sonic identity, controllable instruments, and a playable result. Infer sensible duration and arrangement when unspecified; explain the choice briefly. For sound effects, prioritize the requested identity over adding musical accompaniment.

## Build

- Inspect workspace instructions and existing patches first. Locate sclang and scsynth; on macOS check /Applications/SuperCollider.app/Contents/{MacOS,Resources}. Prefer stock UGens unless installed extensions are verified.
- Keep SynthDefs separate from live playback and rendering. Resolve sibling files relative to thisProcess.nowExecutingPath, capturing that path before asynchronous callbacks.
- Declare vars at the beginning of each function. Use stable control names with useful defaults: amp, gate, out, plus musical controls such as freq, throttle or brightness. Clamp controls that could drive unstable filters or extreme frequencies.
- Give sustained voices a gate/release and one-shots an envelope with doneAction: 2. Remove DC, stage gains conservatively, and limit complex layered outputs. Smooth live parameter changes. Do not globally stop unrelated sessions to manage a patch.
- Create depth with purposeful layers and different time scales: foundation, character, texture, space. Use correlated modulation for coherent motion; reserve independent noise for organic variation. For music, shape phrases and transitions rather than merely stacking loops.
- Include a minimal live example with definition loading, s.waitForBoot, s.sync before Synth creation, parameter edits, and a graceful stop. Keep rendering from starting live playback.

## Render and verify

Use Score/recordNRT for reproducible offline output when possible. Put SynthDef bytes in /d_recv before /s_new, set tempo to 1 for seconds, and include releases and effect tails before the final dummy event. Configure output channels and sample rate explicitly. Seed random UGens when reproducibility matters. Exit command-line sclang only after all render callbacks finish; never exit a user's IDE as a side effect of loading instrument definitions.

Run the actual SuperCollider code and inspect logs for parser, missing-UGen, and server errors. Verify rendered WAV sample rate, channels, duration, non-silence, finite samples, peak headroom, and start/end behavior. Check requested pitched effects against their target frequencies. Listen if audio audition tools are available; otherwise report numerical verification honestly without claiming a listening pass.

Deliver editable source and clickable audio previews, with concise instructions for starting, changing, and stopping the sound. Distinguish an evolving drone from a seamless loop. Use official local help or https://doc.sccode.org for uncertain APIs. Verify historical signal specifications against sources instead of inventing authenticity.
