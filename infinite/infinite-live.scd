// Load this entire file. It defines controls without starting playback.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "infinite-instruments.scd").load;
(root +/+ "infinite-engine.scd").load;
~infiniteSettings=~infiniteSettings ? (chaos:0.25, density:0.55, mutation:0.30, tension:0.20);
~stopInfinite = {
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
};
~fillInfinite = { if(~infiniteEngine.notNil) { ~infiniteEngine[\requestFill].value } };
~mutateInfinite = { if(~infiniteEngine.notNil) { ~infiniteEngine[\requestMutation].value } };
~holdInfinite = { |hold=true| if(~infiniteEngine.notNil) { ~infiniteEngine.controls.hold=hold } };
~startInfinite = { |mode=\edm, seed=2600, bpm, server|
    var engine=~makeInfiniteEngine.value(mode, seed, ~infiniteSettings);
    var generation, srv=server ? s;
    if(bpm.notNil) { engine.bpm=bpm.clip(40, 200) };
    ~stopInfinite.value;
    generation=~infiniteGeneration;
    ~infiniteEngine=engine;
    ~infiniteMode=mode; ~infiniteSeed=seed; ~infiniteBpm=engine.bpm; ~infiniteServer=srv;
    srv.waitForBoot {
        ~infiniteDefs.do { |def| def.send(srv) }; srv.sync;
        if(generation == ~infiniteGeneration) {
            var bus=Bus.audio(srv, 2), group=Group.new(srv), master, clock;
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
    };
};
)
