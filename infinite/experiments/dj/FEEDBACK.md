# Listening feedback

EDM compression verdict (2026-11-12): **D · Stronger** for both E Aeolian / Brass Circuit and G Ionian / Wired House. Strong compression is now selected for both EDM and Pop. [EDM comparison and settings](edm-compression/README.md).

Pop's strong compression comparison was selected on 2026-11-11 and is now the default Pop master processing. The [compression study](pop-compression/README.md) records the comparison and settings.

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

## Listening round 03

Human listening decisions on 2026-11-12 approved eight of eighteen candidates.

| ID | Song | Decision |
| --- | --- | --- |
| A | Copper Teeth | Approved for London Dubstep |
| B | Sodium Bloom | Approved |
| C | Redline Ritual | Passed. Too fast |
| D | Robot Orchard | Passed |
| E | Chrome Shuffle | Passed. Clanging timbre sounds experimental |
| F | Magnet Rooms | Passed. Clanging timbre sounds experimental |
| G | Sidewinder | Passed. Clanging timbre sounds experimental |
| H | Paper Tigers | Passed. Clanging timbre sounds experimental |
| I | Low Orbit | Passed. Possible Pop direction with a different timbre |
| J | Violet Engine | Approved. “Banger!!!!” Refine the melody, possibly its tonality |
| K | Horizon Wire | Approved. “Banger” |
| L | Last Train Sun | Approved. Refine melody timing |
| M | Velvet Satellites | Passed |
| N | Borrowed Summer | Passed |
| O | Neon Postcards | Passed |
| P | Concrete Radio | Approved |
| Q | Dust on the Dial | Approved |
| R | Exit Ramp Gold | Approved |

Exact votes, comments and the heard recipe snapshots are saved in
`audio/listening-round/03/round-03-feedback.json`. The source recipes are in
[song-audition-03.scd](song-audition-03.scd). A's channel assignment is London
Dubstep. J's tonality and L's timing remain listening refinement requests.

Render and package the round from the repository root.

```sh
mkdir -p audio/listening-round/03
/Applications/SuperCollider.app/Contents/MacOS/sclang -D \
  infinite/experiments/dj/song-audition-02.scd \
  "$PWD/audio/listening-round/03" "$PWD/infinite/experiments/dj/song-audition-03.scd"
python3 infinite/experiments/dj/package-audition.py audio/listening-round/03 03
```

## Listening round 04 — connected melodies

On 2026-11-14, the listener described the drums and bass as fairly decent, but the melody as disjointed. The exact live track or layer was not identified. Five new fixed compositions test one main lead, stable repeating themes, small pitch movements and chord-tone phrase endings, with the approved strong compression. They are prototypes pending human listening review; the live melody generator is unchanged.

| ID | Song | Direction |
| --- | --- | --- |
| A | Neon Gravity | Warm E minor pop-house / brass hook |
| B | Violet Afterburn | F# minor trance / rounded pulse lead |
| C | Night Signal | A Dorian acid / low answering melody |
| D | Silver Motion | D minor synth-pop / one singing lead |
| E | Horizon Lights | D Dorian trance / lowered Anthem register |

Open `audio/listening-round/04/listen.html` to rate the one-minute excerpts. Each starts with drums, adds bass after four bars, and introduces its main melody around 14–15 seconds. The hook returns around 42–46 seconds. [Composition details and render commands](melodic-round/README.md).

### Neon Gravity — backing approved, lead rejected

The listener “absolutely love[s] Neon Gravity EXCEPT the melody,” describing its sound as “a wet fart meets nails screeching on a blackboard.” Preserve the drums, bass and arrangement; the original brass lead is rejected. [Three clean lead replacements and a no-lead reference](melodic-round/neon-leads/README.md) retain the same melody notes and timing so the instrument tone can be judged separately. Their listening page is `audio/listening-round/04-neon/listen.html`.

### Round 04 decisions

Human listening decisions on 2026-11-14 approved all five backings and rejected every lead.

| ID | Song | Decision |
| --- | --- | --- |
| A | Neon Gravity | Approved backing. Lead “overwhelming”; moved from EDM to Pop |
| B | Violet Afterburn | Approved backing. Drop the melody unless it can be improved |
| C | Night Signal | Approved backing. Drop the melody unless it can be improved |
| D | Silver Motion | Approved as Pop. Drop the melody unless it can be improved |
| E | Horizon Lights | Approved backing. Drop the melody unless it can be improved |

The working versions are now instrumental: drums, bass and chord bed, with the lead dropped at score export and all other events unchanged. Neon Gravity's channel is Pop; Pop and EDM share the same deck and strong master, so the sound is unchanged. A melody returns only if a replacement is approved in listening; the Neon lead study above is the remaining test of that. Each song is now a style in the live rotation: Violet Afterburn, Night Signal and Horizon Lights on EDM, Neon Gravity and Silver Motion on Pop. A style is an ensemble like the existing ones. It keeps its kick and bass patterns, bass voice, kit and close chord bed, and the engine generates everything else: key, mode, chord progression, form, tempo, effects and track name. Styles rotate with the other ensembles, so about three in seven EDM songs and one in three Pop songs use one. The grammar is in [song-styles.scd](song-styles.scd); the offline render plays the approved arrangement through the same grammar. The live melody generator is still unchanged. Exact comments and heard recipes are saved in `audio/listening-round/04/round-04-feedback.json`.

```sh
mkdir -p audio/listening-round/04-instrumental
/Applications/SuperCollider.app/Contents/MacOS/sclang -D \
  infinite/experiments/dj/melodic-round/render.scd "$PWD/audio/listening-round/04-instrumental" instrumental
python3 infinite/experiments/dj/package-audition.py audio/listening-round/04-instrumental 04-instrumental
```

### Round 04-neon decisions

Human listening decisions on 2026-11-14 on the Neon Gravity lead tones.

| ID | Version | Decision |
| --- | --- | --- |
| A | Rounded lead | Passed |
| B | Soft keys | Approved. “Great!” |
| C | Clean pluck | Approved. “Also great!” |
| D | No lead | Approved. Occasionally play the song without a lead |

The study page still showed EDM because it was rendered before the Pop reclassification; Neon Gravity is a Pop style. The live Neon Gravity style now plays its melody with soft keys or clean pluck, and roughly one song in five plays without a lead. The melody is the approved four-bar cell set, landing on the generated chords. Round 04-leads later approved the same leads for the other four styles. Exact comments and heard recipes are in `audio/listening-round/04-neon/round-04-neon-feedback.json`.


### Round 04-leads — Neon leads on the other styles

Soft keys and clean pluck, approved for Neon Gravity, are now auditioned on Violet Afterburn, Night Signal, Silver Motion and Horizon Lights with each song's approved notes and backing. [Versions and render commands](melodic-round/style-leads/README.md). The listening page is `audio/listening-round/04-leads/listen.html`.

Human listening decisions on 2026-11-14 approved all eight. Night Signal with soft keys (C) “can also work w.o. groove.”

| ID | Version | Decision |
| --- | --- | --- |
| A | Violet Afterburn / soft keys | Approved |
| B | Violet Afterburn / clean pluck | Approved |
| C | Night Signal / soft keys | Approved. Can also work without the groove |
| D | Night Signal / clean pluck | Approved |
| E | Silver Motion / soft keys | Approved |
| F | Silver Motion / clean pluck | Approved |
| G | Horizon Lights / soft keys | Approved |
| H | Horizon Lights / clean pluck | Approved |

Every live style now plays its melody cells on soft keys or clean pluck, and roughly one song in five plays without a lead. When a style moves to a key whose lead would sink below the lead register, the whole melody moves up instead of down. Night Signal songs with soft keys drop drums and bass in their breakdowns, leaving the full melody over the chord bed. Exact comments and heard recipes are in `audio/listening-round/04-leads/round-04-leads-feedback.json`.

### Round 05-rock — guitar tone and playing (2026-11-15)

All six clips approved: Rook today (A), cleaner amp (B), sparser ringing chords (C, "Almost a humbucker :)"), both (D, "nice bend at the end of the solo"), June (E) and Flint (F, "Nice!!!!!"). The earlier "guitar isn't great" did not single out a tone or a player, so no variant replaces the current Rock sound yet. The listener asked which other expressions are modeled; hammer-ons and pull-offs are not. [Round notes](round-05/README.md).

### Round 05-form — builds, hooks and form (2026-11-15)

All four Violet Afterburn arrangements approved ("The EDM tracks are all good. Allow variations like that in the infinite DJ stream"): the reference, the bigger build, the hook payoff, and the breakdown with a double drop. Every EDM and Pop song style now takes one of four forms for its whole length (`~djSongStyleForms`): classic, big build, hook payoff, or breakdown and double drop. The form name shows after the lead name in the desktop window. Noise risers are left out of MIDI exports.

### Round 05-legato — hammer-ons and pull-offs (2026-11-15)

All five clips approved ("Guitar hammer ons and pull offs are all good"). Rook, June and Flint now play half of their eligible lead notes as hammer-ons or pull-offs in the live Rock channel (`legatoChance:0.5`). June's and Flint's phrases mostly rise between close notes, so they hammer on far more than they pull off. [Round notes](round-05/README.md).

### Round 05-fx — wah, overdrive boost, tremolo and echo (2026-11-15)

| ID | Version | Decision |
| --- | --- | --- |
| B | Rook, wah on the solos | Approved |
| C | Rook, overdrive boost on the solos | Rejected. "Not that noticeable" |
| D | Rook, wah, boost and echo on the solos | Approved. "Align delay better with the quarter or eight notes" |
| E | Rook, slapback echo | Approved |
| F | June, tremolo | Approved |
| G | June, dotted-eighth echo | Approved |
| H | Flint, wah and boost on the solos | Approved. "Gorgeous!!" |

Each live Rock song now takes one approved pedalboard for its whole length, or none. D's echo moved from a dotted eighth to eighth notes. The boost is used only together with the wah. [Round notes](round-05/README.md).
