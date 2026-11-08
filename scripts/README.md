# Verification tools

The current Infinite DJ generator uses `variety-check.scd` for seeds, modes, forms, current recipes and passive feedback persistence. Run `channels-check.scd` for CLI flags and fresh launch seeds, and `variety-runtime-check.scd` for the actual rating buttons, deck targeting and mode changes. These paths live under `infinite/experiments/dj/`.

Render `variety-render.scd` for six current song excerpts, then run `python3 scripts/verify_audio.py`. Its timing and generation details are in `variety-preview.json`. The older study checks below include frozen first-song and recipe assertions for their original generator versions.


Run `python3 scripts/verify_audio.py` from the repository root after rendering. The script also accepts invocation by full path from another directory: it resolves audio and manifests against the repository automatically.

It checks available WAVs for sample format, duration, finite non-silent samples, peak headroom and quiet endings. Additional checks cover Quindar frequencies and available DJ timeline manifests. EDM E manifests also require its chord, percussion, signature and slide events, both A/B groove variants, and bounded pullbacks; the comparison reports levels for each component pass. Results are written to `audio/verification.json`. Required Quindar WAVs can be generated with `sclang -D patches/render.scd`.

These numerical checks do not replace human listening review.

## Companion page

`python3 scripts/build_site.py` packages the browser player, artwork, SuperCollider sources and WebAssembly runtime into ignored `_site/`. See [site/README.md](../site/README.md) for local playback and GitHub Pages deployment.

The Pop preview also checks its rendered timeline for contrasting verse/chorus/bridge progressions and one-bar chord changes.

Rock backing-track previews are checked against `infinite/studies/rock/manifest.json` for format, 32-bar duration, activity, tonic-ending onset and quiet tails. Their SuperCollider composition check separately validates pitch membership in the advertised pentatonic or modal scale.

`python3 scripts/verify_rock_fx.py` compares the rock effect and `nofx` renders: clean openings must be PCM-identical, and later effect passages must differ measurably. Mode-comparison WAVs are checked using `infinite/experiments/dj/modes-tour.json`.

Rock channel renders use `infinite/experiments/dj/rock-preview.json` and `rock-tones.json`, including the slower tempo range, automatic handover and ensemble comparison. `rock-check.scd` and `channels-runtime-check.scd` cover composition and live controls separately.

`python3 scripts/verify_rock_guitar.py` checks the temporary waveforms exported by `infinite/experiments/dj/rock-guitar-signal-check.scd`: audible slides/bends/vibrato, stable final pitch, guitar compression and isolated bass/drum routing.

For the current physical guitar, render `infinite/experiments/dj/rock-physical-render.scd`, then run `python3 scripts/verify_rock_physical.py`. It checks waveform pitch, tension/fret behavior, the diode circuit against an independent solver, antialiasing, chord interaction, compression and guitar-only routing. The one-minute public study is also included in `verify_audio.py`. [Listening guide and research](../infinite/experiments/dj/GUITAR.md).

The separate [guitar phrasing prototypes](../infinite/experiments/dj/guitar-prototypes/README.md) explore variable vibrato timing, partial bends, overshoots and releases. Their render/package commands are listed there. `python3 scripts/verify_guitar_prototypes.py` checks actual waveform pitch, intended intonation, onset diversity, body equivalence and comparable listening levels. `verify_audio.py` also includes their four clips and combined comparison when present.

The [picking-hand studies](../infinite/experiments/dj/guitar-contact/README.md) add timed strums, pick/finger contact and double stops. After rendering and packaging, `python3 scripts/verify_guitar_contact.py` measures separate string onsets, release-dependent spectra, a held partner's pitch during a bend and the matched listening pass. `guitar-contact/check.scd` checks force equilibrium, bounded contact states, playable string assignments and preservation of accepted instrument graphs. The general audio verifier includes these studies when their manifest is present.

The [guitar harmony studies](../infinite/experiments/dj/guitar-harmony/README.md) compare triad inversions, sevenths/ninths, slash chords and four accompaniment patterns. `guitar-harmony/check.scd` checks the SuperCollider score and unchanged accepted instruments. After rendering and packaging, `python3 scripts/verify_guitar_harmony.py` independently checks chord spelling, fret assignments, actual bass notes, voice movement, performed timing and 52 dry string pitches. The general audio verifier also includes the nine available study/source WAVs when their manifest is present. Neither script substitutes for listening review.

[Rock guitarist characters](../infinite/experiments/dj/PLAYERS.md) limit variation within each song. `rock-players-check.scd` checks stable profiles, repeated patterns, personal gesture/rig bounds, chord endings, unchanged bass/drum events and saved-track compatibility. The general audio verifier includes the new set/tour WAVs and their per-song guitarist/pedal timelines. `channels-runtime-check.scd` checks the native player labels alongside live channel/effect behavior with hardware output muted.

The [humbucker study](../infinite/experiments/dj/guitar-pickups/README.md) has its own `verify.py`, which compares rendered circuit response and spatial harmonic ratios with independent calculations, measures ideal/mismatched hum cancellation and checks the clean/drive comparison levels. The general audio verifier also checks its three listening WAVs.
