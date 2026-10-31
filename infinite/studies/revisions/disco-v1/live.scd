// Evaluate this file, then ~discoPlay.value. Loading alone does not boot or play.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "instruments.scd").load; (root +/+ "track.scd").load;
~discoStop={
    ~discoGeneration=(~discoGeneration ? 0)+1;
    if(~discoRoutine.notNil) { ~discoRoutine.stop; ~discoRoutine=nil };
    if(~discoClock.notNil) { ~discoClock.stop; ~discoClock=nil };
    if(~discoMaster.notNil) {
        var group=~discoGroup,bus=~discoBus;
        ~discoMaster.set(\gate,0); ~discoMaster=nil;
        SystemClock.sched(1.2,{ group.free; bus.free; nil });
    };
};
~discoPlay={ |server|
    var srv=server ? s,generation,events=~discoEvents.value;
    ~discoStop.value; generation=~discoGeneration;
    srv.waitForBoot({
        ~discoDefs.do { |def| def.send(srv) }; srv.sync;
        if(generation == ~discoGeneration) {
            var bus=Bus.audio(srv,6),group=Group.new(srv),master;
            master=Synth.tail(group,\discoMix,~discoMixArgs.value(bus.index));
            srv.sync;
            if(generation == ~discoGeneration) {
                ~discoBus=bus; ~discoGroup=group; ~discoMaster=master;
                ~discoClock=TempoClock.new(~discoSpec.bpm/60);
                ~discoRoutine=Routine {
                    var previous=0;
                    events.do { |event|
                        (event.beat-previous).wait; previous=event.beat;
                        srv.sendBundle(srv.latency,~discoMessage.value(event,-1,group.nodeID,bus.index));
                    };
                    (128-previous).wait;
                    SystemClock.sched(4,{ if(generation == ~discoGeneration) { ~discoStop.value }; nil });
                }.play(~discoClock,quant:4);
                "Coastal Pocket: playing 32 bars".postln;
            } { group.free; bus.free };
        };
    });
};
)
