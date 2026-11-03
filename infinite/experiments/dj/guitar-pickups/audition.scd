// Load in SuperCollider, then call ~hpAudition.value(1, false).
// The audition owns only its own group and buses. It never quits the server.
(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname,library=Environment.new,defs;
var generation=0,resources,routine,stop;
~hpAuditionStop.value;
library.use {
    (dj+/+"instruments.scd").load;(dj+/+"guitar-contact/contact.scd").load;
    (dj+/+"guitar-contact/performance.scd").load;
    (root+/+"model.scd").load;(root+/+"instruments.scd").load;
    defs=~hpDefs++[SynthDef(\hpAuditionFade,{|in=16,gate=1|
        Out.ar(0,In.ar(in,2)*EnvGen.kr(Env.asr(0.015,1,0.08),gate,doneAction:2));
    })];
};
stop={
    generation=generation+1;routine.tryPerform(\stop);routine=nil;
    if(resources.notNil){
        var old=resources;resources=nil;old[\fade].set(\gate,0);
        SystemClock.sched(0.12,{old[\group].free;old[\bus].free;nil});
    };
};
~hpAuditionStop=stop;
~hpAudition={|preset=1,drive=false,server|
    var srv=server ? s,id=preset.asInteger.clip(0,4),request,events;
    stop.value;request=generation;
    events=library.use {
        var config=~hpPresets[id][\config];
        ~gcStroke.value([[0,40],[1,47],[2,54],[3,56],[4,59],[5,64]],0.1,\down,\hard,1.4,1.6).collect {|e|
            [e[\at],[\freq,e[\note].midicps,\stringIndex,e[\string],\amp,0.55,\sustain,e[\hold]]
                ++~gcArgs.value(~hpInitial.value(e[\initial],config))]
        };
    };
    srv.waitForBoot {
        if(request==generation){
            defs.do {|def|def.send(srv)};srv.sync;
            if(request==generation){
                var bus=Bus.audio(srv,6),group=Group(srv),fade;
                Synth.tail(group,("hpPickup"++id).asSymbol,[\in,bus.index,\out,bus.index+2]);
                Synth.tail(group,if(drive){\hpDrive}{\hpClean},[\in,bus.index+2,\out,bus.index+4]);
                fade=Synth.tail(group,\hpAuditionFade,[\in,bus.index+4]);
                resources=(group:group,bus:bus,fade:fade);srv.sync;
                if(request==generation){routine=Routine {
                    var previous=0;
                    events.do {|event|
                        (event[0]-previous).wait;previous=event[0];
                        srv.sendMsg(*([\s_new,\hpString,-1,0,group.nodeID,\out,bus.index]++event[1]));
                    };
                    2.wait;routine=nil;stop.value;
                }.play(SystemClock)};
            };
        };
    };
};
)
