# Coastal Pocket — disco v1

An original 32-bar chill-disco / French-touch-influenced funk study, prompted by the user's [Dafunk Lounge reference](https://www.youtube.com/watch?v=io0zvMJf8aA). The reference's title and description informed the direction; its audio was not analysed. This is original musical material, with no sampled reference audio or external music model.

[Listen to the AAC preview](../../../../audio/study-06-coastal-pocket-v1.m4a) · local WAV render via `render.scd`

120 BPM, 4/4, C major / A minor. **Am9–Dm9–G13–Cmaj9**, two bars per chord. The 64 seconds of music have a 100 ms lead-in and six seconds for releases and effects.

The main hook is a written two-bar bass phrase, transposed with each chord. Its oscillator pitch stays steady; there is no pitch dive or resonant filter snap. Warm electric keys and short, strummed string-resonator chops share close seventh/ninth voicings. The answering melody stays between F3 and G4, using a soft organ/reed voice rather than the earlier bright bell/pluck timbres. Drums use accents, quiet ghost notes and 55% sixteenth swing. All synthesis uses stock UGens; the bass and guitar-like parts are synthetic approximations.

| Bars | Approximate start | Arrangement |
| --- | --- | --- |
| 1–4 | 0:00 | Bass/drums/keys; quiet, sparse chord chops |
| 5–8 | 0:08 | Fuller chops and swung shaker; two-note melody hint |
| 9–12 | 0:16 | First half of the mid-register hook |
| 13–16 | 0:24 | Answering phrase; small rim fill |
| 17–20 | 0:32 | Two bars without kick, sustained keys; groove eases back in |
| 21–24 | 0:40 | Chops gradually brighten; two-note pickup |
| 25–28 | 0:48 | Full groove and returning hook |
| 29–32 | 0:56 | Answer, reduced chops, sustained C-major ending |

From the repository directory on macOS:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/studies/revisions/disco-v1/render.scd
python3 verify_audio.py
python3 infinite/studies/previews.py disco-v1
```

The renderer is a standalone batch process that exits when finished. It writes only this study's WAV. Use a locally installed `sclang` command on other platforms; AAC preview conversion requires macOS `afconvert`. The WAV is directly playable without conversion.

For interactive playback, evaluate [live.scd](live.scd) in the SuperCollider IDE, then evaluate these lines individually:

```supercollider
~discoPlay.value; // finite 32-bar playback; call again to restart
~discoMaster.set(\brightness, 2800, \wet, 0.08); // try a darker, drier mix
~discoStop.value; // fade and release this study's resources
```

[track.scd](track.scd) holds every note, rhythm, chord voicing and section rule. [instruments.scd](instruments.scd) holds the voices and mix chain and starts no playback when loaded. [manifest.json](manifest.json) records the musical and render settings; [reproduction.json](reproduction.json) records source/audio checksums. This is a finite composition for evaluation, not yet an infinite generator.

SuperCollider rendered successfully and root `verify_audio.py` passed: 70.1013 seconds, stereo 48 kHz / 24-bit, peak −2.03 dBFS, active-music RMS −17.48 dBFS, with quiet edges and activity in all 32 bars. The renderer also checked timing, key membership and deterministic event generation. Muted live playback exercised start, stop, rapid restart, mix control and a complete arrangement at accelerated tempo with automatic cleanup. Original recordings and archived v1 source passed the preservation check.

These numerical/runtime checks do not judge the musical result. Human listening review of this new study is pending; leave feedback in the [listening notebook](../../NOTES.md).
