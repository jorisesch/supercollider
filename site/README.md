# Infinite DJ in the browser

Press **Play** and choose **EDM**, **Pop**, **Soundscape** or **Rock**. **Next** starts a transition to another song or a fresh soundscape. **Energy** shapes the arrangement. Use your device’s volume controls to set the listening level.

If the browser asks for another tap after loading, press **Enable audio** to start playback. If startup fails, the status line identifies the step that failed. Press **Retry** to reload the player.

EDM opens on a generated 134 BPM anthem hook, and Pop opens on a chorus. Each set still starts with a fresh seed. The page loads the same SuperCollider composition and synthesis sources as the desktop app. The browser runs both `sclang` and `scsynth` in WebAssembly and routes their OSC messages through JavaScript. The player downloads a single bundle of music sources alongside the runtime. The browser generates the audio locally. [Runtime source and licenses](runtime/SOURCE.txt).

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
