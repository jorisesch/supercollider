# Sound patches and startup example

These are the standalone sound-design sources, separate from the [Infinite DJ](../infinite/experiments/dj/README.md) and [Neon Rush](../neon-rush/README.md) music projects. Paths in terminal commands below are relative to the repository root.

| Files | Purpose |
| --- | --- |
| [instruments.scd](instruments.scd) | Quindar radio tones, vinyl texture, rocket engine and countdown SynthDefs; loading starts no playback. |
| [live.scd](live.scd) | Interactive rocket launch and Quindar controls; evaluate the first block, then individual control lines. |
| [render.scd](render.scd) | Offline Quindar and rocket rendering; exits after all six exports finish. |
| [pod-racer.scd](pod-racer.scd) | Pod racer SynthDef; loading starts no playback. |
| [pod-racer-live.scd](pod-racer-live.scd) | Interactive pod racer playback and controls. |
| [pod-racer-render.scd](pod-racer-render.scd) | Offline 30-second pod racer arrangement. |
| [sonar-ping.scd](sonar-ping.scd) | Sonar ping SynthDef; loading starts no playback. |
| [sonar-ping-live.scd](sonar-ping-live.scd) | Interactive sonar ping playback. |
| [sonar-ping-render.scd](sonar-ping-render.scd) | Offline sonar ping export with its decay tail. |
| [startup.scd](startup.scd) | Optional user-startup example that boots the default server and starts SuperDirt; requires SuperDirt and its samples. |

## Play or render

For select-all playback, the self-contained sound patches remain in [audio/](../audio/). Open one in SuperCollider and evaluate it with Cmd+Return on macOS, or Ctrl+Return on Windows/Linux. Cmd+. stops playback on macOS. The `*-live.scd` files above offer separate interactive controls.

```sh
sclang -D patches/render.scd
sclang -D patches/pod-racer-render.scd
sclang -D patches/sonar-ping-render.scd
python3 scripts/verify_audio.py
```

Renderers resolve their dependencies relative to their source files, write WAVs into the repository's `audio/` directory and exit after completion. Run them in a terminal, rather than loading them into an IDE session you want to keep open. Generated WAVs and temporary scores are ignored by Git. Verification can also be run from another directory using the script's full path.

## Optional startup

The repository's `startup.scd` is an example, not an automatically installed startup file. Infinite DJ boots its own server and does not require it. See the [startup explanation](../docs/startup.md) before installing it. Your existing user startup file is not changed by this folder reorganization.

See the [sound-design guide](../docs/sound-design.md) and [pod racer research](../docs/POD_RACER_RESEARCH.md) for synthesis details and references.
