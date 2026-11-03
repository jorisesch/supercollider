# Rock channel

An evolving band of rhythm guitar, picked bass and drums. Each song has a named guitarist with a consistent sound and playing style. It writes verse, chorus and bridge sections, then mixes into a new track. Occasional four- or eight-bar guitar solos leave plenty of backing-only passages.

[Hear the humbuckers play blues](../../../audio/rock-blues.m4a) · [Listen to the set](../../../audio/rock-player-set.m4a) · [Meet the guitarists](../../../audio/rock-player-comparison.m4a) · [Hear isolated playing and pedals](../../../audio/rock-guitar-study.m4a)

## Start

Choose **Rock** in the DJ window, or run this from the repository folder on macOS:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/rock.scd
```

The audio server starts automatically. On other platforms, replace the executable path with your installed `sclang`. **Close the window to fade out and exit**, or press **Ctrl+C** in Terminal to stop immediately.

## Hear a blues track

Some tracks in Rock’s default mode play a 12-bar blues with swung eighth notes and I7, IV7 and V7 chords. Each guitarist keeps their own pedal and playing style, with a vintage series humbucker feeding the rig. To start on the blues track from the preview, add `2601` after `rock.scd` in the launch command. Press **Riff** to bring in the lead.

[Pickup design and listening comparisons](guitar-pickups/README.md)

## Shape the band

- **Density** adds rhythmic detail; lower it to leave more room to play along.
- **Mutation** permits a small guitar answer at the end of an eight-bar phrase. **Hold** keeps the current track and its main rhythm.
- **Tension** adds guitar brightness and drive.
- **Riff** requests a four-bar guitar solo that resolves onto the current chord. **Fill** requests a drum fill.
- **Next** queues the next track. The same Start/Stop effects work here too.

The guitars are doubled with separate picking and small timing differences. Quieter sections leave more space; choruses open the chords. Each guitarist keeps the same pedal setup throughout the song, with modest changes in drive. Both guitars pass through a shared rig so their notes interact inside the drive circuit. A short drum room replaces EDM's kick-driven pumping. Automatic stutter starts off; the **Auto** button enables it.

## Meet the guitarists

The player's name appears below the track title. Hover over the title for more detail. A player stays with the song through verses, choruses, solos and the fade into the next track.

| Guitarist | Ensemble | Playing character |
| --- | --- | --- |
| **Rook** | Garage | Clipped eighth-note rhythm, short repeating replies, narrow vibrato and feedback overdrive. |
| **June** | Jangle | Ringing chords, spacious replies, lighter bends and gentle chorus. |
| **Flint** | Fuzz room | Heavy spaced riffs, whole-step bends, slower vibrato and a steady distortion/fuzz sound. |

These are fictional players. Each has a main rhythm, a related phrase-ending answer and a small lead vocabulary. Picking and intonation still vary within the player's habits. The three-player comparison starts Rook at **0:00**, June at **0:23** and Flint at **0:46**. [Playing rules and listening notes](PLAYERS.md).

## Guitar feel and effects

Lead phrases use string bends, fretted slides and delayed finger vibrato. The final pitch settles onto its chord tone. Palm muting changes the string's decay, and picking strength changes how hard it drives the pedals.

| Ensemble | Guitar treatment |
| --- | --- |
| Garage | Feedback overdrive and light compression. |
| Jangle | Cleaner two-stage overdrive, gentle chorus and ringing strings. |
| Fuzz room | Diode distortion with a consistent two-stage fuzz blend. |

**Tension** increases gain and brightness. Compression, drive, fuzz, chorus and the speaker filter process **only the guitars**. The earlier ensemble comparison starts with four-bar solos: Garage at **0:00**, Jangle at **0:23**, Fuzz room at **0:46**.

The [isolated guitar study](GUITAR.md) demonstrates each playing technique, followed by the same phrase through the different circuits. It also explains the physical models and their remaining simplifications.

## Guitar solos

Press **Riff** to hear a short call, its answer over the next chord, a five-note climb and a held bend. Automatic solos use the same phrasing. An eight-bar solo answers the first phrase in a higher register. The rhythm guitars ease back while the lead plays. The final note usually lands on the **root of the chord sounding at that moment**, with its third or fifth as occasional alternatives. The held ending finishes before the next chord bar.

With **Pentatonic melodies** enabled, the ending must fit both the chord and the five-note palette. If the root is outside that palette, the solo chooses a permitted third or fifth instead. **Next** gives an active solo a short cadence before the handover.

In the earlier set preview, the first eight-bar solo starts around **0:57** and resolves around **1:14**.

## Play with scales

The first default track starts in **E minor**. Try **E minor pentatonic: E G A B D** over it. The key is shown in the track's tooltip and changes with new records; use **Hold** to stay with one track.

Choose **Dorian** in the main **Mode** menu for brighter minor harmony, or **Mixolydian** for major harmony with a flat seventh. Check **Pentatonic melodies** for five-note lead replies, then press **Apply mode**. The backing chords still use the full seven-note mode. [More about modes](MODES.md).

The sounds are synthesized strings and drums. The new player comparison is ready for listening feedback.

For rendering and checks, see the [technical notes](TECHNICAL.md#rock-channel). The earlier finite [rock backing tracks](../../studies/rock/README.md) remain available for practice.
