# Infinite DJ — rotating palettes v4

Two decks play an ongoing house/electro set at 118–140 BPM. The current style uses a short crunchy riff, an offbeat bass ostinato, four-on-the-floor drums and deliberate space around the hook. Every record selects a coordinated bass, lead, drum kit and supporting voices. Both the track edit and the infinite set use [style.scd](style.scd), [instruments.scd](instruments.scd) and the same playback adapters.

From the repository directory:

~~~sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/c-edm.scd 2600 128 0.25 0.55 0.30 0.20
~~~

Arguments: seed bpm chaos density mutation tension [nogui]. The window opens automatically. Close it to fade out and exit; Ctrl+C exits immediately. The optional nogui flag skips the window. Live playback records no audio.

## The style

The lead and bass share offbeat accents and the same harmony. A small recurring riff has a call, a quieter repeat and a short resolving answer; mutation changes the answer after a full phrase. Arps and chord stabs answer in the gaps. They do not run continuously beneath the main hook.

The lead uses held notes and an octave-below body across the different synth families, with stock UGens throughout. The lead stays in a lower register and the music strip retains more low mids. One kick envelope ducks bass, lead and effect returns together, giving them a common pulse. The bass and kick stay centred, with supporting percussion and pads to the sides.

Four ensembles rotate through a seeded shuffle bag. Each is stable for its whole record, including Hold and motif mutations. Consecutive records choose different ensembles; the display and post window identify the instruments. Palette selection has its own random stream, so changing the ensemble preserves the composed notes and rhythms.

| Ensemble | Bass | Lead | Drum kit |
| --- | --- | --- | --- |
| Wired House | Classic sub | Octave saw | Tight house |
| Brass Circuit | Reese bass | Unison brass | Analog punch |
| Digital Drive | FM bass | FM growl | Dry electro |
| Acid Foundry | Resonant acid | Sync stack | Dust metal |

The expanded bank has four bass voices, four leads, four complete five-voice drum kits and three pads. Pads, arp answers and chord stabs are paired with each ensemble. [palette-instruments.scd](palette-instruments.scd) contains the additional definitions; [library.scd](library.scd) maps them into ensembles.

The opening establishes drums/bass before introducing the riff. Breakdowns sustain the harmony; a brief buildup and one impact announce the drop. Two-bar drum spotlights recur inside records and mute pitched tails as well as new notes. The UI labels these moments DRUM SPOTLIGHT.

Six forms range from 56 to 96 bars, with eight- or sixteen-bar handovers. Records rotate 32 profiles, 32 progressions, 20 duration templates, 16 motifs and 12 keys. Chord lengths are rounded to even bars to support dance phrases. The first record is C minor, with a [0,5,2,6] progression. Incoming records share the beat grid while tempo gradually moves to their target; old pitched parts and effect returns clear before the new key arrives.

Each deck has its own filter, dotted-eighth echo, reverb and stutter. Delay time stays fixed in beats; changing the send allows the stored echoes to decay naturally. Ordinary playback uses restrained sends, with more space in breakdowns.

Automatic stutter occasionally shapes a phrase ending or buildup, choosing quarter, eighth or sixteenth notes for one, two or four bars. It uses a gentler depth than a manual hit and leaves at least eight clear bars afterward. Automatic phrases stay inside the section, preserve drop landings and stop for a handover. FX choices use a separate seeded random stream, leaving the composition unchanged.

## Controls

The knobs shape the next generated bar. Density adds bass subdivisions, hats and brief answers; Chaos increases phrase-ending fills and automatic stutter likelihood; Mutation varies the riff's answer; Tension opens the voice filters and buildup brightness, with a smaller influence on automatic FX likelihood. Section energy moves effective settings around these centres.

- **Hook:** request four bars of the motif.
- **Fill:** request a drum fill on the next generated bar.
- **Mutate motif:** change the riff answer unless Hold is enabled.
- **Hold record:** keep the record and freeze motif mutations; harmony, sections and percussion continue.
- **NEXT record:** queue a handover at the next four-bar boundary, overriding Hold.
- **STOP / START:** fade and continue the same set at its next bar.
- **Restart seed:** reset with the current knobs and clear Hold.

HOT FILTER sweeps down for one bar. HOT ECHO sends the phrase into a longer fading tail. HOT WASH rises gradually across the bar. The three STUTTER buttons select **1/4**, **1/8** or **1/16** notes: four, eight or sixteen pulses in a four-beat bar. Use the **Stutter: 1/2/4 bars** menu to set the next manual hit's duration (default: two bars). The phase starts on the bar grid and continues across bars before releasing. These are rhythmic gates with short smoothed edges.

**Auto stutter** enables or disables automatic phrases independently of the manual buttons. The status line shows the active rate, source, deck and remaining bars. Hold freezes motifs and record changes while automatic FX may continue. A running stutter stays pinned to its record; another manual stutter replaces it.

HOT actions target the currently leading deck and are quantized to the next generated bar; the latest request before a bar replaces the previous pending HOT request. All musical/FX buttons and knobs confirm their requests in the post window.

For IDE playback, load [live.scd](live.scd), then evaluate:

~~~supercollider
~djStart.value(2600, 128);
~djSet.value(0.25, 0.55, 0.30, 0.20);
~djFill.value;
~djHook.value;
~djHot.value(\echo);
~djStutter.value(4, 2);  // quarter notes for two bars
~djStutter.value(8, 4);  // eighth notes for four bars
~djStutter.value(16, 1); // sixteenth notes for one bar
~djAutoStutter.value(false); // true to enable automatic FX again
~djNext.value;
~djHold.value(true);
~djStop.value;
~djResume.value;
~~~

Load [controls.scd](controls.scd) and evaluate ~djShow.value to open the window. CLI playback uses port 57134; IDE playback uses s unless supplied a server. Existing local startup hooks still execute. Close one performance before starting another.

## Listen

[Compare all four ensembles](../../../audio/dj-palette-tour.m4a) · [112-bar Infinite DJ excerpt](../../../audio/dj-interlock-v4.m4a) · [48-bar Wired House edit](../../../audio/interlock-track-v4.m4a)

[Automatic stutter excerpt](../../../audio/dj-auto-stutter.m4a) includes a two-bar eighth-note phrase between stretches of normal playback. It starts about three seconds into this excerpt, or at 52.6 seconds in the full DJ preview.

The 64-second palette tour plays the same eight-bar hook with Wired House at 0.1 seconds, Brass Circuit at 15.1, Digital Drive at 30.1 and Acid Foundry at 45.1. Automatic stutter is disabled for this timbre comparison; the track edit and live DJ include it. Restart a running DJ to load the controls and automatic FX.

The track edit is 94.1 seconds at 128 BPM, including its ending fade. Its sections are groove, hook, space, buildup, drop and outro; the drop arrives at about 45 seconds. The longer excerpt demonstrates the same style across automatic handovers and instrument changes. Settings, timelines and checksums are recorded in [track.json](track.json), [preview.json](preview.json), [palette-tour.json](palette-tour.json) and [reproduction.json](reproduction.json).

Earlier candidates are preserved as a playable [v2 source snapshot](revisions/v2/ABOUT.md) and [v1](revisions/v1/ABOUT.md). Existing v2/v3 audio files are retained separately. Human listening feedback belongs in [NOTES.md](NOTES.md); listening to the new ensembles is pending.

## Rendering and checks

~~~sh
# Complete first-record edit:
sclang -D infinite/experiments/dj/render.scd track
# Longer set excerpt, including handovers:
sclang -D infinite/experiments/dj/render.scd
# Same hook, eight bars per ensemble:
sclang -D infinite/experiments/dj/render.scd palettes

sclang -D infinite/experiments/dj/check.scd
sclang -D infinite/experiments/dj/runtime-check.scd
sclang -D infinite/experiments/dj/stutter-check.scd /tmp/dj-stutter-check.wav
python3 infinite/experiments/dj/verify_stutter.py /tmp/dj-stutter-check.wav
python3 verify_audio.py

# Compact listening copies on macOS:
afconvert -f m4af -d 'aac ' -b 192000 -q 127 audio/interlock-track-v4.wav audio/interlock-track-v4.m4a
afconvert -f m4af -d 'aac ' -b 192000 -q 127 audio/dj-interlock-v4.wav audio/dj-interlock-v4.m4a
afconvert -f m4af -d 'aac ' -b 192000 -q 127 audio/dj-palette-tour.wav audio/dj-palette-tour.m4a
~~~

The renderer exits after writing the WAV and its timeline. WAVs and temporary scores remain ignored by Git; small AAC listening copies can be committed.

The pure check covers 8,192 seeded bars and 2,048 bars at macro extremes: timing, scales, catalog rotation, palette routing and stable composition. It also checks automatic stutter placement, rates, multi-bar durations, cooldowns, manual release and Auto OFF. The muted runtime check exercises the duration menu, Auto switch, palette handover and effect buttons, including queried rates, transport, output and cleanup. The stutter signal test measures one quarter-note bar, two eighth-note bars and four sixteenth-note bars before bypass. Audio verification checks available v4 renders against their timelines, palette coverage, matched tour levels, every bar's activity, duration, finite samples, headroom and quiet boundaries. These checks do not establish musical quality.
