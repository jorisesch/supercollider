// Open this file in SuperCollider and evaluate the block.
(
var root = thisProcess.nowExecutingPath.dirname;
var defs = (root +/+ "instruments.scd").load;
var track = (root +/+ "track.scd").load.value;
var bus, group, mixer, playback, stop, stopped = false;

stop = {
    if(stopped.not) {
        stopped = true;
        if(playback.notNil) {
            if(thisThread != playback) { playback.stop };
            mixer.set(\gate, 0);
            SystemClock.sched(0.95, { group.free; bus.free; nil });
        };
    };
};

if(~stopVoltageHeart.notNil) { ~stopVoltageHeart.value };
~stopVoltageHeart = stop;
s.waitForBoot {
    defs.do { |def| def.send(s) };
    s.sync;
    if(stopped.not) {
        bus = Bus.audio(s, 10);
        group = Group.tail(s);
        mixer = Synth.tail(group, \vhMix, [\in,bus.index,\bpm,track[\bpm]]);
        playback = Routine {
            var previous = 0;
            track[\events].do { |event|
                var args = event[2].copy;
                (event[0] - previous).wait;
                previous = event[0];
                args[1] = bus.index + (args[1] - 16);
                s.sendBundle(s.latency, [\s_new,event[1],s.nextNodeID,0,group.nodeID] ++ args);
            };
            2.25.wait;
            stop.value;
        }.play(SystemClock);
        ~voltageHeartMixer = mixer;
    };
};
)
// While playing, evaluate ~voltageHeartMixer.set(\gain, 1.1) to lower the level.
// Evaluate ~stopVoltageHeart.value to fade and free this track.
