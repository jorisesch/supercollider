# Guitar harmony study notes — 2026-11-02

Request: different chord phrasings, triads, inversions, sevenths, added ninths and slash chords such as A/E. This study changes the score and string assignments. It uses the previous contact model and guitar signal path without altering their synthesis or the accepted Infinite DJ.

## Chord identity, voicing and bass

Root position, first inversion and second inversion put the root, third and fifth respectively in the bass. The root remains the same even when another chord tone is lowest. A slash symbol explicitly specifies the bass: A/E requires E below the A harmony. D/E is a different case: E is outside the D triad, so the sound combines D–F#–A with a low E. [Open Music Theory: Inversion](https://viva.pressbooks.pub/openmusictheory/chapter/inversion/).

Sevenths need a precise quality. An unqualified 7 means the dominant seventh; maj7 and m7 specify different chords. An added ninth preserves the triad and does not imply a seventh; a dominant ninth includes the minor seventh. These distinctions follow [Open Music Theory: Chord Symbols](https://viva.pressbooks.pub/openmusictheory/chapter/chord-symbols/). The study encodes them explicitly:

| Symbol | Pitch classes | Guitar shape, low E to high E |
| --- | --- | --- |
| A | A C# E | x02220 |
| Amaj7 | A C# E G# | x02120 |
| A7 | A C# E G | x02020 |
| Am7 | A C E G | x02010 |
| Aadd9 | A C# E B | x02420 |
| A9 | A C# E G B | x02423 |
| A/E | E beneath A C# E | 002220 |
| A/C# | C# beneath A C# E | x4222x |

`x` means an unplayed string. Numbers indicate frets; `0` is open. Both add9 shapes used in the accompaniment retain their third: C# in Aadd9 and F# in Dadd9. They are not suspended-second chords. The Am7 comparison is an intentional parallel-minor color, separate from the diatonic accompaniment loop.

For triads, each of three selected strings carries exactly one different chord pitch class. The A examples are A3–C#4–E4, C#4–E4–A4 and E4–A4–C#5. The F#m examples likewise demonstrate all three bass choices. Full slash-chord examples also use low strings, making the contrast with treble-only triads explicit.

## Movement between chords

Berklee's guitar lesson describes smooth voice leading through held common notes and small movements between corresponding voices. It also explains harmonic resolution rules for thirds and sevenths. [Berklee: Voice Leading for Guitar](https://online.berklee.edu/takenote/voice-leading-for-guitar/).

Our algorithm implements a narrower minimum-motion objective. It enumerates closed triads on the D, G and B strings, retains valid chord pitches in ascending order, and uses dynamic programming to minimize the sum of absolute semitone movement per string across the complete progression. Both comparisons start from the same root-position A. The initial register preference is a tiny tie-break; no random selection affects the path.

The eight-chord comparison, A–F#m–D–E repeated twice, requires **103 semitones of total movement** when all triads remain in root position, versus **21** when inversions are allowed. This measures aggregate movement across three voices and seven transitions. It does not measure musical quality, and this implementation is not a classical counterpoint or functional-resolution solver.

The playable-shape filter requires unique strings, frets within range, at most four distinct stopped frets and a stopped-fret spread of at most four. Enumerated triads use frets 0–14 and span less than an octave. Named shapes can extend to fret 19. This is a practical screening heuristic; it does not assign fingers, prove every hand position comfortable, simulate barre pressure or model physical transitions between shapes.

## Bass movement and rhythm

The E pedal re-picks E2 every three seconds while the upper harmony changes every 1.5 seconds: E, A/E, D/E, E7. The first bass note remains audible through the next upper chord. Each upper note is an independent string voice; slash labels are checked against the actual lowest MIDI pitch, not only the chord root.

The descending line uses A3–G#3–F#3–E3–D3–C#3–B2, then E3 as a dominant turnaround. The high-register A and E/G# shapes keep that descent in one register. A subsequent A/E–E7 riff resolves to Aadd9.

Four accompaniment passes share A–F#m7–Dadd9–E7 and 100 BPM:

- Block strums sustain on beats 1 and 3.
- Syncopated short attacks fall on beat offsets 0.5, 1.75, 2.5 and 3.5, counting the bar from zero.
- Bass/treble answers alternate low-string attacks with upper-string pinches half a beat later.
- Eighth-note arpeggios vary string order and sustain. The first bass note of bars 2–4 anticipates the bar by 0.15 seconds, a sixteenth note at this tempo. The other notes retain their grid positions.

Old arpeggio notes release before an anticipated harmony change. The pedal section deliberately permits a common E to ring across changes. Up/down attacks and material-dependent contact latency come from the earlier picking-hand model; all sections use a fixed clean rig. This isolates harmony and articulation. It does not demonstrate how every dense voicing will behave under heavy distortion.

## Verification and remaining listening work

SuperCollider checks 22 named shapes, chord pitch sets, inversion basses, deterministic voicing paths and 538 performed string events. It also verifies that loading this study preserves the accepted instrument definitions and motion function. Python independently checks all 70 score voicings, their frets, actual slash bass notes, chord membership, rhythmic signatures and the movement totals.

Twelve diagnostic chords route each string to its own stereo output. Autocorrelation checks 52 separately audible string pitches against equal-tempered targets; the largest deviation is 11.864 cents, within the 18-cent diagnostic tolerance. These checks identify the played notes and bass register. They do not establish exact intonation: stiff-string partials and finite-window autocorrelation can bias that estimate. Unplayed diagnostic string channels are also checked for silence.

All nine WAVs pass 48 kHz, stereo, 24-bit PCM, duration, activity, finite-value, headroom and quiet-edge checks. Four listening studies use a constant gain to reach −23 dBFS whole-file RMS, with a peak cap. The concatenated preview preserves those gains; sections within each study are not independently normalized.

Human listening remains pending. Review whether the inversions feel connected, whether Aadd9 and A9 are distinct enough, whether the bass movement is clear, and whether the four accompaniment patterns have useful space. Promotion to the Rock channel is a separate listening decision. The accepted reference, previous phrasing studies and picking-hand studies remain unchanged.
