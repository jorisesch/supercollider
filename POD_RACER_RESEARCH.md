# Pod-racer research brief

The current synth should stop trying to be a generic “space engine.” The strongest production references point to a real-world sound collage with clear vehicle personality and edited perspective.

## What the production references say

Ben Burtt describes the podrace as a sound-effects-led sequence: the audience should feel surrounded by the engine from the racers’ point of view, with sound carrying speed and danger without continuous music. He describes each racer as a distinct personality: Sebulba has a pulsing heartbeat-like engine, another is an electric toothbrush motor, and Anakin’s is a blend of high-speed racecars. The palette is a disguised collage of familiar high-energy sources including racecars, warbirds, jets, motorcycles, rockets, and helicopters. See the [StarWars.com interview](https://www.starwars.com/news/ben-burtt-the-phantom-menace).

Matthew Wood’s account adds the key editorial idea: the memorable material is often the transition between gears, with short high-energy changes rather than a steady sound. He also describes pulling back to distant canyon shots so the engine becomes reverb and echo. See the [Skywalker Sound interview](https://www.starwars.com/news/matthew-wood-the-phantom-menace).

The practical implication is a small library of contrasting gestures: crank/start, uneven idle, gear-change surge, high-speed engine, coast, pass-by, and distant canyon tail. A single continuously modulated oscillator cannot tell that story by itself.

## Reference-file measurements

The supplied scene was decoded locally and measured around 2:40–3:10. Its loudness and spectrum change in gestures rather than one continuous timbre. Two-second windows show these broad energy shifts:

| scene time | RMS dBFS | 20–150 Hz | 150–500 Hz | 500–2000 Hz |
|---:|---:|---:|---:|---:|
| 2:40 | -11.9 | 0.61 | 0.29 | 0.04 |
| 2:46 | -20.1 | 0.11 | 0.39 | 0.45 |
| 2:52 | -21.6 | 0.44 | 0.13 | 0.31 |
| 2:58 | -13.8 | 0.57 | 0.31 | 0.05 |
| 3:04 | -19.2 | 0.62 | 0.13 | 0.16 |

The low-frequency-heavy windows read as close engine mass; the midrange-heavy windows read as a gear change, pass, or more distant/angled view. The next implementation should automate those state changes explicitly.

## Next synthesis direction

Keep the user’s analog core as one layer: two slightly detuned sawtooths into an LFO-controlled low-pass filter. Add separate, level-controlled layers rather than using noise as the engine body:

1. Crank/start: sparse low-frequency pulses, uneven amplitude, and a few metal impacts.
2. Piston idle: a low pulse train with two slightly different firing rates; let this layer fade with speed.
3. Turbine/race layer: the saw pair opens through the filter as the LFO rate accelerates; add a short gear-change envelope when speed jumps.
4. Mechanical debris: rare clanks with resonant metal tails, triggered independently and kept quiet.
5. Pass-by: a slow band-pass sweep across stereo, with the pitch crossing the listener over roughly 1–3 seconds rather than a fast chirp.
6. Canyon: send only the pass and low engine transient into a sparse delay/reverb network. The wall repeats should be audible as fading low “whomp” echoes while the close engine remains dry.

Avoid a Shepard-riser as the main identity. It makes the sound feel like a synth demonstration instead of a vehicle. Use brief filter and gear transitions; let the familiar mechanical source carry the speed cue.
