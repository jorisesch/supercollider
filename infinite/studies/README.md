# 32-bar listening studies

Original, composed SuperCollider pieces for choosing the musical direction of the infinite DJ. The first five explore melodic house and EDM; a sixth explores chill disco and funk. Each has a recurring hook, coordinated bass/drums, chord voicings, a breakdown and a return. They use individually written musical material; they do not call the random DJ planner or an external music-generation service.

Each is 32 bars in 4/4, approximately one minute of music, with a 100 ms lead-in and six seconds for release and effects tails. AAC previews are convenient listening copies; WAVs are stereo 48 kHz / 24-bit masters.

## New: Coastal Pocket

[Listen](../../audio/study-06-coastal-pocket-v1.m4a) · [WAV](../../audio/study-06-coastal-pocket-v1.wav) · [Source and commands](revisions/disco-v1/README.md)

A separate **120 BPM chill-disco/funk study** for the Dafunk Lounge direction: a recurring syncopated bass hook, warm electric keys, damped guitar-like chord chops, light swing and a small mid-register melody. Am9–Dm9–G13–Cmaj9, with a short breakdown and a fuller return. It uses new synthesis and musical material and retains all earlier candidates. The reference's published description informed the genre; its audio has not been analysed. Human review of this study is pending.

## Listening notes and revisions

The first human review is saved in the [listening notebook](NOTES.md). The opening of #1 worked, but the bright, high melodic entrance disrupted studies 1–4. #2 was described as decent; #4 was below #2/#3; #5 was described as “quite nice” and is retained unchanged. These are the listener's judgments, separate from numerical checks.

**v2 studies 1–4** test a softer lead one octave lower and quieter, lower bell ornaments. Phrases and rhythm are retained, along with drums, bass, chords, and arrangement. The first seven seconds of each revised WAV match its original exactly. The user's collective response was “Decent”; no further per-track ranking was supplied.

| # | Warmer v2 preview | Full WAV |
| --- | --- | --- |
| 1 | [Afterglow v2](../../audio/study-01-afterglow-v2.m4a) | [WAV](../../audio/study-01-afterglow-v2.wav) |
| 2 | [Glassline v2](../../audio/study-02-glassline-v2.m4a) | [WAV](../../audio/study-02-glassline-v2.wav) |
| 3 | [Night Circuit v2](../../audio/study-03-night-circuit-v2.m4a) | [WAV](../../audio/study-03-night-circuit-v2.wav) |
| 4 | [Sun Room v2](../../audio/study-04-sun-room-v2.m4a) | [WAV](../../audio/study-04-sun-room-v2.wav) |

## Original v1 recordings

The originals below remain untouched. Source snapshots, render settings, seeds, and recording checksums are stored under [`revisions/`](revisions/). See [the reproduction instructions](NOTES.md#reproduction-and-preservation).

| # | Track | Direction | BPM / key | Listen | Full WAV |
| --- | --- | --- | --- | --- | --- |
| 1 | Afterglow | Warm melodic house; bell/pluck hook and rounded bass | 124 / A minor | [Preview](../../audio/study-01-afterglow.m4a) | [WAV](../../audio/study-01-afterglow.wav) |
| 2 | Glassline | Bright progressive; syncopated pluck and longer chord holds | 128 / D minor | [Preview](../../audio/study-02-glassline.m4a) | [WAV](../../audio/study-02-glassline.wav) |
| 3 | Night Circuit | Dark rolling electro; dry stabs, reese-like bass, and rim percussion | 130 / F# minor | [Preview](../../audio/study-03-night-circuit.m4a) | [WAV](../../audio/study-03-night-circuit.wav) |
| 4 | Sun Room | Swung garage/house; electric-piano hook and broken kick pattern | 120 / C major | [Preview](../../audio/study-04-sun-room.m4a) | [WAV](../../audio/study-04-sun-room.wav) |
| 5 | Wide Horizon | Wider melodic progressive; sustained unison lead and rising arp | 126 / E minor | [Preview](../../audio/study-05-wide-horizon.m4a) | [WAV](../../audio/study-05-wide-horizon.wav) |

## What to listen for

Rate **groove**, **hook**, and **sound** separately. The best bass/drum combination may belong to a different study from the best melody. Note anything tiring, too thin, too busy, too soft, or too familiar. Also note whether you want to replay it.

The full theme starts around bar 9 for studies 1, 3, 4, and 5 (approximately 15–16 seconds). Glassline introduces its theme around bar 5 (8 seconds). Each has a four-bar break starting at bar 17 (30–32 seconds); the main return starts at bar 25 (44–48 seconds). Sun Room uses a rhythmic turnaround in place of the noise-led buildup of the other studies. The final bar returns to the tonic.

These are candidates for human evaluation. Numerical checks establish that the files rendered correctly; they do not establish which music is good.

## Editable source

- [tracks.scd](tracks.scd): five explicit melodies, bass phrases, chord voicings, section plans, accents, and arrangements. Hook events are `[beat, MIDI note, duration in beats]` within a four-bar phrase.
- [instruments.scd](instruments.scd): synthesis and the shared mix chain. Loading it starts no playback.
- [render.scd](render.scd): standalone offline batch renderer, with no sample or plugin dependencies.
- [live.scd](live.scd): IDE playback and graceful stop.
- [manifest.json](manifest.json): track metadata and expected render lengths.

From the repository directory, reproduce all five originals into a separate folder, or render the four v2 candidates:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/studies/revisions/v1/render.scd
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/studies/revisions/v2/render.scd
python3 verify_audio.py
python3 infinite/studies/previews.py v2
python3 infinite/studies/check_revisions.py
```

For just one revised WAV, append its number, for example `sclang -D infinite/studies/revisions/v2/render.scd 3`. The v1 renderer accepts 1–5 and writes `audio/recreated-v1/`; v2 accepts 1–4 and writes distinct `-v2.wav` files in `audio/`. To encode reconstruction previews without replacing original AACs, use `python3 infinite/studies/previews.py v1`. The batch process exits after rendering. Substitute your local sclang executable path where needed. AAC previews use macOS `afconvert`; WAV playback does not require that preview step.

To play original editable source, open and evaluate all of `live.scd`. For v2, use [`revisions/v2/live.scd`](revisions/v2/live.scd) instead. Then evaluate individual lines:

```supercollider
~studyPlay.value(1); // 1 through 5
~studyMaster.set(\wet, 0.12, \delay, 0.10); // explore the live mix
~studyStop.value; // one-second fade; frees only this study's resources
```

Live playback is finite and includes the effect tail. An explicit server can be passed as a second argument to `~studyPlay`; the default is `s`.

## Verification

All five WAVs rendered through SuperCollider with exit code 0. The renderer validates note timing and key membership. `verify_audio.py` checks PCM format, exact 32-bar duration plus tail, non-silence in every bar, headroom, and quiet starts/endings. It records overall and four-bar RMS values in [`audio/verification.json`](../../audio/verification.json). The common mix chain keeps the five active-music RMS levels within approximately 1.1 dB; this is an RMS comparison rather than perceptual loudness normalization.

The original live source was also exercised with output muted. Human review of the original and warmer v2 studies is recorded in [NOTES.md](NOTES.md); Coastal Pocket's review is pending. The existing infinite generators are unchanged by these studies.
