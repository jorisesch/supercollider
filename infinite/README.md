# Run the music

Choose **EDM**, **Pop**, or **Soundscapes**. Each creates music continuously and opens a window with controls.

## Get ready

1. Install **[SuperCollider](https://supercollider.github.io/downloads)**. It is free; no sample packs or SuperDirt setup are needed.
2. Download this repository using **Code → Download ZIP** on GitHub, then unzip it.
3. Open **Terminal**, type `cd ` (with a space), drag the unzipped repository folder into Terminal, and press Return.

Run the commands below from the **repository folder**, not from inside `infinite/`.

## EDM

Bass, drums and synth grooves, with new tracks mixed in automatically:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/c-edm.scd
```

## Pop

Bright synths, varied chord progressions and returning chorus hooks:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/pop.scd
```

You can also switch between EDM and Pop using the DJ window's channel menu.

## Soundscapes

Slow, infinitely evolving textures, with their own control window:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/infinite-run.scd soundscape
```

These commands are for macOS. On Windows or Linux, replace the full executable path with `sclang` if it is on your PATH, or use the path to your installed `sclang` executable.

## Play and stop

The music and audio server start automatically. Try moving one knob at a time and allow a few seconds to hear the change.

**Close the control window to fade out and exit.** Press **Ctrl+C** in its Terminal to stop immediately. Close one session before launching another if you only want to hear one at a time.

See the **[DJ run guide](experiments/dj/README.md)** for the controls and help getting started.
