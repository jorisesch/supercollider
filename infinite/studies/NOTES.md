# Listening notebook

Keep listening judgments separate from numerical verification. Never replace an auditioned recording when making a new candidate: use a new revision ID and retain its source, metadata, and audio references.

## 2026-10-31 — first review, original v1 studies

These observations are the user's human listening feedback. No numerical rating or overall ranking was supplied.

| # | Recording | Listener feedback | Preserve | Next experiment |
| --- | --- | --- | --- | --- |
| 1 | Afterglow | Started great. The part entering around 7–8 seconds was disruptive: too high-pitched, almost like a different genre. | The opening groove. | Try a lower, darker melodic voice with a softer attack. |
| 2 | Glassline | Decent, with a bit of the same problem as #1. | Keep the candidate in contention and preserve its musical material. | Apply the warmer lead treatment without rewriting the groove or phrase. |
| 3 | Night Circuit | Same problem as #1. The comment on #4 places #3 above #4, without giving a broader ranking. | Keep the rolling groove as a comparison. | Soften/lower the lead; avoid adding treble bite. |
| 4 | Sun Room | Same problem as #1; not as good as #2 or #3. | Keep the original for reference. | Lower-priority test of the same lead treatment; do not assume the groove is a favorite. |
| 5 | Wide Horizon | “Quite nice.” No further reason was specified. | Keep the whole recording unchanged as a promising reference. | No change in this round. |

Working hypothesis: the melodic voice's register, attack, and its relationship to the backing are causing the disruption. This is a source-based interpretation to test, not a further listening judgment. The user suggested changing the synth or UGen associated with the harp-like sound.

## Source diagnosis

- **#1:** the first high lead is `studyBell`, scheduled at approximately **7.84 seconds**. Its FM-like sine modulation and percussive envelope can give it a bell/harp character. The separate bell arpeggio enters later, around 15.6 seconds, so replacing only the arp would miss the first reported entrance.
- **#2:** `studyPluck` enters at approximately **7.60 seconds**, with a high VarSaw-based hook.
- **#3:** the first sparse `studyStab` hook enters at approximately **7.48 seconds**, using pulse/saw harmonics.
- **#4:** the primary `studyKeys` melody enters around **16.4 seconds**; keyboard chords are present earlier. The user did not provide an entrance time for this sample. Do not assign #1's exact timing to #4.
- **#5:** `studyWide` uses a sustained, wider lead. Its exact reason for working better is still unconfirmed; preserve the reference before drawing conclusions.

Times are approximate scheduled onsets; the output limiter adds a small lookahead delay.

## v2 — warmer melodic role in studies 1–4

Human review: the user described the revised set as **“Decent”** before asking about the Groovix / Da Funk direction. No further individual-track judgments or ranking were supplied.

Changes are confined to melodic roles:

- The main hook, tease, buildup pickup, and closing melody move down one octave, preserving pitch classes, contour, onsets, durations, and rests.
- `studyWarmLead` replaces the bright primary voice. A 40 ms attack, short release, gentle low-pass filtering, and fundamental-rich waveforms soften the struck-string/bell impression. Its four family settings retain some individual character.
- Main lead amplitude is 90% of v1. Bell ornaments become `studyWarmAccent`, one octave lower at 65% of their original amplitude, with a soft attack and shorter tail.
- Drums, bass, chord voicings, tempo, arrangement, swing, and the master effects chain remain unchanged. Sun Room's chord-keyboard bed is retained; its tagged melodic lead is revised.
- #5 remains the original v1 recording. There is no v2 render for #5.

This tests a combination of register, timbre, envelope, and balance changes. An improvement would not yet tell us which one mattered most.

| # | Original | Warmer v2 |
| --- | --- | --- |
| 1 | [Afterglow v1](../../audio/study-01-afterglow.m4a) | [Afterglow v2](../../audio/study-01-afterglow-v2.m4a) |
| 2 | [Glassline v1](../../audio/study-02-glassline.m4a) | [Glassline v2](../../audio/study-02-glassline-v2.m4a) |
| 3 | [Night Circuit v1](../../audio/study-03-night-circuit.m4a) | [Night Circuit v2](../../audio/study-03-night-circuit-v2.m4a) |
| 4 | [Sun Room v1](../../audio/study-04-sun-room.m4a) | [Sun Room v2](../../audio/study-04-sun-room-v2.m4a) |
| 5 | [Wide Horizon v1 — unchanged reference](../../audio/study-05-wide-horizon.m4a) | — |

## Reproduction and preservation

- [v1 source snapshot](revisions/v1/) contains the original instrument definitions, composition, live controls, and manifest. Its [reproduction record](revisions/v1/reproduction.json) stores source, WAV, PCM, and preview SHA-256 checksums, SuperCollider version, and render settings.
- [v2 source snapshot](revisions/v2/) contains the revised instruments/composition and its own manifest and renderer. It writes distinct `-v2.wav` filenames locally; WAV output is ignored by Git.
- Every render is deterministic: 32 bars in 4/4, fixed tempo per track, stereo 48 kHz / 24-bit, a 100 ms lead-in, and a six-second tail. Per-event noise seeds are `31000 + family*1000 + event ordinal`.
- AAC previews are retained publicly. Original and revised WAV renders are local-only; the archival v1 renderer writes to `audio/recreated-v1/` so reproducing a study does not replace the version the user heard.

From the repository directory:

```sh
# Recreate v1 in a separate folder; append 1..5 to choose one.
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/studies/revisions/v1/render.scd

# Render the four revised candidates; append 1..4 to choose one.
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/studies/revisions/v2/render.scd
python3 scripts/verify_audio.py
python3 infinite/studies/previews.py v2
python3 infinite/studies/check_revisions.py
```

A reproduction trial of Afterglow v1 from its saved snapshot produced PCM identical to the original across the full recording, not only its opening. This result is recorded in `revisions/v1/reproduction.json`.

Use the same SuperCollider version and render settings for PCM comparisons. The saved recordings remain the exact listening references across platforms and software versions. The legacy `patches/render.scd` still targets the original filenames; use the versioned commands above to preserve them.

When local WAV renders are present, the revision check verifies original recording/source checksums and confirms that each v2 opening's first seven seconds is byte-identical to v1. Public numerical verification is limited to committed previews and is separate from the user's listening review.


## 2026-10-31 — reference direction: Groovix / Da Funk

The user asked what would approximate the Groovix or Da Funk music they hear on YouTube. This is a new reference enquiry, not a rating of the warmer v2 recordings.

Groovix's [own public description](https://www.patreon.com/GroovixDisco/posts/welcome-to-167912285) identifies disco, funky grooves, house, and DJ sessions, with French-house/French-touch tags. That supports exploring French touch, disco house, and nu-disco. This identification is based on published descriptions, not direct audition of a specific reference video.

The “Da Funk” identity was initially unresolved. The user subsequently supplied the video confirmed below as Dafunk Lounge. Do not substitute the Daft Punk song or the Swiss producer with the same name.

Proposed musical experiment, pending the precise reference: approximately 120–122 BPM; a repeating, syncopated, bass-guitar-like phrase; warm electric-piano seventh/ninth chords; muted guitar/chord chops; firm house drums with lightly swung percussion; and slow filtering/saturation. Build the hook from the bass and chord rhythm, with a short mid-register response. Use gradual filter openings and changes in texture for the arrangement.

A possible original harmonic starting point is Am9–Dm9–G13–Cmaj9. This is a proposed recipe, not a transcription or a claim about a reference track. Sample-based or physically modelled guitar/bass articulation is worth comparing with the existing oscillator instruments. No new audio or changes to the preserved studies were made for this enquiry.


## 2026-10-31 — confirmed reference: Dafunk Lounge

User reference: [YouTube video io0zvMJf8aA](https://www.youtube.com/watch?v=io0zvMJf8aA).

YouTube's oEmbed metadata identifies the channel as **Dafunk Lounge** and the title as **Daft Punk Inspired Chill Disco 🎸 Coastal Blue Hour & Smooth Riviera Grooves | Dafunk Lounge**. The public uploader description identifies relaxed disco, French Touch, warm bass and polished synthesizers. It describes a fan-made tribute, so this reference should not be labelled as an official Daft Punk recording.

The uploader's tracklist identifies the opening piece as **Clear Signal**, beginning at 00:01, followed by **Low Tide** at 03:14. The opening piece is a useful provisional reference for the next study; the user has not specified a preferred timestamp within the mix.

Analysis scope: channel, title and public description were inspected. The audio itself has not been auditioned or analysed here. Exact BPM, chord changes, instrumentation and mix characteristics remain unverified.

Working musical direction for a new original study: chill disco / French-touch-influenced funk, starting around 120 BPM as a design choice rather than a measured tempo. Prioritize a repeating syncopated bass phrase, warm seventh/ninth chord comping, muted guitar-like chops, restrained house percussion and a small mid-register answering motif. Explore slow filtering and selective layer changes for movement. Preserve all previous samples and their feedback as separate references.

## 2026-10-31 — Coastal Pocket, disco v1

User request: “Create a da dunk style track to explore.” Interpreted in the context of the supplied Dafunk Lounge video. This is a new original study, not a transcription of the reference. Subsequent human feedback: **“Not quite there…”**. The user then returned to improving the infinite DJ, describing its songs as too sterile and favoring the original generator as a reference. No detailed per-instrument judgment or rating of Coastal Pocket was supplied.

- Recording: [Coastal Pocket preview](../../audio/study-06-coastal-pocket-v1.m4a); render the WAV locally from the revision source when needed.
- Source and reproduction: [`revisions/disco-v1/`](revisions/disco-v1/README.md). ID `study-06-coastal-pocket-v1`; event seeds start at 62000. All previous recordings and source snapshots remain separate.
- Composition: 120 BPM, 32 bars, 4/4; Am9–Dm9–G13–Cmaj9, two bars per chord. A written two-bar bass rhythm repeats over the harmony. Melody and chord comping are explicit, not independent note randomization.
- Sound hypothesis: a fixed-pitch, fundamental-rich bass should avoid EDM B's reported rubber-band snap. Short damped string-resonator chops and warm keys may bring the accompaniment closer to disco/funk. This is a proposed improvement to evaluate, not a listening finding.
- Melody stays at MIDI 53–67 (F3–G4), with a soft reed/organ-like voice, modest level and a repeated eight-bar phrase. This follows the earlier concern about high, disconnected harp-like entrances.
- Structure: sparse opening, fuller groove, melody from bar 9 (~16 seconds), a two-bar kick withdrawal at bar 17 (~32 seconds), gradual brightening from bar 21 (~40 seconds), full return at bar 25 (~48 seconds), and a C-major ending. No large noise riser or new high-register arp is introduced.
- Evaluation focus: whether the bass/chord rhythm invites movement; whether the melody feels part of the same track; whether the return adds enough energy. Numerical checks cannot answer those questions.
- Verification: SuperCollider completed successfully; `scripts/verify_audio.py` passed (70.1013 seconds, peak −2.03 dBFS, active-music RMS −17.48 dBFS, quiet boundaries, all bars active). Muted start/stop/restart and accelerated natural completion passed. The original-five preservation check passed. This records numerical/runtime evidence, not a listening judgment.
