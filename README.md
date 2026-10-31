# A playground for sound

Put on headphones. Let a groove run. Start an imaginary engine. Open a patch and change something.

This is an open notebook of experiments made with **SuperCollider**: music that keeps going, machines with a character of their own, and a reusable skill for making more of both. There is audio to listen to, code to take apart, and plenty still to explore.

## Find your next groove

[**Infinite music**](infinite/README.md) starts with a simple question: how much can a pattern change and still feel familiar?

Four tracks share a musical world. Basslines remember their phrases, melodies repeat and resolve, rhythms leave gaps, and the arrangement makes room for a return. Try EDM for a steady pulse and melodic patterns, or soundscapes for slower layers and space.

Four knobs let you steer: **Chaos**, **Density**, **Mutation**, and **Tension**. Find a groove you like, hold it for a while, then nudge it somewhere else.

With SuperCollider installed on macOS, run this from the repository directory:

```sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/infinite-run.scd
```

A control window opens and the music starts. Close it to fade out. The [music guide](infinite/README.md) has the other modes, controls, and ways to experiment.

## Take an imaginary machine for a spin

The [**pod racer**](audio/pod-racer.wav) is a little scene told through sound: a reluctant engine catches, warms up, shifts gears, and tears past a canyon wall.

Listen for the uneven pistons, the change in character as it accelerates, and the space opening up around a pass. Then [open the patch](audio/pod-racer.scd) or [take the live controls](pod-racer-live.scd) and give the engine a different personality. It is built from synthesis, with no film samples.

**[Listen to the pod racer →](audio/pod-racer.wav)** · [Explore the sound design](docs/sound-design.md) · [Read the research notes](POD_RACER_RESEARCH.md)

There are other sounds to wander into, too: a [rocket launch](audio/rocket-launch.wav), clean [space-radio signals](audio/quindar-in-out.wav), and their [vinyl-textured cousins](audio/quindar-in-noisy.wav). Each of these has an editable playback patch beside it in [`audio/`](audio/).

To play one, open its `.scd` file in SuperCollider, select all, and evaluate with **Cmd+Return** on macOS (**Ctrl+Return** on Windows/Linux).

## Make the next experiment

The [**SuperCollider music skill**](skill/supercollider-music/SKILL.md) collects the working methods behind these projects: turn an idea into an instrument, give it a playable arrangement, render it, measure it, and listen again.

Use it with Codex, or read it as a practical starting point for your own patches. It covers composition and sound design, keeping instruments separate from playback, and checking what a render actually produced.

<details>
<summary>Install the skill for Codex</summary>

From the repository directory:

```sh
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R skill/supercollider-music "${CODEX_HOME:-$HOME/.codex}/skills/"
```

Refresh skills, then invoke `$supercollider-music`.

</details>

These are working experiments. Try a different tempo, change a sound, follow an unexpected result. If you find a direction worth exploring, bring it back as an issue or a pull request.
