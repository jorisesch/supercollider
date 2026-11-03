# Infinite DJ

Music that keeps playing, creating and mixing new tracks as it goes. Start it, leave it running, or shape the music with the controls.

## Install

1. Download and install **[SuperCollider](https://supercollider.github.io/downloads)**. It is free.
2. Download this repository using **Code → Download ZIP** on GitHub, then unzip it.
3. Open **Terminal**. Type `cd ` (including the space), drag the unzipped repository folder into Terminal, and press Return.

You only need to install SuperCollider once. You do not need SuperDirt or any sample packs.

## EDM

On macOS, paste this into Terminal and press Return:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/c-edm.scd
```

The control window opens and music starts. The audio server starts automatically—there is nothing else to launch.

On Windows or Linux, open a terminal in the repository folder and run the same command with your SuperCollider installation's `sclang` executable. If it is on your PATH, use:

```sh
sclang -D infinite/experiments/c-edm.scd
```

## Use the controls

Start with the default settings. Try moving one knob at a time:

| Control | What it does |
| --- | --- |
| **Chaos** | Adds rhythmic variation and fills. |
| **Density** | Adds more notes and percussion. |
| **Mutation** | Lets musical patterns change more often. |
| **Tension** | Adds brightness and drive; high settings add brief modal accents in EDM/Pop. |
| **Next** | Requests the next track. |
| **Bass hook / Chorus / Riff** | Brings the current track's hook forward. |
| **Fill** | Requests a drum fill. |
| **Hold** | Keeps the current track playing. |
| **STOP / START** | Fades out, then lets you continue the same set. |

Changes enter on musical boundaries, so allow a few seconds to hear them. The highlighted track is the one you are hearing. The spectrum shows the sound's frequencies.

To try an effect, choose **Filter**, **Echo**, **Wash** or **Stutter** from the effect menu, then press **Start FX**. Press **Stop FX** to release it. Selecting an effect alone does not turn it on.

## Pop channel

Choose **Pop** in the window's channel menu, or start it directly on macOS:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/pop.scd
```

Pop chooses from a broad range of chord progressions and timings. Verses, choruses and bridges have different harmony, while the chorus keeps a recognizable melody.

Switching channels starts a new set with a fade. Close your current session before launching another from Terminal.

## Rock channel

Choose **Rock** in the channel menu, or start it directly:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/rock.scd
```

Rock creates guitar riffs, blues grooves, bass and drum arrangements with clean, crunch and fuzz sounds. Each song keeps a named guitarist, one pickup type, and a consistent playing character. Occasional longer solos resolve onto the current chord. [Listen and try it](ROCK.md).

## Soundscapes

For infinitely evolving soundscapes, use this separate launcher:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/infinite-run.scd soundscape
```

It opens its own control window. Close the DJ window before starting it if you only want to hear soundscapes.

## Try musical modes

In EDM and Pop, leave **Mode** on **Auto / follows Tension**. Above 60%, Tension can add brief modal accents; above 85%, rarer colors become possible. Normal major/minor harmony remains the foundation, and Pop choruses keep their returning harmony. Moving Tension keeps the set playing.

Optional **Pentatonic melodies** use five-note lead phrases. Press **Apply mode** after changing the Mode or Pentatonic choices; that restarts with a fade. Rock keeps fixed mode choices. [Listen to the examples and see the choices](MODES.md).

## Stop

**Close the control window** to fade out and exit. To stop immediately, press **Ctrl+C** in the Terminal window that launched it.

## If it does not start

- **“No such file”**: check that Terminal is in the unzipped repository folder and that SuperCollider is installed in Applications.
- **“sclang not found”**: on macOS, use the full `/Applications/SuperCollider.app/Contents/MacOS/sclang` command above.
- **Port already in use**: close the previous session before starting another. A custom SuperCollider `startup.scd` may also start extra services; Infinite DJ does not require that file.
- **No sound**: check your computer's output device and volume, and press **START** if the window says it is stopped.

For source code, rendering and development checks, see the [technical notes](TECHNICAL.md).
