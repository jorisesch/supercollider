# Humbucker pickup study

Listen to the [combined comparison](../../../../audio/rock-humbucker-comparison.m4a) (1:41). It plays the same notes and picking through five pickups, first [clean and level matched](../../../../audio/rock-humbucker-clean.m4a), then through [one fixed overdrive](../../../../audio/rock-humbucker-drive.m4a). The drive pass preserves how hard each pickup hits the pedal. The studio comparison uses the full pickup prototype. Rock uses its vintage series pickup in a lighter live string model.

| Pickup | Clean | Overdrive |
| --- | ---: | ---: |
| Single coil | 0:00 | 0:51 |
| Vintage humbucker, series | 0:10 | 1:01 |
| Same humbucker, parallel | 0:20 | 1:11 |
| Same humbucker, split to its bridge-side coil | 0:30 | 1:21 |
| Hot humbucker, series | 0:40 | 1:31 |

The phrase includes an Eadd9 strum, treble upstroke, short lead, a double stop and Em7. Start with **0:00 → 0:10** to hear the change in clean tone, then **1:01 → 1:31** to compare the two series pickups into the same pedal.

## Blues in Rock

[Hear two blues choruses](../../../../audio/rock-blues.m4a). The first follows a standard 12-bar blues in E with E7, A7 and B7. The second goes to A7 in bar two and brings in a solo at **0:38**. Both come from the live Rock score at 102 BPM with seed 2601.

To render the blues preview from the repository folder:

```sh
sclang -D infinite/experiments/dj/guitar-pickups/render-blues.scd
afconvert -f m4af -d aac -b 192000 -q 127 audio/rock-blues.wav audio/rock-blues.m4a
```

## Recreate the pickup comparison

From the repository folder:

```sh
sclang -D infinite/experiments/dj/guitar-pickups/render.scd
python3 infinite/experiments/dj/guitar-pickups/package.py
python3 infinite/experiments/dj/guitar-pickups/verify.py
python3 scripts/verify_audio.py
```

On macOS, the executable may be `/Applications/SuperCollider.app/Contents/MacOS/sclang`. Rendering runs offline and exits. Play the WAVs from `audio/`; stop playback in your audio player. Diagnostic WAVs stay in SuperCollider's temporary folder. To recreate the public listening copies:

```sh
for name in rock-humbucker-clean rock-humbucker-drive rock-humbucker-comparison; do
  afconvert -f m4af -d aac -b 192000 -q 127 "audio/$name.wav" "audio/$name.m4a"
done
```

## Play one chord live

In SuperCollider, with the repository as the working directory, evaluate:

```supercollider
"infinite/experiments/dj/guitar-pickups/audition.scd".load;
~hpAudition.value(1, false); // vintage series, clean
```

Use `0`–`4` for the five pickups in the table, or `true` as the second argument for overdrive. Each chord fades out on its own. Evaluate `~hpAuditionStop.value` to fade it early. The audition starts the audio server if needed and manages only its own synths and buses.

Edit geometry, wiring or load values in [model.scd](model.scd). See [research and limitations](RESEARCH.md), [preset values](presets.tsv), [performance events](events.tsv), [measured results](verification.json) and the [reproduction record](reproduction.json). The studio comparison passed the numerical checks and received a positive listening review.
