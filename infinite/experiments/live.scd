// Load this entire file. It defines controls without starting playback.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "instruments.scd").load;
(root +/+ "engine.scd").load;
~experimentSettings=~experimentSettings ? (chaos:0.25, density:0.55, mutation:0.30, tension:0.20);
~stopExperiment = {
    ~experimentPlaying=false;
    ~experimentGeneration=(~experimentGeneration ? 0) + 1;
    if(~experimentRoutine.notNil) { ~experimentRoutine.stop; ~experimentRoutine=nil };
    if(~experimentClock.notNil) { ~experimentClock.stop; ~experimentClock=nil };
    if(~experimentMaster.notNil) {
        var oldGroup=~experimentGroup, oldBus=~experimentBus, fade=~experimentFade ? 5;
        ~experimentMaster.set(\gate, 0);
        SystemClock.sched(fade + 0.2, { oldGroup.free; oldBus.free; nil });
        ~experimentMaster=nil;
    };
};
~setExperiment = { |chaos, density, mutation, tension|
    [\chaos, \density, \mutation, \tension].do { |key, i|
        var value=[chaos, density, mutation, tension][i];
        if(value.notNil) { ~experimentSettings[key]=value.clip(0, 1) };
    };
    if(~experimentEngine.notNil) {
        ~experimentSettings.keysValuesDo { |key, value| ~experimentEngine.controls[key]=value };
    };
    ("Experiment controls: chaos " ++ ((~experimentSettings.chaos * 100).round.asInteger)
        ++ "%, density " ++ ((~experimentSettings.density * 100).round.asInteger)
        ++ "%, mutation " ++ ((~experimentSettings.mutation * 100).round.asInteger)
        ++ "%, tension " ++ ((~experimentSettings.tension * 100).round.asInteger) ++ "%").postln;
};
~fillExperiment = {
    if(~experimentEngine.notNil) {
        ~experimentEngine[\requestFill].value;
        "Experiment: fill requested; it will enter on the next bar.".postln;
    } { "Experiment: fill ignored; engine is not running.".postln };
};
~mutateExperiment = {
    if(~experimentEngine.notNil) {
        ~experimentEngine[\requestMutation].value;
        "Experiment: mutation requested; it will enter on the next bar.".postln;
    } { "Experiment: mutation ignored; engine is not running.".postln };
};
~holdExperiment = { |hold=true|
    if(~experimentEngine.notNil) {
        ~experimentEngine.controls.hold=hold;
        ("Experiment: motifs " ++ if(hold, "held.", "released.")).postln;
    } { "Experiment: hold changed before the engine started.".postln };
};
// Continue the retained composition at its next bar; Restart seed still creates a new engine.
~resumeExperiment = {
    "Experiment: START requested; continuing at the next bar.".postln;
    ~startExperiment.value(~experimentMode ? \edm, ~experimentSeed ? 2600,
        ~experimentBpm, ~experimentServer, true);
};
~startExperiment = { |mode=\edm, seed=2600, bpm, server, resume=false|
    var engine=if(resume and: { ~experimentEngine.notNil }) { ~experimentEngine } {
        ~makeExperimentEngine.value(mode, seed, ~experimentSettings)
    };
    var generation, srv=server ? s, label;
    if(bpm.notNil) { engine.bpm=bpm.clip(40, 200) };
    ~stopExperiment.value;
    generation=~experimentGeneration;
    ~experimentPlaying=true;
    ~experimentEngine=engine; ~experimentFade=if(mode == \edm, 5, 8);
    ~experimentMode=mode; ~experimentSeed=seed; ~experimentBpm=engine.bpm; ~experimentServer=srv;
    label=if(engine[\profile] == \d, "edmD", mode);
    srv.waitForBoot({
        ~experimentDefs.do { |def| def.send(srv) }; srv.sync;
        if(generation == ~experimentGeneration) {
            var bus=Bus.audio(srv, engine[\busChannels] ? 4), group=Group.new(srv), master, clock;
            master=Synth.tail(group, engine[\masterSynth] ? \xpMaster, [\in, bus, \bpm, engine.bpm,
                \ambient, if(mode == \soundscape, 1, 0), \fade, ~experimentFade]);
            srv.sync;
            // The generation can change while sync yields.
            if(generation == ~experimentGeneration) {
                ~experimentBus=bus; ~experimentGroup=group; ~experimentMaster=master;
                clock=TempoClock.new(engine.bpm / 60); ~experimentClock=clock;
                ~experimentRoutine=Routine {
                    loop {
                        var previous=0;
                        engine[\nextBar].value.do { |event|
                            (event.beat - previous).wait;
                            srv.sendBundle(srv.latency, ~experimentMessage.value(event, engine, -1, group.nodeID, bus.index));
                            previous=event.beat;
                        };
                        (4 - previous).wait;
                    };
                }.play(clock, quant:4);
                ("Experiment " ++ label ++ " | " ++ engine.bpm ++ " BPM | seed " ++ seed).postln;
            } { group.free; bus.free };
        };
    }, onFailure: {
        if(generation == ~experimentGeneration) { ~experimentPlaying=false };
    });
};
)
