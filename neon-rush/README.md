# Neon Rush

An original 138 BPM trance / Eurodance instrumental with bright saw leads, offbeat bass, a breakdown and a final return. The 48-bar arrangement lasts about 88 seconds including the effect tail.

Evaluate [live.scd](live.scd) in SuperCollider to play it; the file includes level and stop commands. Edit [track.scd](track.scd) for the arrangement and [instruments.scd](instruments.scd) for synthesis. Loading the instruments alone does not start playback.

From the repository root, run:

```sh
sclang -D neon-rush/render.scd
python3 scripts/verify_audio.py
```

This generates `audio/neon-rush.wav` and updates the numerical checks. The WAV remains local and is excluded from Git. Numerical verification passed; the preview also received a positive human listening review in the session.
