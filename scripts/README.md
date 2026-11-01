# Verification tools

Run `python3 scripts/verify_audio.py` from the repository root after rendering. The script also accepts invocation by full path from another directory: it resolves audio and manifests against the repository automatically.

It checks available WAVs for sample format, duration, finite non-silent samples, peak headroom and quiet endings. Additional checks cover Quindar frequencies and available DJ timeline manifests. Results are written to `audio/verification.json`. Required Quindar WAVs can be generated with `sclang -D patches/render.scd`.

These numerical checks do not replace human listening review.
