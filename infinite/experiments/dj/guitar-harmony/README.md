# Guitar chords and phrasing

Listen to the [complete comparison](../../../../audio/rock-harmony-comparison.m4a) (2:22). It explores chord shapes, bass movement and accompaniment patterns using the picking-hand guitar instrument. These are separate studies for listening review; the live DJ channels retain their current behavior.

| In the comparison | Study | Listen for |
| --- | --- | --- |
| 0:00 | [Triads and inversions](../../../../audio/rock-triad-voicings.m4a) | A and F#m in three inversions; a progression first in root position, then with smaller movements between notes. |
| 0:33 | [Sevenths and ninths](../../../../audio/rock-chord-colors.m4a) | A, Amaj7, A7, Am7, Aadd9 and A9, each strummed and then picked note by note. |
| 1:09 | [Slash chords](../../../../audio/rock-slash-chords.m4a) | A/C#, A/E, a ringing low E beneath changing upper chords, and a descending bass line. |
| 1:42 | [Accompaniment patterns](../../../../audio/rock-chord-phrasing.m4a) | The same four chords as block strums, offbeat stabs, bass/treble answers and arpeggios. |

Within the individual clips:

- **Triads:** A inversions at 0:00; F#m inversions at 0:08; root-position progression at 0:16; smoother inversions at 0:24.
- **Colors:** A at 0:00; Amaj7 at 0:06; A7 at 0:12; Am7 at 0:18; Aadd9 at 0:24; A9 at 0:30.
- **Slash chords:** A → A/C# → A/E at 0:00; E pedal at 0:08; descending bass at 0:16; A/E–E7 riff resolving to Aadd9 at 0:24.
- **Patterns:** block strums at 0:00; syncopation at 0:10; bass/treble answers at 0:20; arpeggios at 0:30. The later arpeggio bars pick the new bass a sixteenth note early.

The accompaniment loop is **A – F#m7 – Dadd9 – E7**, at 100 BPM. Its last E7 leaves the vamp open for a return to A. Each study has one fixed listening gain, preserving its internal dynamics. All four use the same clean guitar rig, with compression, chorus, drive, echo and reverb disabled so the harmony stays exposed.

## Recreate the audio

From the repository folder, with SuperCollider installed:

```sh
sclang -D infinite/experiments/dj/guitar-harmony/render.scd
python3 infinite/experiments/dj/guitar-harmony/package.py
python3 scripts/verify_guitar_harmony.py
python3 scripts/verify_audio.py
```

On macOS, the language executable may be `/Applications/SuperCollider.app/Contents/MacOS/sclang`. Rendering runs offline and exits when finished. Play the generated WAVs from `audio/`; stop playback in your audio player. There is no live process to stop after rendering.

To recreate the public M4A copies on macOS:

```sh
for name in rock-triad-voicings rock-chord-colors rock-slash-chords rock-chord-phrasing rock-harmony-comparison; do
  afconvert -f m4af -d aac -b 192000 -q 127 "audio/$name.wav" "audio/$name.m4a"
done
```

Edit chord spelling and string/fret shapes in [harmony.scd](harmony.scd), or change patterns and timing in [performance.scd](performance.scd). The renderer reuses the [picking-hand instrument](../guitar-contact/README.md) and its dependencies. WAVs and temporary diagnostic scores remain outside Git.

See [research and design notes](RESEARCH.md), [chord/fret table](chords.tsv), [performed string events](events.tsv), [numerical results](verification.json) and [reproduction record](reproduction.json). Numerical checks passed; human listening review is pending.
