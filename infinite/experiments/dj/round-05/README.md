# Listening round 05 — EDM form and Rock guitar

Two offline studies. The live generator does not use any of this until clips are approved.

```sh
mkdir -p audio/listening-round/05-form audio/listening-round/05-rock
sclang infinite/experiments/dj/round-05/render.scd "$PWD/audio/listening-round/05-form" form
sclang infinite/experiments/dj/round-05/render.scd "$PWD/audio/listening-round/05-rock" rock
python3 infinite/experiments/dj/package-audition.py audio/listening-round/05-form 05-form
python3 infinite/experiments/dj/package-audition.py audio/listening-round/05-rock 05-rock
```

## 05-form: builds, hooks and form on Violet Afterburn (soft keys)

| Clip | What changes |
| --- | --- |
| A | Reference: the approved round 04 arrangement, identical bar for bar. |
| B | 8-bar build: riser, snare roll from quarters to sixteenths, kick and hats leave halfway, bass leaves on the last beat, half a beat of silence, impact on the drop. |
| C | Hook payoff: the first hook plays only the first and last note of each cell. After the build the full hook returns with clean-pluck answers and offbeat chord stabs. |
| D | New form: groove with no melody, 8-bar breakdown with the melody over chords only, the 8-bar build, then a 16-bar drop whose second half adds answers and a shaker. |

The options live in `~djSongStyleBar` (`bigBuild`, `drop`, `tease`, `answer`, `stabs`, `lift`). All four clips were approved, so the live song styles now pick among them per song through `~djSongStyleForms`.

## 05-rock: guitar tone and playing

Same seed, key and 24 bars for every clip, with a solo requested at bar 12.

| Clip | What changes |
| --- | --- |
| A | Rook as he plays today. |
| B | Rook with a cleaner amp: drive at 45% and the cleaner two-stage overdrive. |
| C | Rook with sparser, ringing chords instead of constant eighth notes. |
| D | B and C together. |
| E | June as she plays today. |
| F | Flint as he plays today. |

Cleaner clips are also quieter (B, D, E measure about 3 dB below A), so judge tone rather than loudness.

## 05-legato: hammer-ons and pull-offs

```sh
mkdir -p audio/listening-round/05-legato
sclang infinite/experiments/dj/round-05/render.scd "$PWD/audio/listening-round/05-legato" legato
python3 infinite/experiments/dj/package-audition.py audio/listening-round/05-legato 05-legato
```

Same seed and 24 bars as 05-rock, with four solos requested (bars 4, 8, 14 and 18) so there are enough lead notes to compare.

| Clip | What changes | Hammer-ons / pull-offs |
| --- | --- | --- |
| A | Rook, picked and slid as today. | 0 / 0 |
| B | Rook, half of the eligible notes played legato. | 6 / 5 |
| C | Rook, every eligible note played legato. | 16 / 8 |
| D | June, half of the eligible notes. | 6 / 0 |
| E | Flint, half of the eligible notes. | 6 / 0 |

A note is eligible when it follows the previous lead note within about a sixteenth, on the same string, at most four frets away. Rising notes hammer on and falling notes pull off. The string model gives them no pick noise, a softer start, a fingertip thump (hammer-on) or a small sideways pluck (pull-off). A player uses them only when it has a `legatoChance`. All five clips were approved on 2026-11-15, so Rook, June and Flint now play half of their eligible notes legato in the live Rock channel (`rock-players.scd`).

## 05-fx: wah, overdrive boost, tremolo and delay

```
mkdir -p audio/listening-round/05-fx
sclang infinite/experiments/dj/round-05/render.scd "$PWD/audio/listening-round/05-fx" fx
python3 infinite/experiments/dj/package-audition.py audio/listening-round/05-fx 05-fx
```

Same seed, 24 bars and four requested solos as 05-legato. Rook, June and Flint already play with hammer-ons and pull-offs.

| Clip | Player | Pedals |
| --- | --- | --- |
| A | Rook | None added (today's sound). |
| B | Rook | Wah on the solos. |
| C | Rook | Overdrive boost on the solos. |
| D | Rook | Wah, boost and eighth-note echo on the solos. |
| E | Rook | Slapback echo (a sixteenth) throughout. |
| F | June | Tremolo (three dips per beat) throughout. |
| G | June | Dotted-eighth echo throughout. |
| H | Flint | Wah and boost on the solos. |

Rhythm and lead guitar share one rig, so a pedal stepped on for a solo also colours the chords played under it. Wah and boost sit ahead of the compressor and drive pedals (in the deck's input stage); tremolo follows the chorus; the echo follows the speaker. Listening on 2026-11-15 approved B and D to H (H: "Gorgeous!!") and rejected C, the boost on its own, as "not that noticeable". D's echo was first a dotted eighth; on request it now falls on eighth notes. In the live Rock channel each song takes one pedalboard for its whole length (`boards` in `rock-players.scd`): Rook plays with none, wah, wah with boost and eighth-note echo, or slapback; June with none, tremolo, or dotted-eighth echo; Flint with none, or wah and boost. Tremolo and echo exist only on the current deck, not on the older humbucker deck used by tone versions 3 to 5.

