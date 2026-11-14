# Listening round 04 — connected melodies

Five new one-minute EDM and Pop compositions test a more recognizable melodic approach. Open `audio/listening-round/04/listen.html` after rendering and packaging, approve or pass each song, and copy the feedback into the chat.

Neon Gravity's backing received strong approval, but its original brass lead was rejected as unpleasantly raspy and screeching. [Compare cleaner lead replacements](neon-leads/README.md) over the same notes and backing.

Listening on 2026-11-14 approved all five backings and rejected all five leads: drop the melody unless it can be improved. Render the approved instrumental versions by passing `instrumental` in place of a candidate ID; output goes to `audio/listening-round/04-instrumental`. See [FEEDBACK.md](../FEEDBACK.md#round-04-decisions).

| ID | Song | Direction |
| --- | --- | --- |
| A | Neon Gravity | E minor pop-house (Pop channel); warm brass and a compact answering hook |
| B | Violet Afterburn | F# minor trance; rolling bass and a sustained, rounded pulse lead |
| C | Night Signal | A Dorian acid; a steady bass cell with a low, sparse answering melody |
| D | Silver Motion | D minor synth-pop; a singing lead over a consistent backbeat |
| E | Horizon Lights | D Dorian trance; an open melodic contour in the approved lower Anthem register |

Each excerpt starts with four drum-only bars, followed by four bars of drum and bass groove. The lead enters at bar 8 (about 14–15 seconds), repeats an eight-bar theme, leaves space, builds, and returns to the same theme. The last bar resolves to the tonic. The main lead is the melody to listen for; there is no second lead or busy upper arpeggio competing with it.

The four-bar melodic cells use fixed rhythms, modest pitch movement and chord tones at their beginnings and endings. The eight-bar harmony repeats; the hook's first seven returning bars keep exactly the same lead pitches and durations. Only the closing bar resolves differently. Pads use close, gently moving voicings. Hats and fills stay restrained, and every candidate uses the approved strong stereo-linked compression and existing kick ducking.

All five backings were approved and now play, without a lead, in the live EDM and Pop rotation. Their bar-by-bar backing lives in [fixed-songs.scd](../fixed-songs.scd), shared by this renderer and the live engines. The generated-song melody generator is unchanged.

From the repository root on macOS:

```sh
mkdir -p audio/listening-round/04
/Applications/SuperCollider.app/Contents/MacOS/sclang -D \
  infinite/experiments/dj/melodic-round/render.scd "$PWD/audio/listening-round/04"
python3 infinite/experiments/dj/package-audition.py audio/listening-round/04 04
```

Append a candidate ID, such as `B`, to the render command to render just that song. The score checks drum-only intros, chord-tone phrase endings, lead range and returning-hook identity. JSON recipes include all scheduled melody notes. The package separately verifies audio duration, peak headroom, non-silence and clean edges, then writes M4A previews and a numerical report. Human listening verdicts remain separate from those checks.
