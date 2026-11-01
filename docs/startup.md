# SuperCollider startup

Normally, `sclang` starts the language interpreter; `scsynth` is the separate audio server. Code such as `s.boot` or `s.waitForBoot` starts the server. Infinite DJ boots its own server automatically, so no manual boot is needed.

SuperCollider also evaluates your user `startup.scd` whenever the language starts, including command-line renders. A startup file that boots the server and starts SuperDirt therefore makes those services start automatically. This is a local configuration choice, not a requirement of Infinite DJ. Running multiple language sessions with that setup can cause OSC port conflicts.

The optional [startup.scd example](../patches/startup.scd) in this repo configures a stereo, output-only default server and starts SuperDirt on OSC port 57120. It requires SuperDirt and its samples. Personal sample folders and custom patch loads are omitted. **The repository copy does not run automatically**, and Infinite DJ does not need it.

To find your active startup file, evaluate `Platform.userConfigDir +/+ "startup.scd"` in SuperCollider, or choose **File → Open startup file**. On macOS it is normally `~/Library/Application Support/SuperCollider/startup.scd`. Back up any existing file before copying or merging the example into that location. Leave it uninstalled for a DJ-only setup, or comment out the SuperDirt boot block in your active file if you want to start SuperDirt manually. Editing the repository example does not change your installed startup file.
