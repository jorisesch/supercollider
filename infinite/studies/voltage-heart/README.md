# Voltage Heart

[Listen to Voltage Heart](../../../audio/voltage-heart-e-minor.m4a). A 134 BPM melodic EDM instrumental in E minor with a rising snare build, an octave lift at **0:36**, and syncopated tom fills.

## Play it in SuperCollider

Open [live.scd](live.scd) and evaluate the main block. It boots the sound server and plays the track once. Evaluate `~stopVoltageHeart.value` to fade out.

Edit [track.scd](track.scd) to change the hook or arrangement. Its `transpose` value sets the key in semitones relative to F-sharp minor. The track uses stock SuperCollider instruments with no sample packs.

## Render a WAV

From the repository root, run this on macOS:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/studies/voltage-heart/render.scd
python3 scripts/verify_audio.py
```

On Linux or Windows, use your installation's `sclang` command. The render writes `audio/voltage-heart-e-minor.wav`.
