// Composition and source checks only: no sound or WAV files.
(
var root=thisProcess.nowExecutingPath.dirname, standardFactory,
    assert={ |ok, message| if(ok.not) { Error(message).throw } };
try {
    (root +/+ "live.scd").load;
    (root +/+ "controls.scd").load;
    ["launch.scd", "a-edm.scd", "b-soundscape.scd"].do { |file|
        assert.value(File.readAllString(root +/+ file).compile.notNil, "Parse failed: " ++ file);
    };
    ~experimentDefs.do { |def| assert.value(def.asBytes.size > 0, "Invalid synth definition") };
    {
        var previousEngine=~experimentEngine, fill=false, mutation=false;
        var fake=(controls:(hold:false), requestFill:{ fill=true }, requestMutation:{ mutation=true });
        ~experimentEngine=fake;
        ~setExperiment.value(0.10, 0.20, 0.30, 0.40);
        ~fillExperiment.value; ~mutateExperiment.value; ~holdExperiment.value(true);
        assert.value(fill and: { mutation } and: { fake.controls.hold }, "Experiment control callbacks not wired");
        assert.value((fake.controls.chaos - 0.10).abs < 0.0001 and: { (fake.controls.tension - 0.40).abs < 0.0001 },
            "Experiment knob callback did not update the engine");
        ~experimentEngine=previousEngine;
        "PASS experiment controls: knobs and Fill/Mutate/Hold callbacks reach the engine.".postln;
    }.value;
    [\edm, \soundscape].do { |mode|
        var a=~makeExperimentEngine.value(mode, 2600), b=~makeExperimentEngine.value(mode, 2600);
        var total=0, active=List.new, peak=0, voices=Set.new, previousChord;
        128.do { |bar|
            var x=a[\nextBar].value, y=b[\nextBar].value, last=0;
            assert.value(x.asCompileString == y.asCompileString, "Non-reproducible events");
            x.do { |event|
                var absolute=(bar * 4 + event.beat) * 60 / a.bpm;
                var life=(event.duration * 60 / a.bpm) + (event[\attack] ? 0.1) + (event[\release] ? 1);
                assert.value((event.beat >= last) and: { event.beat < 4 }, "Invalid event order/time");
                assert.value(event.duration > 0 and: { event.amp > 0 }, "Invalid envelope or amplitude");
                assert.value(event.track >= 0 and: { event.track <= 3 }, "Expected four lanes");
                if(event.track < 3) {
                    assert.value(a.state.scale.includes((event.midinote - a.state.key) % 12), "Pitch escaped key");
                };
                if((mode == \edm) and: { a.state.section == \breakdown }) {
                    assert.value([0, 3].includes(event.track).not, "Breakdown retained bass or drums");
                };
                if(mode == \soundscape) { assert.value(event.voice.asString.beginsWith("xp"), "Ambient used a rhythmic baseline voice") };
                voices.add(event.voice); last=event.beat; total=total + 1;
                active=active.select { |ending| ending > absolute }; active=active.add(absolute + life); peak=peak.max(active.size);
            };
            if(mode == \soundscape) {
                if((bar % 8) != 0) { assert.value(a.state.chord == previousChord, "Ambient harmony changed too quickly") };
                previousChord=a.state.chord.copy;
            };
        };
        if(mode == \edm) { assert.value(total > 2000 and: { voices.includes(\xpChord) }, "EDM lacks activity or harmony") }
            { assert.value(total < 300 and: { peak < 32 }, "Ambient events or voices accumulate") };
        ("PASS " ++ mode ++ ": 128 seeded bars, key, timing, arrangement, " ++ total ++ " events; estimated peak voices " ++ peak).postln;
    };

    // EDM D is loaded after the shared A/ambient checks so those checks still
    // exercise the unmodified factory. Its factory is restored before B.
    standardFactory=~makeExperimentEngine;
    (root +/+ "d-engine.scd").load;
    (root +/+ "d-instruments.scd").load;
    assert.value(File.readAllString(root +/+ "d-edm.scd").compile.notNil, "D EDM entry point parse failed");
    {
        var d=~makeDExperimentEngine.value(\edm, 2600), copy=~makeDExperimentEngine.value(\edm, 2600);
        var voices=Set.new, total=0, vibrato=0, syncopated=0, texture=0, percussion=0;
        128.do {
            var events=d[\nextBar].value, other=copy[\nextBar].value, last=0;
            assert.value(events.asCompileString == other.asCompileString, "D is not reproducible");
            events.do { |event|
                assert.value((event.beat >= last) and: { event.beat < 4 }, "D event timing invalid");
                assert.value(event.track >= 0 and: { event.track <= 3 }, "D changed the four-lane contract");
                assert.value(event.duration > 0 and: { event.amp > 0 }, "D envelope or amplitude invalid");
                if(event.track < 3) {
                    assert.value(d.state.scale.includes((event.midinote - d.state.key) % 12), "D escaped the shared key");
                };
                if(event[\vibDepth].notNil) { vibrato=vibrato + 1 };
                if((event.voice == \xdBass) and: { ((event.beat * 4).round.asInteger % 4) == 3 }) { syncopated=syncopated + 1 };
                if(event.voice == \xdPad) { texture=texture + 1 };
                if([\xdGhost, \xdClap, \xdOpenHat].includes(event.voice)) { percussion=percussion + 1 };
                voices.add(event.voice); last=event.beat; total=total + 1;
            };
        };
        assert.value(total > 2400 and: { vibrato > 100 } and: { syncopated > 20 } and: { texture > 20 }, "D lacks its added lanes");
        assert.value(percussion > 40, "D lacks detailed percussion");
        ("PASS edmD: 128 seeded bars; syncopated bass; delayed vibrato; pad texture; ghost/clap/open-hat detail; " ++ total ++ " events").postln;
    }.value;
    ~makeExperimentEngine=standardFactory;

    {
        var aFactory=~makeExperimentEngine, a, b, copy, bassCount=0;
        (root +/+ "bite-engine.scd").load;
        (root +/+ "bite-instruments.scd").load;
        assert.value(File.readAllString(root +/+ "b-edm.scd").compile.notNil, "B EDM entry point parse failed");
        ~experimentDefs.do { |def| assert.value(def.asBytes.size > 0, "Invalid bite synth") };
        a=aFactory.value(\edm, 2600); b=~makeBiteEngine.value(\edm, 2600); copy=~makeBiteEngine.value(\edm, 2600);
        assert.value(b.busChannels == 6 and: { b.masterSynth == \xbMaster }, "B's dry bass routing not configured");
        128.do {
            var original=a[\nextBar].value, events=b[\nextBar].value, last=0;
            assert.value(events.asCompileString == copy[\nextBar].value.asCompileString, "B is not reproducible");
            events.do { |e|
                var message=~experimentMessage.value(e, b, 1000, 1, 16);
                var expected=if(e.track == 0, 20, if(e.track == 3, 18, 16));
                assert.value((e.beat >= last) and: { e.beat < 4 }, "B event timing invalid"); last=e.beat;
                assert.value(e.track >= 0 and: { e.track <= 3 }, "B added a fifth track");
                assert.value(message[6] == expected, "B audio bus routing invalid");
                if(e.track == 0) { assert.value(e.voice == \xbBass, "B did not use hard bass"); bassCount=bassCount + 1 };
                if((e.track < 3)) { assert.value(b.state.scale.includes((e.midinote - b.state.key) % 12), "B escaped the shared key") };
            };
            original.select { |e| e.track == 0 }.do { |old|
                var retained=events.detect { |e| (e.track == 0) and: { e.beat == old.beat } };
                assert.value(retained.notNil and: { retained.midinote == old.midinote }, "B discarded A's bass phrase");
            };
            assert.value(events.count { |e| e.track == 0 } <= (original.count { |e| e.track == 0 } + 1), "B added excessive bass notes");
        };
        [0, 1].do { |value|
            var extreme=~makeBiteEngine.value(\edm, 99, (chaos:value, density:value, mutation:value, tension:value));
            64.do { extreme[\nextBar].value.do { |e|
                assert.value((e.amp > 0) and: { e.amp <= 0.6 } and: { e.duration > 0 } and: { e.beat < 4 }, "B macro extremes invalid");
            } };
        };
        ("PASS bite: 128 seeded bars; four lanes; A's bass pitches retained; dry bass routing; " ++ bassCount ++ " bass events; macro extremes.").postln;
    }.value;
    0.exit;
} { |error| error.reportError; 1.exit };
)
