# Infinite DJ companion page

A buildless, responsive introduction to Infinite DJ with embedded EDM, Pop and Soundscape demos, the real control-window screenshot, technical notes and launch instructions. No frameworks, third-party fonts, tracking or browser synthesis. Players load no audio until requested, and starting one pauses the other.

## Preview

From the repository root:

```sh
python3 scripts/build_site.py
python3 -m http.server 8000 --bind 127.0.0.1
```

Open `http://127.0.0.1:8000/_site/`. Serving from the repository root also makes the fallback guide and repository links accessible. Press Ctrl+C to stop the preview server.

## GitHub Pages

Choose **Settings → Pages → Source → GitHub Actions** once in the repository. After committing and pushing these files to `main`, `.github/workflows/pages.yml` packages and publishes the site. It can also be run manually from Actions. The deployment reports the public URL; project pages normally live at `https://<owner>.github.io/<repository>/`.

The build copies only the page, two screenshots/artwork assets and three selected M4A previews into `_site/`. Its repository links are injected from GitHub's workflow context, so no account name is stored in source. Optional local equivalent: `python3 scripts/build_site.py --repository-url https://github.com/OWNER/REPOSITORY`.

Recorded demos run in the browser. The infinite generator itself requires a local SuperCollider installation. This page does not promise a browser port of the synthesis engine.

The Soundscape preview is generated from the current baseline with `sclang -D infinite/infinite-render.scd soundscape`, checked with `python3 scripts/verify_audio.py`, then encoded with `afconvert -f m4af -d aac -b 192000 audio/infinite-soundscape.wav audio/infinite-soundscape.m4a`. It is an excerpt of the separate Soundscape engine, not a two-deck DJ channel.

The players demonstrate the current EDM, Pop and Soundscape generators. The refreshed Pop preview includes contrasting verse, chorus and bridge harmony.
