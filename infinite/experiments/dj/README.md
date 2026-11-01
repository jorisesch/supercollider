# Infinite DJ — groove and space v6.3

Two decks play an ongoing house/electro set at 118–140 BPM. Bass and drums carry the record: a repeating low bass groove, four-on-the-floor kick, percussion and long stretches with no lead. Brief melodic tags punctuate selected phrase endings. Every record selects a coordinated bass, accent synth and drum kit. Both the track edit and the infinite set use [style.scd](style.scd), [instruments.scd](instruments.scd) and the same playback adapters.

From the repository directory:

~~~sh
/Applications/SuperCollider.app/Contents/MacOS/sclang -D infinite/experiments/c-edm.scd 2600 128 0.25 0.55 0.30 0.20
~~~

Arguments: seed bpm chaos density mutation tension [nogui]. The window opens automatically. Close it to fade out and exit; Ctrl+C exits immediately. The optional nogui flag skips the window. Live playback records no audio.

## Pop channel

The window now has an **EDM / Pop** channel selector. EDM remains the default and retains its existing catalog, instruments and musical grammar. Switching channels fades the old performance and restarts the seed at the selected channel's factory tempo (EDM: 128 BPM; Pop: 138 BPM), preserving the knobs, Hold and automatic FX setting. STOP / START continues the current channel. Soundscape remains available through its original launcher.

Start Pop directly from the repository root:

~~~sh
sclang -D infinite/experiments/pop.scd
# Optional: seed bpm chaos density mutation tension [nogui]
sclang -D infinite/experiments/pop.scd 2600 138 0.25 0.55 0.30 0.20
~~~

Pop develops the original [Neon Rush](../../../neon-rush/track.scd) sketch into continuously generated instrumental records: offbeat pulse bass, bright detuned saw leads, sustained chord beds, and rotating drum kits. Each record chooses a key, familiar four-chord progression and four-bar chorus motif. Verses leave melodic space; the chorus repeats its motif when it returns. Mutation changes verse/bass answers while preserving the chorus. The **Chorus** button brings that hook forward for four bars. Existing deck FX, Fill, Hold, NEXT and transport remain available.

The mixer labels its Pop song sections using the shared internal names: `groove` is a verse, `hook` and `drop` are choruses, `space` and `breakdown` are bridges. Pop records have 64- or 96-bar forms with eight-bar automatic handovers. Its own catalog and voices are in [pop-style.scd](pop-style.scd) and [pop-instruments.scd](pop-instruments.scd). Loading them starts no playback. The EDM style and existing instrument definitions are unchanged.

[Listen to the Pop excerpt](../../../audio/dj-pop-preview.m4a): 96 bars, around 2:53 including the ending, with a complete first record and an automatic handover. Its [manifest](pop.json) and [timeline](dj-pop-preview-timeline.tsv) describe the render. **Human listening review is pending**; numerical and muted runtime checks do not establish musical quality.

For IDE playback, load `live.scd` and `controls.scd`, then evaluate:

~~~supercollider
~djSettings.channel=\pop;
~djStart.value(2600,138);
~djShow.value;
~djChannel.value(\edm); // fade and restart in EDM
~djChannel.value(\pop); // fade and restart in Pop
~djStop.value;           // graceful stop
~~~

Render and check Pop with:

~~~sh
sclang -D infinite/experiments/dj/render.scd pop
sclang -D infinite/experiments/dj/pop-check.scd
sclang -D infinite/experiments/dj/pop-runtime-check.scd
python3 scripts/verify_audio.py
afconvert -f m4af -d aac -b 192000 -q 127 audio/dj-pop-preview.wav audio/dj-pop-preview.m4a
~~~

The Pop structural check covers 1,024 reproducible bars, returning chorus hooks, key membership, defined voices, automatic handovers and Hold/NEXT. Its muted runtime check exercises the actual channel menu and Chorus/Fill callbacks, a Pop handover, internal signal, transport continuation, return to EDM and old-bus cleanup. The unchanged EDM structural suite and UI runtime check remain available. A 256-bar before/after capture of EDM notes and automation was byte-identical when this channel was added.

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
| Digital Drive | FM bass | Rounded FM | Dry electro |
| Acid Foundry | Resonant acid | Sync stack | Dust metal |

Digital Drive's lead has a lower FM index, a smoother octave layer, gentler saturation and a lower filter cutoff. Its attack and release are rounded to reduce the sharp edge. This refinement changes only that lead SynthDef; basses, kits, other voices and the arrangement retain the favourite version's definitions and events.

The bank retains four bass voices, four accent synths, four complete five-voice drum kits and three pads. Arp and stab definitions remain available for manual composition. [palette-instruments.scd](palette-instruments.scd) contains the additional definitions; [library.scd](library.scd) maps them into ensembles.

The opening establishes drums/bass. An occasional quarter-bar pullback (one beat in 4/4) removes the last kick, bass and hat hits before the next bar. These pullbacks have at least sixteen bars between them. The pre-drop withdrawal also lasts just one beat; its first three beats retain kick and bass. There is no automatic noise riser. Drum-only spotlights last one bar, occur no more than once per thirty-two record bars, and wait until the section has settled. They mute pitched tails as well as new notes; the UI labels them DRUM SPOTLIGHT.

Six forms range from 56 to 96 bars, with eight- or sixteen-bar handovers. Records rotate 32 profiles, 32 progressions, 20 duration templates and 12 keys, with 16 motif IDs selecting the sparse accent tags. Chord lengths are rounded to even bars to support dance phrases. The first record is C minor, with a [0,5,2,6] progression. Incoming records share the beat grid while tempo gradually moves to their target; old pitched parts and effect returns clear before the new key arrives.

Each deck has its own filter, dotted-eighth echo, reverb and stutter. Delay time stays fixed in beats; changing the send allows the stored echoes to decay naturally. Ordinary playback uses restrained sends, with more space in breakdowns.

Automatic stutter occasionally plays eight sixteenth-note pulses across the final half of a bar (beats three and four). It uses a gentler depth than a manual hit and leaves at least sixteen full clear bars afterward. The first half plays normally and the gate releases at the next downbeat. Automatic phrases stay inside the section, preserve drop landings and stop for a handover. FX choices use a separate seeded random stream, leaving the composition unchanged.

## Controls

The compact window shows a generated **track name** for each deck. The leading deck is highlighted green, and a short status underneath identifies **Playing**, **fading in/out**, or **Stopped**. An empty deck has a blank name and a separate animated `waiting.` / `waiting..` / `waiting...` status. Hover over a name for the key, section, tempo, instruments, chords and energy. Knob values and explanations are also on hover. Select a name to copy it.

The thin slider is the **A/B mix position**: it starts left while A plays, moves right during the handover to B, stays right for B's record, then moves left during the return to A. Stopping holds its position. Hover for the mix percentages, tempo and bar.

The four knobs retain Chaos, Density, Mutation and Tension. **Next** queues a record, **Bass hook / Chorus** brings its hook forward, **Fill** requests a drum fill, and **Hold** keeps the current record and freezes motif changes. **STOP / START** fades out and continues the same set. The **More...** menu contains Mutate motif, Restart seed and Replay track. Restart seed clears Hold.

Choose **Filter**, **Echo**, **Wash**, or **Stutter 1/4, 1/8, 1/16** from the effect menu. Selection alone does nothing. **Start FX** activates the selection on the next generated bar and keeps it running until **Stop FX**. Filter and wash develop over their first bar and then hold; echo keeps sending; stutter continues at the selected note division. Effects follow the leading deck through handovers. Stop releases the effect with smoothing, including the remaining automation in the current bar, while existing echo/reverb tails decay. Stop the effect before choosing another. Stopping music also clears the manual effect.

**Auto ON/OFF** controls occasional automatic half-bar stutters. Manual effects take priority. The old bounded `~djHot` and `~djStutter` calls remain available from code.

The **Spectrum** panel shows separate left/right FFTs of the final output, with logarithmic Hz/kHz labels and an 80 dB range. It pauses with STOP, resumes with START, and has its own ON/OFF switch. Closing the window frees its synths and buffers; headless playback creates no analyzer.

## Replay a named track

Choose **More... → Replay track...**, paste the complete name, and press Play track. The name restores the record's original entry, including its handover context, from a small local JSON recipe. Recipes record the seed, channel, starting controls and earlier knob/action history; the notes and automation are generated again. Later live gestures are a new performance and are not encoded by that starting name.

Recipes live in `infinite/experiments/dj/saved-tracks/`, which is ignored by Git. Copy that folder with the matching music source to move your library to another machine. A name is a lookup key in this library, not a globally published song ID. Recipes check their source version before playing. No WAV is needed. The [recall code](recall.scd) is separate from the pure composition engine and never evaluates recipe data as code.

For IDE playback, load [live.scd](live.scd), then evaluate:

~~~supercollider
~djStart.value(2600, 128);
~djSet.value(0.25, 0.55, 0.30, 0.20);
~djFill.value;
~djHook.value; // four-bar bass hook
~djFXStart.value(\echo); // keep sending until explicitly stopped
~djFXStop.value;
// Replay a copied name from the local recipe library:
// ~djRecall.value("Copper Motion at Velvet Dawn");
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

[Digital Drive lead in context](../../../audio/digital-drive-rounded-v6d.m4a) · [Before/after lead](../../../audio/digital-drive-lead-ab-v6d.m4a) · [112-bar Infinite DJ excerpt](../../../audio/dj-groove-v6d.m4a) · [Compare all four ensembles](../../../audio/dj-groove-palettes-v6d.m4a) · [48-bar Wired House edit](../../../audio/groove-track-v6d.m4a)

The [v6.2 groove track](../../../audio/groove-track-v6c.m4a) remains the user's **favourite so far** (2026-10-31): “pretty good.” Its original audio and a playable [source snapshot](revisions/v6c/ABOUT.md) are preserved as the listening reference. The rounded Digital Drive lead awaits listening feedback.

The focused Digital Drive passage runs for four bars with a complete ending tail; its lead enters around 6.4 seconds. The isolated comparison plays four notes with the old lead first (0–4 seconds), then the same notes with the new lead (4–8 seconds), at identical note levels and brightness controls.

The first half-bar sixteenth-note stutter runs from about 53.54 to 54.48 seconds in the track and set. The earlier [v4 stutter excerpt](../../../audio/dj-auto-stutter.m4a) is retained for comparison.

The 64-second palette tour plays the same eight-bar bass-led section with Wired House at 0.1 seconds, Brass Circuit at 15.1, Digital Drive at 30.1 and Acid Foundry at 45.1. Automatic stutter is disabled for this timbre comparison; the track edit and live DJ include it. Restart a running DJ to load the new arrangement and Bass hook control.

The track edit is 94.1 seconds at 128 BPM, including its ending fade. Its sections are groove, hook, space, buildup, drop and outro. It has two regular one-beat pullbacks, around 27.8 and 57.8 seconds; the pre-drop pickup starts around 44.6 seconds. Each lasts about 0.47 seconds. A single drum-only bar starts around 67.6 seconds. The longer excerpt demonstrates the same style across automatic handovers and instrument changes. Timelines record the start beat of each cut, drum spotlights and bass tone/drive. Settings, timelines and checksums are recorded in [track.json](track.json), [preview.json](preview.json), [palette-tour.json](palette-tour.json) and [reproduction.json](reproduction.json).

The lead-forward [v4 source snapshot](revisions/v4/ABOUT.md), [v2](revisions/v2/ABOUT.md) and [v1](revisions/v1/ABOUT.md) remain playable. Earlier audio files are retained separately. Human listening feedback belongs in [NOTES.md](NOTES.md); separate listening judgments for the longer set and palette tour remain pending.

## Rendering and checks

~~~sh
# Complete first-record edit:
sclang -D infinite/experiments/dj/render.scd track
# Longer set excerpt, including handovers:
sclang -D infinite/experiments/dj/render.scd
# Same bass groove, eight bars per ensemble:
sclang -D infinite/experiments/dj/render.scd palettes
# Focused Digital Drive passage:
sclang -D infinite/experiments/dj/render.scd digital
# Isolated old/new Digital Drive lead and spectral check:
sclang -D infinite/experiments/dj/lead-compare.scd
python3 infinite/experiments/dj/verify_lead.py

sclang -D infinite/experiments/dj/check.scd
sclang -D infinite/experiments/dj/runtime-check.scd
sclang -D infinite/experiments/dj/spectrum-check.scd
sclang -D infinite/experiments/dj/deck-view-check.scd
sclang -D infinite/experiments/dj/interaction-check.scd
sclang -D infinite/experiments/dj/manual-fx-check.scd /tmp/dj-manual-fx-check.wav
python3 infinite/experiments/dj/verify_manual_fx.py /tmp/dj-manual-fx-check.wav
sclang -D infinite/experiments/dj/bass-check.scd /tmp/dj-bass-check.wav
python3 infinite/experiments/dj/verify_bass.py /tmp/dj-bass-check.wav
sclang -D infinite/experiments/dj/stutter-check.scd /tmp/dj-stutter-check.wav
python3 infinite/experiments/dj/verify_stutter.py /tmp/dj-stutter-check.wav
python3 scripts/verify_audio.py

# Compact listening copies on macOS:
afconvert -f m4af -d 'aac ' -b 192000 -q 127 audio/groove-track-v6d.wav audio/groove-track-v6d.m4a
afconvert -f m4af -d 'aac ' -b 192000 -q 127 audio/dj-groove-v6d.wav audio/dj-groove-v6d.m4a
afconvert -f m4af -d 'aac ' -b 192000 -q 127 audio/dj-groove-palettes-v6d.wav audio/dj-groove-palettes-v6d.m4a
afconvert -f m4af -d 'aac ' -b 192000 -q 127 audio/digital-drive-rounded-v6d.wav audio/digital-drive-rounded-v6d.m4a
afconvert -f m4af -d 'aac ' -b 192000 -q 127 audio/digital-drive-lead-ab-v6d.wav audio/digital-drive-lead-ab-v6d.m4a
~~~

The renderer exits after writing the WAV and its timeline. WAVs and temporary scores remain ignored by Git; small AAC listening copies can be committed.

The pure check covers 8,192 seeded bars and 2,048 bars at macro extremes: timing, scales, catalog rotation, palette routing and stable composition. It checks motif repetition and small answers, bounded swing, quiet ghosts, percussion entrances/exits, bass filter/drive variation, quarter-bar cut limits and coordinated returns. Automatic stutters must occupy only the final half-bar, reset at beat three and leave sixteen clear bars; manual half-bar and longer actions remain covered. The signal check measures eight pulses inside the half-bar with steady output before and after, alongside the longer gate rates. The muted runtime check exercises the compact window, tooltips, all six menu-selected held effects and immediate release against the server, handovers, transport, track-name replay and cleanup. The interaction check compares unchanged EDM events/automation with the favourite snapshot and checks EDM/Pop recall after prior knob and action history. The offline manual-FX probe verifies a sixteenth stutter through its sixth held bar and continuous output after release. Audio verification checks available v6.3 renders against their timelines, palette levels, activity, duration, finite samples, headroom and quiet boundaries; it also measures the track's cuts and limits their count. The lead comparison checks that only the FM lead SynthDef changed, and measures reduced upper-band energy at comparable RMS levels. These checks do not establish musical quality.
