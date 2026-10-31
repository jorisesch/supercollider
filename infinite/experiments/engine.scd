// Experimental composition adapters. The original engine is loaded, never edited.
(
var root=thisProcess.nowExecutingPath.dirname;
(root.dirname +/+ "infinite-engine.scd").load;
~experimentVoiceLead = { |notes, previous|
    var best, cost=1e9;
    [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]].do { |order|
        var candidate=order.collect { |index, voice|
            var options=[-24, -12, 0, 12, 24].collect { |octave| notes[index] + octave }
                .select { |note| (note >= 52) and: { note <= 76 } };
            options.sort { |a, b| (a - previous[voice]).abs < (b - previous[voice]).abs }.first;
        };
        var score=(candidate - previous).abs.sum + ((candidate.mean - 64).abs * 0.2);
        if(score < cost) { cost=score; best=candidate };
    };
    best;
};
~makeExperimentEngine = { |mode=\edm, seed=2600, settings|
    var original, engine, controls, state, nextBar, bar=0;
    var randomState=(seed.abs % 2147483646) + 1, random, choose;
    var voiceLead=~experimentVoiceLead, voicing, leadPrevious=67;
    var bloom=false, change=false, harmony=0, foundation=36;
    if([\edm, \soundscape].includes(mode).not) { Error("Unknown experiment mode").throw };
    controls=(chaos:0.25, density:0.55, mutation:0.30, tension:0.20, hold:false, arpProbability:0.96);
    if(settings.notNil) { settings.keysValuesDo { |key, value| controls[key]=value } };
    random={ randomState=(randomState * 48271) % 2147483647; randomState / 2147483647 };
    choose={ |items| items[(random.value * items.size).floor.asInteger] };
    if(mode == \edm) {
        original=~makeInfiniteEngine.value(\edm, seed, controls);
        controls=original.controls; state=original.state; voicing=[60, 63, 67];
    } {
        state=(key:36, scale:[0, 2, 4, 5, 7, 9, 11], chord:[60, 64, 67], bar:0,
            section:\settle, harmony:0, tension:0.2);
        voicing=[60, 64, 67];
    };
    nextBar={
        var events=List.new, density=controls.density.clip(0, 1), chaos=controls.chaos.clip(0, 1);
        var tension=controls.tension.clip(0, 1), position=bar % 64, section;
        var add, tone=(0.3 + (tension * 0.45));
        add={ |track, voice, beat, note, duration, amp, pan=0, attack=0.01, release=0.5|
            events.add((track:track, voice:voice, beat:beat, midinote:note, duration:duration,
                amp:amp, pan:pan, attack:attack, release:release, tone:tone, seed:seed + (bar * 31) + events.size));
        };
        if(mode == \edm) {
            var raw;
            original.bpm=engine.bpm;
            raw=original[\nextBar].value;
            section=case
                { position < 8 } { \introduce }
                { position < 24 } { \theme }
                { position < 32 } { \lift }
                { position < 40 } { \breakdown }
                { position < 48 } { \rebuild }
                { true } { \release };
            raw.do { |event|
                var e=event.copy, keep=true, step=(e.beat * 4).round.asInteger;
                if(section == \introduce) {
                    if((e.track == 1) and: { position < 4 }) { keep=false };
                    if((e.track == 2) and: { step.odd.not }) { keep=false };
                };
                if(section == \breakdown) {
                    if([0, 3].includes(e.track)) { keep=false };
                    if((e.track == 2) and: { (step % 4) != 1 }) { keep=false };
                };
                if((section == \rebuild) and: { position < 44 }) {
                    if((e.voice == \igKick) and: { (step % 8) != 0 }) { keep=false };
                };
                if(keep) {
                    e.seed=seed + (bar * 31) + events.size; e.tone=tone;
                    if(e.track == 0) { e.voice=\xpBass; e.duration=0.21; e.amp=e.amp * 1.2 };
                    if(e.track == 1) {
                        var options=[-12, 0, 12].collect { |octave| e.midinote + octave }
                            .select { |note| (note >= 60) and: { note <= 84 } };
                        e.midinote=options.sort { |a, b| (a - leadPrevious).abs < (b - leadPrevious).abs }.first;
                        leadPrevious=e.midinote;
                        e.voice=\xpPluck; e.duration=0.32; e.amp=e.amp * 1.5;
                    };
                    if(e.track == 2) { e.voice=\xpArp; e.duration=0.24; e.amp=e.amp * 1.25 };
                    if(step.odd and: { (e.track == 2) or: { e.voice == \igHat } }) {
                        e.beat=e.beat + (0.025 * (0.5 + chaos));
                    };
                    events.add(e);
                };
            };
            if(bar.even) {
                voicing=voiceLead.value(state.chord + 24, voicing);
                voicing.do { |note, i|
                    add.value(1, \xpChord, 0, note, if(section == \breakdown, 5.5, 2.5),
                        if(section == \breakdown, 0.045, 0.032), (i - 1) * 0.35, 0.18, 1.2);
                };
            };
            state.section=section;
        } {
            var chordSets=[[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62]];
            var roots=[0, 9, 5, 7], rootNote, count;
            if(((bar % 8) == 0) and: { controls.hold.not }) {
                harmony=(bar div: 8) % 4;
                voicing=voiceLead.value(chordSets[harmony], voicing);
            };
            if(change and: { controls.hold.not }) {
                if(random.value < 0.5) { voicing=voicing.rotate(1) } { voicing=voicing.rotate(-1) };
            };
            change=false;
            state.bar=bar; state.harmony=harmony; state.chord=voicing.copy;
            state.tension=tension;
            state.section=[\settle, \open, \float, \home][harmony];
            rootNote=36 + roots[harmony];
            if((bar % 8) == 0) {
                var options=[-12, 0, 12].collect { |octave| rootNote + octave }
                    .select { |note| (note >= 24) and: { note <= 47 } };
                foundation=options.sort { |a, b| (a - foundation).abs < (b - foundation).abs }.first;
                add.value(0, \xpDrone, 0, foundation, 24, 0.16, 0, 4, 6);
            };
            if((bar % 4) == 0) {
                count=if(density < 0.2, 2, 3);
                voicing.keep(count).do { |note, i|
                    add.value(1, \xpCloud, i * 0.13, note, 8, 0.075,
                        (i - 1) * 0.4, 6, 12);
                };
                if((tension > 0.5) and: { density > 0.6 }) {
                    add.value(1, \xpCloud, 0.6, rootNote + 26, 6, 0.035, 0.3, 7, 10);
                };
                add.value(3, \xpAir, 0.4, 68 + (tension * 12), 8, 0.11, -0.2, 4, 10);
            };
            if([2, 5, 7].includes(bar % 8) and: { random.value < (0.15 + (density * 0.65)) }) {
                add.value(2, \xpBell, 0.3 + (random.value * 2.8), choose.value(voicing) + 12,
                    2, 0.05, (random.value - 0.5) * (0.7 + chaos), 0.04, 4);
            };
            if(bloom) {
                voicing.do { |note, i| add.value(2, \xpBell, 0.2 + (i * 0.7), note + 12, 3, 0.035, (i - 1) * 0.35, 0.05, 5) };
                bloom=false;
            };
            if(((bar % 8) == 7) and: { controls.hold.not } and: { random.value < controls.mutation.clip(0, 1) }) { change=true };
        };
        state.voicing=voicing.copy; state.bpm=engine.bpm;
        bar=bar + 1;
        events.sort { |a, b| a.beat < b.beat };
    };
    engine=(mode:mode, bpm:if(mode == \edm, 126, 48), controls:controls, state:state, nextBar:nextBar,
        requestFill:{ if(mode == \edm) { original[\requestFill].value } { bloom=true } },
        requestMutation:{ if(mode == \edm) { original[\requestMutation].value } { change=true } });
    engine;
};
~experimentMessage={ |event, engine, node, group, bus|
    [\s_new, event.voice, node, 0, group, \out, bus + if(event.track == 3 and: { engine.mode == \edm }, 2, 0),
        \freq, event.midinote.midicps, \amp, event.amp, \sustain, event.duration * 60 / engine.bpm,
        \pan, event.pan, \tone, event[\tone] ? 0.4, \seed, event[\seed] ? 2600,
        \attack, event[\attack] ? 0.01, \release, event[\release] ? 0.5]
};
)
