// Load this entire file. It defines controls without starting playback.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "infinite-instruments.scd").load;
(root +/+ "infinite-engine.scd").load;
~infiniteSettings=~infiniteSettings ? (chaos:0.25, density:0.55, mutation:0.30, tension:0.20);
~stopInfinite = {
    ~infinitePlaying=false;
    ~infiniteGeneration=(~infiniteGeneration ? 0) + 1;
    if(~infiniteRoutine.notNil) { ~infiniteRoutine.stop; ~infiniteRoutine=nil };
    if(~infiniteClock.notNil) { ~infiniteClock.stop; ~infiniteClock=nil };
    if(~infiniteMaster.notNil) {
        var oldGroup=~infiniteGroup, oldBus=~infiniteBus;
        ~infiniteMaster.set(\gate, 0);
        SystemClock.sched(3.2, { oldGroup.free; oldBus.free; nil });
        ~infiniteMaster=nil;
    };
};
~setInfinite = { |chaos, density, mutation, tension|
    [\chaos, \density, \mutation, \tension].do { |key, i|
        var value=[chaos, density, mutation, tension][i];
        if(value.notNil) { ~infiniteSettings[key]=value.clip(0, 1) };
    };
    if(~infiniteEngine.notNil) {
        ~infiniteSettings.keysValuesDo { |key, value| ~infiniteEngine.controls[key]=value };
    };
    ("Infinite controls: chaos " ++ (~infiniteSettings.chaos * 100).round.asInteger ++ "%, density "
        ++ (~infiniteSettings.density * 100).round.asInteger ++ "%, mutation "
        ++ (~infiniteSettings.mutation * 100).round.asInteger ++ "%, tension "
        ++ (~infiniteSettings.tension * 100).round.asInteger).postln;
};
~fillInfinite = {
    if(~infiniteEngine.notNil) {
        ~infiniteEngine[\requestFill].value;
        "Infinite: fill requested; it will enter on the next bar.".postln;
    } { "Infinite: fill ignored; engine is not running.".postln };
};
~mutateInfinite = {
    if(~infiniteEngine.notNil) {
        ~infiniteEngine[\requestMutation].value;
        "Infinite: mutation requested; it will enter on the next bar.".postln;
    } { "Infinite: mutation ignored; engine is not running.".postln };
};
~holdInfinite = { |hold=true|
    ~infiniteSettings.hold=hold;
    if(~infiniteEngine.notNil) {
        ~infiniteEngine.controls.hold=hold;
        ("Infinite: motifs " ++ if(hold, "held.", "released.")).postln;
    } { "Infinite: hold changed before the engine started.".postln };
};
// Continue the retained composition at its next bar; Restart seed still creates a new engine.
~resumeInfinite = {
    ~startInfinite.value(~infiniteMode ? \edm, ~infiniteSeed ? 2600,
        ~infiniteBpm, ~infiniteServer, true);
};
~startInfinite = { |mode=\edm, seed=2600, bpm, server, resume=false|
    var engine=if(resume and: { ~infiniteEngine.notNil }) { ~infiniteEngine } {
        ~makeInfiniteEngine.value(mode, seed, ~infiniteSettings)
    };
    var generation, srv=server ? s;
    if(bpm.notNil) { engine.bpm=bpm.clip(40, 200) };
    ~stopInfinite.value;
    generation=~infiniteGeneration;
    ~infinitePlaying=true;
    ~infiniteEngine=engine;
    ~infiniteMode=mode; ~infiniteSeed=seed; ~infiniteBpm=engine.bpm; ~infiniteServer=srv;
    srv.waitForBoot({
        ~infiniteDefs.do { |def| def.send(srv) }; srv.sync;
        if(generation == ~infiniteGeneration) {
            var bus=Bus.audio(srv, 2), group=Group.new(srv), master, clock;
            // Group.new sends /g_new asynchronously; register it before /s_new or notes race the group.
            srv.sync;
            master=Synth.tail(group, \igMaster, [\in, bus]);
            srv.sync;
            // The generation can change while sync yields.
            if(generation == ~infiniteGeneration) {
                ~infiniteBus=bus; ~infiniteGroup=group; ~infiniteMaster=master;
                clock=TempoClock.new(engine.bpm / 60); ~infiniteClock=clock;
                ~infiniteRoutine=Routine {
                    loop {
                        var previous=0;
                        engine[\nextBar].value.do { |event|
                            (event.beat - previous).wait;
                            srv.sendBundle(srv.latency, ~infiniteMessage.value(event, engine, -1, group.nodeID, bus.index));
                            previous=event.beat;
                        };
                        (4 - previous).wait;
                    };
                }.play(clock, quant:4);
                ("Infinite " ++ mode ++ " | " ++ engine.bpm ++ " BPM | seed " ++ seed).postln;
            } { group.free; bus.free };
        };
    }, onFailure: {
        if(generation == ~infiniteGeneration) { ~infinitePlaying=false };
    });
};
)
