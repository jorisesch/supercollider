# Run the music

Choose **EDM**, **Pop**, **Rock**, **London Dubstep** or **Soundscapes**. Each creates music continuously and opens a window with controls.

## Get ready

1. Install **[SuperCollider](https://supercollider.github.io/downloads)**. It is free; no sample packs or SuperDirt setup are needed.
2. Download this repository using **Code → Download ZIP** on GitHub, then unzip it.
3. Open **Terminal**, type `cd ` (with a space), drag the unzipped repository folder into Terminal, and press Return.

Run the commands below from the **repository folder**, not from inside `infinite/`.

## EDM

Each set starts with a randomly chosen song and eight bars of drums. Later songs begin with four bars of drums and use varied keys and ensembles.

Bass, drums and synth grooves, with strong mix compression for a fuller sound and new tracks mixed in automatically:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/infinite-edm.scd
```

## Pop

Each set starts with a randomly chosen song and eight bars of drums. Later songs begin with four bars of drums and follow the normal random rotation.

Bright synths, varied chord progressions and returning chorus hooks, with a compressed mix for a fuller sound:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/infinite-pop.scd
```

You can switch between EDM, Pop, Rock and London Dubstep from the DJ window's channel menu.

## Rock

Each song begins with four bars of drums before the guitars and bass enter.

Guitar riffs, occasional solos, bass and a room drum kit, with clean, crunch and fuzz arrangements:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/infinite-rock.scd
```

[Listen and see the Rock controls](experiments/dj/ROCK.md).

## London Dubstep

Each song begins with four bars of its drum pattern before the bass and synths enter.

Half-step drums, deep mono sub, sliding acid and short dub echoes. Acid Relay brings in a straight kick pattern before returning to half-step. Start it from the repository folder.

```sh
./bin/mobius.sh dubstep
```

## Soundscapes

Slow, infinitely evolving textures, with their own control window:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/infinite-soundscape.scd
```

These commands are for macOS. On Windows or Linux, replace the full executable path with `sclang` if it is on your PATH, or use the path to your installed `sclang` executable.

## Musical modes

Leave **Mode** on **Auto / varied songs** to explore different scales and song forms. Higher **Tension** unlocks rarer modes. Choose a named mode to pin a scale, or enable **Pentatonic melodies** for simpler leads, then press **Apply mode**. Use the **👍 / 👎** buttons under each deck to save a rating for later training. [Modes and examples](experiments/dj/MODES.md).

## Play and stop

The music and audio server start automatically. Try moving one knob at a time and allow a few seconds to hear the change.

**Close the control window to fade out and exit.** Press **Ctrl+C** in its Terminal to stop immediately. Close one session before launching another if you only want to hear one at a time.

See the **[DJ run guide](experiments/dj/README.md)** for the controls and help getting started.
