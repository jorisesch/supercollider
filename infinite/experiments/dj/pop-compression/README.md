# Pop compression listening test

The comparison uses two Pop excerpts with the same notes, synths and arrangement in each version. Open `audio/listening-round/pop-compression/listen.html` in a browser after rendering and packaging. Switch A, B and C during playback to compare at the same position. Choose a preference for each excerpt and paste the feedback into the chat.

- **A** bypasses the mix-bus compressor.
- **B** applies gentle compression at 2.5:1, with a 20 ms attack and 160 ms release.
- **C** applies stronger compression at 4:1, with a 4 ms attack and 180 ms release.

The deck's existing kick ducking is present in all versions. The comparison bypasses the live master's drive, compressor and limiter so it can isolate the proposed compression. Both stereo channels share a gain envelope. A 110 Hz high-pass filter in the detector reduces the kick and sub's influence on that envelope.

The package matches average levels across the six previews and leaves peak headroom. The raw renders include a diagnostic gain channel, which the package checks before writing stereo WAV and M4A previews. `verification.json` records the measured gain reduction and matching gain.

The stronger setting was selected for the Pop channel. The live master uses the same shared compression function from `../pop-master.scd`, followed by makeup gain and the output safety limiter.

From the repository root on macOS, run these commands.

```sh
mkdir -p audio/listening-round/pop-compression
/Applications/SuperCollider.app/Contents/MacOS/sclang -D \
  infinite/experiments/dj/pop-compression/render.scd "$PWD/audio/listening-round/pop-compression"
python3 infinite/experiments/dj/pop-compression/package.py audio/listening-round/pop-compression
```

The source loads definitions and renders offline. The comparison files and browser feedback stay in the locally ignored listening folder.
