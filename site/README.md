# Infinite DJ in the browser

Choose **EDM**, **Pop**, **Soundscape**, **Rock** or **London Dubstep**, then press **Play**. **Next** starts a transition to another song or a fresh soundscape. **Energy** shapes the arrangement. Use your device’s volume controls to set the listening level.

If the browser asks for another tap after loading, press **Enable audio**. If playback was interrupted while the page was in the background, press **Resume audio**. The status line identifies startup failures. **Retry** tries a failed download again in place or restarts the player if the audio engine failed.

Pop uses the strong compression setting selected in the listening comparison, with one shared gain envelope for the stereo mix.

After a deployment, an older tab reloads once if the page, player and music bundle have different versions. It keeps the selected channel and Energy setting. A set that is already playing continues with the music sources it loaded. The WebAssembly runtime has its own version, so music updates can reuse the cached runtime.

During startup, instrument definitions are uploaded one at a time so the fixed audio runtime can finish compiling each definition before receiving the next. A fatal worker error stops startup or displays a restart prompt during playback.

During startup, the browser forwards at most one status reply per poll and pauses status replies while login and server tree setup finish. This prevents queued replies during slow or paused audio startup from triggering repeated logins and duplicate server setup. Normal status updates resume after the server boots.

EDM and Pop choose a fresh first song, key and mode each time. Both open with eight bars of drums before the full song enters, then continue with randomly generated tracks. Every later EDM and Pop song, and every Rock and London Dubstep song, starts with four rhythm-only bars before its pitched parts enter. London Dubstep also chooses its first song randomly and rotates among dry half-step, sparse rim-and-sub, and a straight kick pattern that drops back into half-step. Each set starts with a fresh seed. The browser runs the same SuperCollider sources as the desktop app using WebAssembly. [Runtime source and licenses](runtime/SOURCE.txt).

## Preview locally

Run these commands from the repository root.

```sh
python3 scripts/build_site.py
python3 -m http.server 8000 --bind 127.0.0.1
```

Open `http://127.0.0.1:8000/_site/` and press **Play**. The page may reload once while its service worker enables cross-origin isolation for WebAssembly audio. Use a current browser on HTTPS or localhost. Press Ctrl+C to stop the preview server.

## Publish

In the repository's **Settings → Pages**, set **Source** to **GitHub Actions**. The Pages workflow packages the player, background artwork, SuperCollider sources and pinned WebAssembly runtime. It publishes automatically when the player or music sources change on `main`. The workflow injects the repository URL for the footer links.

For terminal launch commands, see the [desktop guide](../infinite/README.md).
