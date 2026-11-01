// Evaluate this whole block to play the arrangement on the default server.
(
var root=thisProcess.nowExecutingPath.dirname;
(root+/+"instruments.scd").load;
(root+/+"track.scd").load;
s.waitForBoot {
    ~neonDefs.do(_.send(s));
    s.sync;
    ~neonGroup=Group.new(s);
    s.sync;
    ~neonPlayback=Routine {
        var previous=0;
        ~neonScore.value.do { |event|
            (event[0]-previous).wait;
            previous=event[0];
            event.copyRange(1,event.size-1).do { |message|
                if(message[0]==\s_new) {
                    message=message.copy;
                    message[4]=~neonGroup.nodeID;
                    s.sendBundle(nil,message);
                };
            };
        };
        1.wait; ~neonGroup.free;
    }.play(SystemClock);
};
)
// Master level while playing:
// s.sendMsg(\n_set, 900, \amp, 0.6);
// Graceful stop (evaluate this line):
// ~neonPlayback.stop; s.sendMsg(\n_set, 900, \amp, 0); SystemClock.sched(0.2, { ~neonGroup.free; nil });
