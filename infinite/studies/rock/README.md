# Rock backing tracks

Three practice tracks with rhythm guitar, bass and drums, leaving space for you to play. The guitar-like sounds are synthesized plucked strings; no sample packs are needed. Each arrangement is 32 bars with a clean ending, about 74–87 seconds including the decay.

## Listen and choose a scale

| Track | Feel | Notes to start with |
| --- | --- | --- |
| [Ironwood](../../../audio/rock-ironwood.m4a) · 102 BPM | Palm-muted power-chord rock | **E minor pentatonic:** E G A B D |
| [Green Room](../../../audio/rock-green-room.m4a) · 94 BPM | Clean, syncopated minor groove | **A Dorian:** A B C D E F♯ G |
| [Open Road](../../../audio/rock-open-road.m4a) · 112 BPM | Open, driving major chords | **D Mixolydian:** D E F♯ G A B C |

**Pentatonic means five notes.** Ironwood keeps both the bass and guitar inside E minor pentatonic. E5, G5, A5 and D5 chords leave room to improvise with that same five-note shape.

**Heptatonic means seven notes.** Dorian and Mixolydian are seven-note modes, each with a distinct color:

- Over **Green Room**, start with A minor pentatonic: **A C D E G**. Add **F♯** to hear the brighter Dorian sixth, then **B** when you want the full mode. Am7 and Dadd9 make that minor-to-major-IV contrast audible.
- Over **Open Road**, start with D major pentatonic: **D E F♯ A B**. Add **C** for the Mixolydian flat seventh and **G** for the full mode. The D–C–G–D progression supports that sound.

Try short phrases, leave a gap, and answer them. You do not need to use every note at once.

## Selective effects

The added effects come and go with the arrangement; they do not cover the whole band.

| Track | What changes |
| --- | --- |
| Ironwood | Overdrive joins the answer around **0:38**. Left-side fuzz enters around **0:47**, with occasional upper-bass grit; the other guitar retains definition. |
| Green Room | Overdrive accents the answer around **0:31**. Short wah responses follow; the quieter section stays clean. |
| Open Road | More overdrive enters around **0:26**. Slapback catches selected phrase endings. |

To remove the added effects while keeping the original amp tone, add `nofx` to the play command, for example `sclang -D infinite/studies/rock/run.scd ironwood nofx`. In the IDE, use `~rockPlay.value(\ironwood, s, false);`.

## Play locally

Install [SuperCollider](https://supercollider.github.io/downloads), open Terminal in the repository folder, and run on macOS:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/studies/rock/run.scd ironwood
```

Replace `ironwood` with `greenroom` or `openroad` for the other tracks. The server starts automatically and the arrangement plays once, then exits. **Ctrl+C** stops immediately. On other platforms, use your installed `sclang` executable in place of the macOS path.

## Change the backing

For interactive playback, open [live.scd](live.scd) in SuperCollider and evaluate the whole file. Then evaluate individual lines:

```supercollider
~rockPlay.value(\ironwood);
~rockMaster.set(\amp, 0.7); // lower the backing level
~rockStop.value;           // fade out
~rockPlay.value(\greenroom);
~rockPlay.value(\openroad);
```

To slow Ironwood down, set `~rockSpecs[0].bpm=85;` before starting it. The other tracks are indices 1 and 2. [tracks.scd](tracks.scd) contains the arrangements; [instruments.scd](instruments.scd) defines the sounds and starts no playback on its own.

## Render and check

```sh
sclang -D infinite/studies/rock/check.scd
sclang -D infinite/studies/rock/runtime-check.scd
sclang -D infinite/studies/rock/render.scd
python3 scripts/verify_audio.py
# Optional measured comparison with the original amp tone:
sclang -D infinite/studies/rock/render.scd nofx
python3 scripts/verify_rock_fx.py
```

Add a track ID to the render command to export just one study. WAVs go to `audio/` and remain local; the small M4A files are the listening previews. These are finite arrangements with endings, not seamless loops or a new Infinite DJ channel.

The composition check verifies timing, scale membership, characteristic modal notes, backbeats and reproducibility. Numerical audio verification is recorded in `audio/verification.json`; it does not replace listening review. The [manifest](manifest.json) records the keys and settings. Human listening review is pending.
