# Rock player previews

[Listen to the set](../../../../audio/rock-player-set.m4a) · [Compare Rook, June and Flint](../../../../audio/rock-player-comparison.m4a)

The comparison starts Rook at 0:00, June at 0:23 and Flint at 0:46. Each plays a four-bar solo and four bars of backing in the same key at 102 BPM. The longer set follows the normal Rock arrangement and an automatic handover. Read the [player guide](../PLAYERS.md) for their playing habits and the limits on variation.

From the repository folder:

```sh
sclang -D infinite/experiments/dj/guitar-players/render.scd
python3 infinite/experiments/dj/guitar-players/package.py
python3 scripts/verify_audio.py
```

Rendering writes two WAVs in `audio/` and their timelines here, then exits. Play the WAVs in your audio player and stop them there. WAVs and temporary SuperCollider scores are ignored by Git. On macOS, create the public listening copies with:

```sh
for name in rock-player-set rock-player-comparison; do
  afconvert -f m4af -d aac -b 192000 -q 127 "audio/$name.wav" "audio/$name.m4a"
done
```

The [manifest](manifest.json) contains durations and comparison timestamps. The set and comparison timelines include the guitarist and pedal for each deck, allowing the audio verifier to check that a song keeps its identity. [Reproduction record](reproduction.json). Numerical verification and human listening review are separate; listening review is pending.
