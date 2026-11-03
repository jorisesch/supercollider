# Slash solo study for Rock

Three recorded solos and Slash’s accounts suggest a direction for Rock’s existing guitarists. Give the lead a short musical idea that survives the chord changes, then give its return a clear destination. The proposals below are original generator rules drawn from the references.

| Solo | What to listen for | Candidate rule for Rock |
| --- | --- | --- |
| **November Rain** | Listen to the early lead passages separately from the outro. Slash recalls finding the solo over the song’s changes on acoustic guitar, and describes a solo as an extension of the vocal or a countermelody. [Official recording](https://www.youtube.com/watch?v=4_fvXrgAm1A) · [Slash interview](https://www.guitarworld.com/artists/guitarists/slash-guns-n-roses-2025) | Let a compact motif answer the backing or recall the song’s hook. Reuse its rhythm and contour across chords, adjusting one or two destination notes to fit the harmony. Leave a rest after the answer. |
| **Sweet Child O’ Mine** | Listen for the seam between the melodic opening and the more aggressive second half. Slash recalls using the neck pickup first, then the bridge for the second part, which he recorded as a separate overdub. [Official recording](https://www.youtube.com/watch?v=1w7OgIMMRc4) · [Slash interview](https://www.guitarworld.com/features/slash-izzy-stradlin-guns-n-roses-appetite-destruction) | Reserve the upper register and a short, dense run for a phrase boundary. Use the pickup prototype to audition a neck-to-bridge change at that same boundary after testing the phrasing by itself. |
| **Estranged** | Listen for sustained notes that swell into the piano arrangement. Slash recalls using the neck pickup with the tone rolled down, a saturated amp and the guitar volume control for swells. [Official recording](https://www.youtube.com/watch?v=8VgRL8Htv7k) · [Slash interview](https://www.theskinny.co.uk/music/interviews/slashs-guitar-clinic) | Select one long note for a volume swell before drive, and give the phrase a rest afterwards. Audition that against the existing sharp picked attack with the same note and rig. |

## In the Rock channel

**Riff** and automatic solos now use the four-bar audition's phrasing. The second bar echoes the call's rhythm and keeps its pitch intervals when the new chord and scale allow it. The third bar climbs toward the next chord, leaving room for a picked pickup and a held semitone bend in the fourth. Eight-bar solos repeat the form with a higher register target. Rook, June and Flint have different opening rhythms, contours and vibrato. The final pitch fits the sounding chord and the selected melody scale. [Rock controls](ROCK.md#guitar-solos)

## Four-bar audition

The [A/B clip](../../../audio/rock-riff-study.m4a) opens with June's previous Riff. The new phrase starts at **0:14** over the same Em–D–Am–Am backing and deck automation. The answer keeps the call's rhythm and moves its pitches up a whole step, landing on the third of D. A five-note run lifts the register before a semitone bend into a held A. This first audition compares phrasing and articulation.

To render the comparison, run `sclang -D infinite/experiments/dj/rock-riff-study.scd` from the repository folder. The command writes `audio/rock-riff-study.wav` and exits. Run `python3 scripts/verify_audio.py` to check the WAV.
