# Repository instructions

This is a public repository of SuperCollider skills, editable synthesis patches, and rendered audio.

- All changes require pull-request review before merging. Do not push implementation changes directly to the default branch or self-merge a pull request.
- Include the skill, instruments, arrangements, and documentation in review; audio changes also require human listening review.
- Keep public files portable. Exclude credentials, personal filesystem paths, local logs, temporary scores, and unrelated artifacts.
- Read `skill/supercollider-music/SKILL.md` when composing or changing synthesis.
- Keep `instruments.scd` free of playback side effects; `live.scd` is interactive and `render.scd` is a standalone batch process that exits after rendering.
- When sound generation changes, render with SuperCollider and run `python3 verify_audio.py`. Keep the WAVs and `audio/verification.json` consistent with source.
- Update README instructions with behavioral changes. Report numerical verification separately from listening review.
