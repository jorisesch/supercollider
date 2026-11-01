# Infinite DJ — groove and space v6.2

Two decks play an ongoing house/electro set at 118–140 BPM. Bass and drums carry the record: a repeating low bass groove, four-on-the-floor kick, percussion and long stretches with no lead. Brief melodic tags punctuate selected phrase endings. Every record selects a coordinated bass, accent synth and drum kit. Both the track edit and the infinite set use [style.scd](style.scd), [instruments.scd](instruments.scd) and the same playback adapters.

From the repository directory:

~~~sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/c-edm.scd 2600 128 0.25 0.55 0.30 0.20
~~~

Arguments: seed bpm chaos density mutation tension [nogui]. The window opens automatically. Close it to fade out and exit; Ctrl+C exits immediately. The optional nogui flag skips the window. Live playback records no audio.

## The style

The bass is the hook. Each record keeps a recognizable rhythmic cell with strong offbeat roots and quieter syncopated pickups. The first three bars repeat the cell; a small change to its last beat answers in the fourth bar. Root/fifth notes and occasional octave pickups keep the low part focused. Mutation varies the answer while Hold preserves it.

The bass opens gradually through each eight-bar phrase: filter brightness and saturation rise together, with stronger articulation in hook/drop sections and a darker sound in reduced sections. All four bass synths expose these controls. The low fundamental remains beneath the harmonic grit.

Kick anchors remain on the grid. Odd sixteenths in the bass, hats, ghost snares and percussion share subtle swing, roughly 11–20 ms at 128 BPM. Hats have deliberate accents and different lengths; quiet snare/hat ghosts connect the main hits. Extra hats arrive after the phrase has settled, and percussion enters later, then leaves for the next foundation passage.

There is no recurring lead riff, automatic arpeggio or chord comping. Occasional quiet phrases range from a short tag to a fuller melodic gesture, with repeated notes, syncopation and a resolving answer. Their rhythms and contours vary by record and mutation; the drop can develop the earlier phrase. Each entrance occupies one bar, separated by long bass/drum passages. In the first 48-bar edit, only two bars contain lead notes. Breakdowns keep a reduced kick, hats and sub pulse, with one quiet two-voice atmosphere at the entrance. Space sections remove extra percussion. One kick envelope ducks bass, accents and effect returns together. Bass and kick stay centred.

Four ensembles rotate through a seeded shuffle bag. Each is stable for its whole record, including Hold and motif mutations. Consecutive records choose different ensembles; the display and post window identify the instruments. Palette selection has its own random stream, so changing the ensemble preserves the composed notes and rhythms.

| Ensemble | Bass | Lead | Drum kit |
| --- | --- | --- | --- |
| Wired House | Classic sub | Octave saw | Tight house |
| Brass Circuit | Reese bass | Unison brass | Analog punch |
| Digital Drive | FM bass | FM growl | Dry electro |
| Acid Foundry | Resonant acid | Sync stack | Dust metal |

The bank retains four bass voices, four accent synths, four complete five-voice drum kits and three pads. Arp and stab definitions remain available for manual composition. [palette-instruments.scd](palette-instruments.scd) contains the additional definitions; [library.scd](library.scd) maps them into ensembles.

The opening establishes drums/bass. An occasional quarter-bar pullback (one beat in 4/4) removes the last kick, bass and hat hits before the next bar. These pullbacks have at least sixteen bars between them. The pre-drop withdrawal also lasts just one beat; its first three beats retain kick and bass. There is no automatic noise riser. Drum-only spotlights last one bar, occur no more than once per thirty-two record bars, and wait until the section has settled. They mute pitched tails as well as new notes; the UI labels them DRUM SPOTLIGHT.

Six forms range from 56 to 96 bars, with eight- or sixteen-bar handovers. Records rotate 32 profiles, 32 progressions, 20 duration templates and 12 keys, with 16 motif IDs selecting the sparse accent tags. Chord lengths are rounded to even bars to support dance phrases. The first record is C minor, with a [0,5,2,6] progression. Incoming records share the beat grid while tempo gradually moves to their target; old pitched parts and effect returns clear before the new key arrives.

Each deck has its own filter, dotted-eighth echo, reverb and stutter. Delay time stays fixed in beats; changing the send allows the stored echoes to decay naturally. Ordinary playback uses restrained sends, with more space in breakdowns.

Automatic stutter occasionally plays eight sixteenth-note pulses across the final half of a bar (beats three and four). It uses a gentler depth than a manual hit and leaves at least sixteen full clear bars afterward. The first half plays normally and the gate releases at the next downbeat. Automatic phrases stay inside the section, preserve drop landings and stop for a handover. FX choices use a separate seeded random stream, leaving the composition unchanged.

## Controls

The knobs shape the next generated bar. Density adds bass pickups and hats; Chaos increases phrase-ending fills and automatic stutter likelihood; Mutation varies the bass answer; Tension opens the voice filters and increases bass drive, with a smaller influence on automatic FX likelihood. Section energy moves effective settings around these centres. Higher Density keeps the lead sparse, and deliberate pullbacks retain their space.

- **Bass hook:** request four bars of stronger bass accents and phrase-ending pickups. It does not call in a lead riff.
- **Fill:** request a drum fill on the next generated bar.
- **Mutate motif:** change the bass pickup unless Hold is enabled.
- **Hold record:** keep the record and freeze motif mutations; harmony, sections and percussion continue.
- **NEXT record:** queue a handover at the next four-bar boundary, overriding Hold.
- **STOP / START:** fade and continue the same set at its next bar.
- **Restart seed:** reset with the current knobs and clear Hold.

HOT FILTER sweeps down for one bar. HOT ECHO sends the phrase into a longer fading tail. HOT WASH rises gradually across the bar. The three STUTTER buttons select **1/4**, **1/8** or **1/16** notes: four, eight or sixteen pulses in a full four-beat bar. The duration menu offers **1/2 bar**, **1 bar**, **2 bars** or **4 bars**, defaulting to a half bar. Half-bar hits start on beat three of the next generated bar; longer hits start on beat one and continue across bars. The phase resets once at the actual entrance. These are rhythmic gates with short smoothed edges.

**Auto stutter** enables or disables automatic phrases independently of the manual buttons. The status line shows the active rate, source, deck and remaining bars. Hold freezes motifs and record changes while automatic FX may continue. A running stutter stays pinned to its record; another manual stutter replaces it.

HOT actions target the currently leading deck and are quantized to the next generated bar; the latest request before a bar replaces the previous pending HOT request. All musical/FX buttons and knobs confirm their requests in the post window.

For IDE playback, load [live.scd](live.scd), then evaluate:

~~~supercollider
~djStart.value(2600, 128);
~djSet.value(0.25, 0.55, 0.30, 0.20);
~djFill.value;
~djHook.value; // four-bar bass hook
~djHot.value(\echo);
~djStutter.value(16, 0.5); // eight sixteenth pulses in the last half of the next bar
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

[48-bar groove track](../../../../../audio/groove-track-v6c.m4a) · [112-bar Infinite DJ excerpt](../../../../../audio/dj-groove-v6c.m4a) · [Compare all four ensembles](../../../../../audio/dj-groove-palettes-v6c.m4a)

The v6.2 groove track is the user's **favourite so far** (2026-10-31): “pretty good.” It is the listening reference for future refinements.

The first half-bar sixteenth-note stutter runs from about 53.54 to 54.48 seconds in the track and set. The earlier [v4 stutter excerpt](../../../../../audio/dj-auto-stutter.m4a) is retained for comparison.

The 64-second palette tour plays the same eight-bar bass-led section with Wired House at 0.1 seconds, Brass Circuit at 15.1, Digital Drive at 30.1 and Acid Foundry at 45.1. Automatic stutter is disabled for this timbre comparison; the track edit and live DJ include it. Restart a running DJ to load the new arrangement and Bass hook control.

The track edit is 94.1 seconds at 128 BPM, including its ending fade. Its sections are groove, hook, space, buildup, drop and outro. It has two regular one-beat pullbacks, around 27.8 and 57.8 seconds; the pre-drop pickup starts around 44.6 seconds. Each lasts about 0.47 seconds. A single drum-only bar starts around 67.6 seconds. The longer excerpt demonstrates the same style across automatic handovers and instrument changes. Timelines record the start beat of each cut, drum spotlights and bass tone/drive. Settings, timelines and checksums are recorded in [track.json](track.json), [preview.json](preview.json), [palette-tour.json](palette-tour.json) and [reproduction.json](reproduction.json).

The lead-forward [v4 source snapshot](../v4/ABOUT.md), [v2](../v2/ABOUT.md) and [v1](../v1/ABOUT.md) remain playable. Earlier audio files are retained separately. Human listening feedback belongs in [NOTES.md](../../NOTES.md); separate listening judgments for the longer set and palette tour remain pending.

## Rendering and checks

~~~sh
# Complete first-record edit:
sclang -D infinite/experiments/dj/render.scd track
# Longer set excerpt, including handovers:
sclang -D infinite/experiments/dj/render.scd
# Same bass groove, eight bars per ensemble:
sclang -D infinite/experiments/dj/render.scd palettes

sclang -D infinite/experiments/dj/check.scd
sclang -D infinite/experiments/dj/runtime-check.scd
sclang -D infinite/experiments/dj/bass-check.scd /tmp/dj-bass-check.wav
python3 infinite/experiments/dj/verify_bass.py /tmp/dj-bass-check.wav
sclang -D infinite/experiments/dj/stutter-check.scd /tmp/dj-stutter-check.wav
python3 infinite/experiments/dj/verify_stutter.py /tmp/dj-stutter-check.wav
python3 scripts/verify_audio.py

# Compact listening copies on macOS:
afconvert -f m4af -d 'aac ' -b 192000 -q 127 audio/groove-track-v6c.wav audio/groove-track-v6c.m4a
afconvert -f m4af -d 'aac ' -b 192000 -q 127 audio/dj-groove-v6c.wav audio/dj-groove-v6c.m4a
afconvert -f m4af -d 'aac ' -b 192000 -q 127 audio/dj-groove-palettes-v6c.wav audio/dj-groove-palettes-v6c.m4a
~~~

The renderer exits after writing the WAV and its timeline. WAVs and temporary scores remain ignored by Git; small AAC listening copies can be committed.

The pure check covers 8,192 seeded bars and 2,048 bars at macro extremes: timing, scales, catalog rotation, palette routing and stable composition. It checks motif repetition and small answers, bounded swing, quiet ghosts, percussion entrances/exits, bass filter/drive variation, quarter-bar cut limits and coordinated returns. Automatic stutters must occupy only the final half-bar, reset at beat three and leave sixteen clear bars; manual half-bar and longer actions remain covered. The signal check measures eight pulses inside the half-bar with steady output before and after, alongside the longer gate rates. The muted runtime check exercises the half-bar menu/button against the server, handovers, other controls, transport and cleanup. Audio verification checks available v6.2 renders against their timelines, palette levels, activity, duration, finite samples, headroom and quiet boundaries; it also measures the track's cuts and limits their count. These checks do not establish musical quality.
