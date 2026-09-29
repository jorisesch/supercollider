// quindar-in-out — select ALL and evaluate (Cmd+Return on macOS).
// Boots the default server if needed and plays the complete sound once.
// Cmd+. stops playback. No files, samples, or path setup required.
(
var server = Server.default;
var events, nodeIDs;
var instrument0 = SynthDef(\quindar, { |out=0, freq=2525, amp=0.22|
    // Total duration 250 ms; 2 ms edges suppress digital clicks.
    var env = EnvGen.ar(Env([0, 1, 1, 0], [0.002, 0.246, 0.002]), doneAction: 2);
    Out.ar(out, (SinOsc.ar(freq) * env * amp) ! 2);
});
events = [[0.05, [\s_new, \quindar, 1000, 0, 0, \freq, 2525]], [1.3, [\s_new, \quindar, 1001, 0, 0, \freq, 2475]]];
nodeIDs = IdentityDictionary.new;
server.waitForBoot {
    var group;
    instrument0.send(server);
    server.sync;
    group = Group.head(server);
    Routine {
        var previous = 0;
        events.do { |event|
            var message = event[1].copy;
            (event[0] - previous).wait;
            previous = event[0];
            if(message[0] == \s_new) {
                var localID = message[2];
                nodeIDs[localID] = server.nextNodeID;
                message[2] = nodeIDs[localID];
                message[4] = group.nodeID;
            } {
                message[1] = nodeIDs[message[1]];
            };
            server.sendBundle(server.latency, message);
        };
        (1.8 - previous + server.latency).wait;
        group.free;
    }.play(SystemClock);
};
)
