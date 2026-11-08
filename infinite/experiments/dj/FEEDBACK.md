# Listening feedback

Each deck has **👍** and **👎** buttons. They rate the song on that deck, including during a handover. Buttons become available once the deck is playing. A saved choice is highlighted.

The post window confirms that a rating was saved. Clicking the same rating again leaves one opinion for that song. Changing your vote creates a new event pointing to the previous one, so later training can use the latest vote.

Files live in `infinite/experiments/dj/feedback/`, which Git ignores. Copy that folder to export your ratings. Votes collect examples for later training. The generator’s choices continue independently of them.

Each JSON file contains:

- The rating, UTC timestamp, session and event identifiers, and any superseded event.
- The track name, deck, channel, session seed and source fingerprint.
- The complete starting recipe and command history up to the heard bar.
- The song’s key, scale, progression, chord schedule, form, arrangement, instrument palette, EDM anthem style and Rock guitarist/pickup.
- The scheduled bar and beat, tempo, controls, current effects and both decks’ gains.
- The generated note events for that bar.

Playback captures the metadata when the bar is scheduled. The vote uses that captured song, so generating the next bar or cueing another deck cannot change its target. Feedback files contain generation data and ratings. Audio recordings can be rendered later using the matching source version and recipe.

For a training set, group by `track_id` and follow `supersedes` to the latest revision for the final label. Keep all revisions if studying how opinions change. Group related examples by the source fingerprint and session identifier when splitting data for evaluation.

The current recipe format is schema 8. Earlier track names require the generator that created them. The feedback schema is independently versioned as 1.

## Listening round 01

The eight excerpts have stable IDs A–H. A is a new G Ionian / Wired House render at 30% Energy for comparison. The other excerpts try different rhythms, tempos, forms and palettes across EDM, Pop and Rock.

From the repository root, render the WAVs and their recipe JSON files with the audition score. The score takes an existing output directory as its argument.

```sh
mkdir -p audio/listening-round
/Applications/SuperCollider.app/Contents/MacOS/sclang -D \
  infinite/experiments/dj/song-audition.scd "$PWD/audio/listening-round"
python3 infinite/experiments/dj/package-audition.py audio/listening-round
```

Open `audio/listening-round/listen.html` in a browser. Rate the excerpts and copy the summary into the chat, or export the ratings with their recipes. The round collects feedback separately from live deck ratings.

## Listening round 02

Six independent arrangements compare acid techno, industrial electro, fast breaks, minor-key trance, synth-pop and motorik guitar rock. Each establishes its rhythm and motif early, then makes space for a contrasting section and a return. These prototypes use fixed arrangement scores and local render settings.

```sh
mkdir -p audio/listening-round/02-revised
/Applications/SuperCollider.app/Contents/MacOS/sclang -D \
  infinite/experiments/dj/song-audition-02.scd "$PWD/audio/listening-round/02-revised"
python3 infinite/experiments/dj/package-audition.py audio/listening-round/02-revised 02-revised
```

Open `audio/listening-round/02-revised/listen.html`. Revised ratings have their own ballot. The shared Round 01 votes and notes are saved locally alongside their recipe snapshots in `audio/listening-round/round-01-feedback.json`.

The original Round 02 files had a scheduling error that placed the music in roughly the first quarter of each clip. The original votes and recipes are preserved in `audio/listening-round/02/round-02-feedback.json`. The revised audio has the corrected timing, a tighter C, a later lead on D and softer drums on F.

## London Dubstep timing comparison

At 140 BPM in F# Phrygian, A and B share the same acid riff, sub and hats. A uses the channel's half-step opening. B moves the kick and snare to a straight dance grid. C uses the channel's swung two-step arrangement. The recipe JSON records each bar's kick, snare and acid grid.

All three received thumbs up. C was singled out for its jazzy feel and is available as a separate audition. London Dubstep rotates among Acid Pressure, Low Signal and Acid Relay. Acid Relay takes B's straight beat into a half-step section.

```sh
mkdir -p audio/listening-round/dubstep-timing
/Applications/SuperCollider.app/Contents/MacOS/sclang -D \
  infinite/experiments/dj/dubstep-audition.scd "$PWD/audio/listening-round/dubstep-timing"
python3 infinite/experiments/dj/package-audition.py audio/listening-round/dubstep-timing 03-dubstep
```
