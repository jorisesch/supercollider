// Load this file in the IDE, then ~studyPlay.value(1) through (5).
// Definitions and controls only; loading does not boot or play.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "instruments.scd").load; (root +/+ "tracks.scd").load;
~studyStop={
    ~studyGeneration=(~studyGeneration ? 0)+1;
    if(~studyRoutine.notNil) { ~studyRoutine.stop; ~studyRoutine=nil };
    if(~studyClock.notNil) { ~studyClock.stop; ~studyClock=nil };
    if(~studyMaster.notNil) {
        var group=~studyGroup,bus=~studyBus;
        ~studyMaster.set(\gate,0); ~studyMaster=nil;
        SystemClock.sched(1.2,{ group.free; bus.free; nil });
    };
};
~studyPlay={ |number=1,server|
    var spec=~studySpecs.at(number-1),srv=server ? s,generation,events;
    if(spec.isNil) { Error("Choose a study from 1 to 5").throw };
    events=~studyEvents.value(spec);
    ~studyStop.value; generation=~studyGeneration;
    srv.waitForBoot({
        ~studyDefs.do { |def| def.send(srv) }; srv.sync;
        if(generation == ~studyGeneration) {
            var bus=Bus.audio(srv,6),group=Group.new(srv),master;
            master=Synth.tail(group,\studyMix,~studyMixArgs.value(spec,bus.index));
            srv.sync;
            if(generation == ~studyGeneration) {
                ~studyBus=bus; ~studyGroup=group; ~studyMaster=master;
                ~studyClock=TempoClock.new(spec.bpm/60);
                ~studyRoutine=Routine {
                    var previous=0;
                    events.do { |event|
                        (event.beat-previous).wait; previous=event.beat;
                        srv.sendBundle(srv.latency,~studyMessage.value(event,spec,-1,group.nodeID,bus.index));
                    };
                    (128-previous).wait;
                    SystemClock.sched(4,{ if(generation == ~studyGeneration) { ~studyStop.value }; nil });
                }.play(~studyClock,quant:4);
                ("Playing study " ++ number ++ ": " ++ spec.title).postln;
            } { group.free; bus.free };
        };
    });
};
)
