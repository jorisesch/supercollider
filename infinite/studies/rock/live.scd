// Load this file to define playback controls. Loading alone starts no music.
(
var root=thisProcess.nowExecutingPath.dirname;
(root+/+"instruments.scd").load;(root+/+"tracks.scd").load;
~rockStop={
    ~rockGeneration=(~rockGeneration ? 0)+1;
    if(~rockRoutine.notNil){~rockRoutine.stop;~rockRoutine=nil};
    if(~rockMaster.notNil){
        var oldGroup=~rockGroup,oldBus=~rockBus;
        ~rockMaster.set(\gate,0);~rockMaster=nil;
        SystemClock.sched(1.6,{oldGroup.free;oldBus.free;nil});
    };
};
~rockPlay={ |id=\ironwood,server,effects=true|
    var spec=~rockSpecs.detect {|item|item.id==id.asSymbol},srv=server ? s,generation;
    if(spec.isNil){Error("Choose ironwood, greenroom or openroad").throw};
    ~rockStop.value;generation=~rockGeneration;
    srv.waitForBoot {
        ~rockDefs.do {|def|def.send(srv)};srv.sync;
        if(generation==~rockGeneration){
            var bus=Bus.audio(srv,6),group=Group.new(srv),source,master;
            srv.sync;source=Group.head(group);
            master=Synth.tail(group,\rkMix,[\in,bus.index]);srv.sync;
            if(generation==~rockGeneration){
                ~rockBus=bus;~rockGroup=group;~rockMaster=master;
                ~rockRoutine=Routine {
                    var previous=0;
                    ("Playing "++spec.title++" / "++spec.scaleName++" / "++spec.bpm++" BPM").postln;
                    ~rockEvents.value(spec,731,effects).do {|event|
                        ((event.beat-previous)*60/spec.bpm).wait;previous=event.beat;
                        srv.sendBundle(srv.latency,~rockMessage.value(event,-1,source.nodeID,bus.index,spec.bpm));
                    };
                    2.5.wait;
                    // Clear the completed routine before cleanup, so Stop cannot
                    // halt its own thread before releasing the mix and bus.
                    ~rockRoutine=nil;
                    if(generation==~rockGeneration){~rockStop.value};
                }.play(SystemClock);
            } {group.free;bus.free};
        };
    };
};
)
// Examples (evaluate individually after loading the file):
// ~rockPlay.value(\ironwood);
// ~rockPlay.value(\greenroom);
// ~rockPlay.value(\openroad);
// ~rockMaster.set(\amp,0.7);
// ~rockStop.value;
