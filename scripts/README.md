# Verification tools

Run `python3 scripts/verify_audio.py` from the repository root after rendering. The script also accepts invocation by full path from another directory: it resolves audio and manifests against the repository automatically.

It checks available WAVs for sample format, duration, finite non-silent samples, peak headroom and quiet endings. Additional checks cover Quindar frequencies and available DJ timeline manifests. EDM E manifests also require its chord, percussion, signature and slide events, both A/B groove variants, and bounded pullbacks; the comparison reports levels for each component pass. Results are written to `audio/verification.json`. Required Quindar WAVs can be generated with `sclang -D patches/render.scd`.

These numerical checks do not replace human listening review.

## Companion page

`python3 scripts/build_site.py` packages the static listening page and selected media into ignored `_site/`. See [site/README.md](../site/README.md) for preview and GitHub Pages deployment.
