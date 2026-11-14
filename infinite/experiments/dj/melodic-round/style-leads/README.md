# Round 04 styles — approved Neon leads on the other songs

Round 04-neon approved two clean lead tones for Neon Gravity: soft keys and clean pluck. These auditions try both on the other four round 04 songs. Each keeps that song's approved backing, melody notes and timing, at the lead levels approved for Neon Gravity. Only the lead tone changes.

| ID | Version |
| --- | --- |
| A | Violet Afterburn / soft keys |
| B | Violet Afterburn / clean pluck |
| C | Night Signal / soft keys |
| D | Night Signal / clean pluck |
| E | Silver Motion / soft keys |
| F | Silver Motion / clean pluck |
| G | Horizon Lights / soft keys |
| H | Horizon Lights / clean pluck |

Listening approved all eight; every live style now uses these leads. See [FEEDBACK.md](../../FEEDBACK.md#round-04-leads--neon-leads-on-the-other-styles). From the repository root on macOS:

```sh
mkdir -p audio/listening-round/04-leads
/Applications/SuperCollider.app/Contents/MacOS/sclang -D \
  infinite/experiments/dj/melodic-round/render.scd "$PWD/audio/listening-round/04-leads" leads
python3 infinite/experiments/dj/package-audition.py audio/listening-round/04-leads 04-leads
```

Open `audio/listening-round/04-leads/listen.html`. The melody enters around 14–15 seconds.
