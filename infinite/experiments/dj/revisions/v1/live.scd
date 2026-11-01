// Load to define the DJ controls. This file starts no playback.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "engine.scd").load;
(root +/+ "instruments.scd").load;
~djSettings=~djSettings ? (chaos:0.25,density:0.60,mutation:0.25,tension:0.20,hold:false);
~djStop={
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
};
~djNext={ if(~djEngine.notNil) { ~djEngine[\requestNext].value } };
~djHook={ if(~djEngine.notNil) { ~djEngine[\requestHook].value } };
~djMutate={ if(~djEngine.notNil) { ~djEngine[\requestMutation].value } };
~djResume={ ~djStart.value(~djSeed ? 2600,~djInitialBpm ? 128,~djServer,true) };
~djStart={ |seed=2600,bpm=128,server,resume=false|
    var engine=if(resume and: { ~djEngine.notNil }) { ~djEngine } { ~makeDJEngine.value(seed,bpm) };
    var srv=server ? s, generation;
    ~djStop.value;
    ~djSeed=seed; ~djInitialBpm=bpm; ~djServer=srv; ~djEngine=engine;
    ~djBpm=engine.state.bpm;
    ~djSet.value;
    ~djPlaying=true; generation=~djGeneration;
    srv.waitForBoot({
        ~djDefs.do { |def| def.send(srv) }; srv.sync;
        if(generation == ~djGeneration) {
            var bus=Bus.audio(srv,14), group=Group.new(srv), sources, decks, master;
            sources=[Group.head(group),Group.head(group)];
            decks=Array.fill(2,{ |id| Synth.tail(group,\djDeck,[\in,bus.index+(id*6),\out,bus.index+12,
                \musicGain,0,\bassGain,0,\drumsGain,0,\bpm,engine.state.bpm]) });
            master=Synth.tail(group,\djMaster,[\in,bus.index+12,\attack,if(resume,3,0.1)]);
            srv.sync;
            if(generation == ~djGeneration) {
                ~djBus=bus; ~djGroup=group; ~djMaster=master;
                ~djDecks=decks; ~djSources=sources;
                ~djClock=TempoClock.new(engine.state.bpm / 60);
                ~djRoutine=Routine {
                    loop {
                        var frame=engine[\nextBar].value, actions=List.new, previous=0;
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
                                ~djBpm=a.bpm; ~djProgress=a.progress; ~djGains=a.gains;
                                srv.sendBundle(srv.latency,*Array.fill(2,{ |id|
                                    [\n_set,decks[id].nodeID,\musicGain,a.gains[id][0],
                                        \bassGain,a.gains[id][1],\drumsGain,a.gains[id][2],\bpm,a.bpm]
                                }));
                            } {
                                var event=action.note, deck=event.deck;
                                var offset=[2,0,0,4][event.lane];
                                srv.sendBundle(srv.latency,[\s_new,event.voice,-1,0,sources[deck].nodeID,
                                    \out,bus.index+(deck*6)+offset,\freq,event.midinote.midicps,
                                    \amp,event.amp,\sustain,event.duration*60/(~djBpm ? bpm),
                                    \pan,event.pan,\color,event.color,\tone,event.tone,\seed,event.seed]);
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
