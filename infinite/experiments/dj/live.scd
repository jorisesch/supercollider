// Load to define the DJ controls. This file starts no playback.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "engine.scd").load;
(root +/+ "instruments.scd").load;
(root +/+ "recall.scd").load;
~djSettings=~djSettings ? (chaos:0.25,density:0.55,mutation:0.30,tension:0.20,hold:false);
~djSettings.autoStutter=~djSettings[\autoStutter] ? true;
~djStutterBars=~djStutterBars ? 0.5;
~djSettings.channel=~djSettings[\channel] ? \edme;
~djLastFX=\none;
~djLastFXLabel="none";
~djManualFX=nil;
~djWithoutManual={ |point|
    var clean=point.copy;
    clean.fx=point.fx.collect { |fx| fx[\base] ? fx };
    clean;
};
~djFXStop={ |post=true|
    ~djManualFX=nil;
    if(~djEngine.notNil) {~djEngine[\stopFX].value};
    if(~djLastAutomation.notNil and: {~djDecks.notNil} and: {~djServer.notNil} and: {~djServer.serverRunning}) {
        ~djServer.sendBundle(~djServer.latency,
            *~djAutomation.value(~djWithoutManual.value(~djLastAutomation),~djDecks.collect(_.nodeID)));
    };
    if(post) {"DJ effect stopped / releasing now".postln};
};
~djFXStart={ |kind=\echo|
    if(~djEngine.notNil and: {~djPlaying ? false}) {
        ~djManualFX=kind;
        ~djEngine[\startFX].value(kind);
        ("DJ effect queued / " ++ kind ++ " / next bar, until Stop FX").postln;
    } {"DJ effect ignored / music is stopped".postln};
};
~djStop={
    if(~djManualFX.notNil) {~djFXStop.value(false)};
    ~djPlaying=false; ~djGeneration=(~djGeneration ? 0) + 1;
    if(~djRoutine.notNil) { ~djRoutine.stop; ~djRoutine=nil };
    if(~djClock.notNil) { ~djClock.stop; ~djClock=nil };
    if(~djMaster.notNil) {
        var oldGroup=~djGroup, oldBus=~djBus;
        ~djMaster.set(\gate,0); ~djMaster=nil;
        SystemClock.sched(3.2,{ oldGroup.free; oldBus.free; nil });
    };
};
~djSet={ |chaos,density,mutation,tension|
    [\chaos,\density,\mutation,\tension].do { |key,i|
        var value=[chaos,density,mutation,tension][i];
        if(value.notNil) { ~djSettings[key]=value.clip(0,1) };
    };
    if(~djEngine.notNil) { ~djSettings.keysValuesDo { |key,value| ~djEngine.controls[key]=value } };
};
~djHold={ |hold=true|
    ~djSettings.hold=hold;
    if(~djEngine.notNil) { ~djEngine.controls.hold=hold };
    ("DJ Hold record: " ++ hold).postln;
};
~djNext={ if(~djEngine.notNil) { ~djEngine[\requestNext].value; "DJ NEXT queued / next four-bar boundary".postln } };
~djHook={ if(~djEngine.notNil) { ~djEngine[\requestHook].value; if(~djSettings.channel==\pop) {"DJ Chorus queued / four bars from next bar"} {"DJ Bass hook queued / four bars from next bar"}.postln } };
~djMutate={ if(~djEngine.notNil) { ~djEngine[\requestMutation].value;
    if(~djSettings.hold) {"DJ Mutation ignored / record held"} {"DJ Mutation queued / next bar"}.postln } };
~djFill={ if(~djEngine.notNil) { ~djEngine[\requestFill].value; "DJ Fill queued / next bar".postln } };
~djAutoStutter={ |enabled=true|
    ~djSettings.autoStutter=enabled;
    if(~djEngine.notNil) {~djEngine.controls.autoStutter=enabled};
    ("DJ Auto stutter: " ++ enabled ++ " / next bar").postln;
};
~djHot={ |kind,bars=1|
    var name=kind.asSymbol,label,length=if(bars<1) {0.5} {bars.asInteger.clip(1,4)};
    label=switch(name,
        \stutter4, {"STUTTER 1/4"}, \stutter8, {"STUTTER 1/8"},
        \stutter16, {"STUTTER 1/16"}, \stutter, {"STUTTER 1/16"},
        {name.asString.toUpper});
    if(~djEngine.notNil and: { ~djPlaying ? false }) {
        ~djLastFX=name; ~djLastFXLabel=label; ~djEngine[\requestFX].value(name,length);
        ("DJ hot FX queued for next bar: " ++ label ++ " / " ++
            if(length==0.5) {"last half-bar"} {length.asString ++ if(length==1) {" bar"} {" bars"}}).postln;
    } {
        "DJ hot FX ignored: DJ is stopped".postln;
    };
};
~djFilter={ ~djHot.value(\filter) };
~djEcho={ ~djHot.value(\echo) };
~djWash={ ~djHot.value(\wash) };
~djStutter={ |division=16,bars|
    if([4,8,16].includes(division).not) {Error("Stutter division must be 4, 8 or 16").throw};
    ~djHot.value(("stutter" ++ division.asInteger).asSymbol,bars ? ~djStutterBars);
};
~djChannel={ |channel=\edme|
    if([\edm,\pop,\edme].includes(channel).not) {Error("DJ channel must be edm, pop or edme").throw};
    ~djSettings.channel=channel;
    ("DJ channel: "++channel++" / restarting set with fade").postln;
    ~djStart.value(~djSeed ? 2600,if(channel==\pop){138}{128},~djServer);
};
~djResume={ ~djStart.value(~djSeed ? 2600,~djInitialBpm ? 128,~djServer,true) };
~djRecall={ |name|
    var spec=~djReadRecipe.value(name),engine=~djSessionFromRecipe.value(spec);
    ~djSettings=engine.controls.copy;~djSettings.channel=engine.channel;
    ~djStart.value(spec[2].asInteger,spec[3].asFloat,~djServer,false,engine);
    ("DJ recall / " ++ name ++ " / original entry").postln;
};
~djStart={ |seed=2600,bpm=128,server,resume=false,prepared|
    var engine=prepared ? if(resume and: { ~djEngine.notNil }) { ~djEngine } { ~makeDJSession.value(seed,bpm,~djSettings) };
    var srv=server ? s, generation;
    ~djStop.value;
    ~djSeed=seed; ~djInitialBpm=bpm; ~djServer=srv; ~djEngine=engine;
    ~djLastAutomation=nil;
    ~djBpm=engine.state.bpm;
    ~djSet.value;
    ~djPlaying=true; generation=~djGeneration;
    srv.waitForBoot({
        ~djDefs.do { |def| def.send(srv) }; srv.sync;
        if(generation == ~djGeneration) {
            var bus=Bus.audio(srv,14), group=Group.new(srv), sources, decks, master;
            sources=[Group.head(group),Group.head(group)];
            decks=Array.fill(2,{ |id| Synth.tail(group,\djDeck,[\in,bus.index+(id*6),\out,bus.index+12,
                \musicGain,0,\bassGain,0,\drumsGain,0,\bpm,engine.state.bpm,\fxFilter,0,
                \fxCutoff,12000,\fxResonance,0.35,\fxEcho,0,\fxDelay,0.33,\fxReverb,0.14,\fxStutter,0]) });
            master=Synth.tail(group,\djMaster,[\in,bus.index+12,\attack,if(resume,3,0.1)]);
            srv.sync;
            if(generation == ~djGeneration) {
                ~djBus=bus; ~djGroup=group; ~djMaster=master;
                ~djDecks=decks; ~djSources=sources;
                ~djClock=TempoClock.new(engine.state.bpm / 60);
                ~djRoutine=Routine {
                    var announced=Set.new,firstBar=true;
                    loop {
                        var frame=engine[\nextBar].value, actions=List.new, previous=0;
                        if(firstBar) {
                            // Resume a running long gate once; half-bar hits reset at beat two.
                            frame.automation[0].fx.do { |fx| if(fx.stutter>0) {fx.stutterReset=true} };
                            firstBar=false;
                        };
                        frame.decks.do { |plan|
                            if(plan.notNil and: {announced.includes(plan.serial).not}) {
                                ("DJ track / " ++ plan.trackName ++ " / " ++ plan.palette.name ++
                                    " / " ++ plan.palette.bassName ++ " + " ++ plan.palette.leadName ++
                                    " / " ++ plan.palette.kitName).postln;
                                announced.add(plan.serial);
                            };
                        };
                        if(frame.stutter.notNil and: {frame.stutter.age==0}) {
                            var fx=frame.stutter;
                            ("DJ " ++ fx[\source] ++ " stutter / 1/" ++ fx.division ++ " / " ++ fx.bars ++
                                " bars / deck " ++ if(fx.deck==0) {"A"} {"B"}).postln;
                        };
                        frame.automation.do { |event| actions.add((beat:event.beat,automation:event)) };
                        frame.events.do { |event| actions.add((beat:event.beat,note:event)) };
                        actions=actions.sort { |a,b|
                            if(a.beat == b.beat) { a[\automation].notNil and: { b[\automation].isNil } } { a.beat < b.beat }
                        };
                        actions.do { |action|
                            (action.beat-previous).wait; previous=action.beat;
                            if(action[\automation].notNil) {
                                var a=action.automation;
                                ~djClock.tempo=a.bpm / 60;
                                ~djBpm=a.bpm; ~djProgress=a.progress; ~djGains=a.gains; ~djFxState=a.fx;
                                ~djLastAutomation=a;
                                // Stop FX also bypasses the rest of this already-generated bar.
                                if(a.fx.any { |fx| fx[\manualKind].notNil and: {fx[\manualKind]!=~djManualFX} }) {
                                    a=~djWithoutManual.value(a);
                                };
                                ~djFxState=a.fx;
                                srv.sendBundle(srv.latency,*~djAutomation.value(a,decks.collect(_.nodeID)));
                            } {
                                var event=action.note, deck=event.deck;
                                srv.sendBundle(srv.latency,~djMessage.value(event,-1,sources[deck].nodeID,bus.index,~djBpm ? bpm));
                            };
                        };
                        (4-previous).max(0).wait;
                    };
                }.play(~djClock,quant:4);
            } { group.free; bus.free };
        };
    },onFailure:{ if(generation == ~djGeneration) { ~djPlaying=false } });
};
)
