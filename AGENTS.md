# Repository instructions

This is a public repository of SuperCollider skills, editable synthesis patches, and rendered audio.

- Prepare changes and ask the user for approval in the current session before committing. Direct commits are allowed after approval; pull requests are not required.
- Human listening review of audio happens in the session; distinguish it from numerical verification.
- Keep public files portable. Exclude credentials, personal filesystem paths, local logs, temporary scores, and unrelated artifacts.
- Read `skill/supercollider-music/SKILL.md` when composing or changing synthesis.
- Keep `instruments.scd` free of playback side effects; `live.scd` is interactive and `render.scd` is a standalone batch process that exits after rendering.
- When sound generation changes, render with SuperCollider and run `python3 verify_audio.py`. Keep the WAVs and `audio/verification.json` consistent with source.
- Update README instructions with behavioral changes. Report numerical verification separately from listening review.
