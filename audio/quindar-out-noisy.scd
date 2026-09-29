// quindar-out-noisy — select ALL and evaluate (Cmd+Return on macOS).
// Boots the default server if needed and plays the complete sound once.
// Cmd+. stops playback. No files, samples, or path setup required.
(
var server = Server.default;
var events, nodeIDs;
var instrument0 = SynthDef(\quindarRadio, { |out=0, freq=2525, amp=0.48, noise=0.9|
    var toneEnv, channelEnv, tone, bed, clicks, pops, popTimes, sig;
    var seed = \seed.ir(1962);
    var variant = \variant.ir(0);
    RandSeed.ir(1, seed);
    toneEnv = EnvGen.ar(Env([0, 0, 1, 1, 0], [0.18, 0.002, 0.246, 0.002]));
    channelEnv = EnvGen.ar(Env([0, 1, 1, 0], [0.008, 0.734, 0.008]), doneAction: 2);
    tone = SinOsc.ar(freq) * toneEnv * 0.37;
    bed = LPF.ar(PinkNoise.ar(0.018), 4200) + LPF.ar(BrownNoise.ar(0.012), 160);
    // Explicitly different scratch positions as well as different random seeds.
    popTimes = [0.042, 0.117, 0.283, 0.512, 0.641] + (variant * [0.023, 0.039, -0.042, 0.048, -0.067]);
    pops = Mix.fill(5, { |i|
        var hit = TDelay.ar(Impulse.ar(0), popTimes[i]);
        var tick = Decay2.ar(hit, 0.00008, 0.0018 + (i * 0.0005));
        var body = SinOsc.ar(900 + (i * 370) + (variant * 210)) * Decay2.ar(hit, 0.0001, 0.005);
        (tick * [1, -0.65, 0.8, -1, 0.55][i]) + (body * 0.22);
    });
    clicks = Dust2.ar(28 + (variant * 17), 0.75);
    sig = tone + ((bed + LPF.ar(pops * 0.5 + clicks, 9500)) * noise.clip(0, 1));
    sig = LeakDC.ar(sig).tanh * channelEnv * amp;
    Out.ar(out, sig ! 2);
});
events = [[0.05, [\s_new, \quindarRadio, 1000, 0, 0, \freq, 2475, \seed, 1969, \variant, 1]]];
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
        (0.9 - previous + server.latency).wait;
        group.free;
    }.play(SystemClock);
};
)
