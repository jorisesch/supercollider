# Rock channel

An evolving band of rhythm guitar, picked bass and drums. It writes verse, chorus and bridge sections, then mixes into a new track. Clean, crunch and fuzz ensembles rotate as it plays. Occasional four- or eight-bar guitar solos leave plenty of backing-only passages.

[Listen to the set](../../../audio/rock-channel.m4a) · [Compare the three guitar sounds](../../../audio/rock-tones.m4a) · [Hear isolated playing and pedals](../../../audio/rock-guitar-study.m4a)

## Start

Choose **Rock** in the DJ window, or run this from the repository folder on macOS:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/rock.scd
```

The audio server starts automatically. On other platforms, replace the executable path with your installed `sclang`. **Close the window to fade out and exit**, or press **Ctrl+C** in Terminal to stop immediately.

## Shape the band

- **Density** adds rhythmic detail; lower it to leave more room to play along.
- **Mutation** lets the guitar rhythm change. **Hold** keeps the current track.
- **Tension** adds guitar brightness and drive.
- **Riff** requests a four-bar guitar solo that resolves onto the current chord. **Fill** requests a drum fill.
- **Next** queues the next track. The same Start/Stop effects work here too.

The guitars are doubled with separate picking and small timing differences. Quieter sections use cleaner, ringing notes; choruses open the chords. Selected phrases use fuzz. Both guitars pass through a shared rig so their notes interact inside the drive circuit. A short drum room replaces EDM's kick-driven pumping. Automatic stutter starts off; the **Auto** button enables it.

## Guitar feel and effects

Lead phrases use string bends, fretted slides and delayed finger vibrato. The final pitch settles onto its chord tone. Palm muting changes the string's decay, and picking strength changes how hard it drives the pedals.

| Ensemble | Guitar treatment |
| --- | --- |
| Garage | Feedback overdrive and light compression. |
| Jangle | Cleaner two-stage overdrive, gentle chorus and ringing strings. |
| Fuzz room | Diode distortion and selected two-stage fuzz phrases. |

**Tension** increases gain and brightness. Compression, drive, fuzz, chorus and the speaker filter process **only the guitars**. The ensemble comparison starts with four-bar solos: Garage at **0:00**, Jangle at **0:23**, Fuzz room at **0:46**.

The [isolated guitar study](GUITAR.md) demonstrates each playing technique, followed by the same phrase through the different circuits. It also explains the physical models and their remaining simplifications.

## Guitar solos

Solos build a short idea, repeat it, answer it and leave gaps. The rhythm guitars ease back while the lead plays. The final note usually lands on the **root of the chord sounding at that moment**, with its third or fifth as occasional alternatives. The held ending finishes before the next chord bar.

With **Pentatonic melodies** enabled, the ending must fit both the chord and the five-note palette. If the root is outside that palette, the solo chooses a permitted third or fifth instead. **Next** gives an active solo a short cadence before the handover.

The set preview's first eight-bar solo starts around **0:57** and resolves around **1:14**.

## Play with scales

The first default track starts in **E minor**. Try **E minor pentatonic: E G A B D** over it. The key is shown in the track's tooltip and changes with new records; use **Hold** to stay with one track.

Choose **Dorian** in the main **Mode** menu for brighter minor harmony, or **Mixolydian** for major harmony with a flat seventh. Check **Pentatonic melodies** for five-note lead replies, then press **Apply mode**. The backing chords still use the full seven-note mode. [More about modes](MODES.md).

The sounds are synthesized strings and drums. This channel is still a sound-design work in progress; the guitar-tone comparison plays Garage at **0:00**, Jangle at **0:23**, and Fuzz room at **0:46** for listening feedback.

For rendering and checks, see the [technical notes](TECHNICAL.md#rock-channel). The earlier finite [rock backing tracks](../../studies/rock/README.md) remain available for practice.
