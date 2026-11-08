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
