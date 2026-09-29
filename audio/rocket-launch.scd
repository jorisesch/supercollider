// rocket-launch — select ALL and evaluate (Cmd+Return on macOS).
// Boots the default server if needed and plays the complete sound once.
// Cmd+. stops playback. No files, samples, or path setup required.
(
var server = Server.default;
var events, nodeIDs;
var instrument0 = SynthDef(\rocketEngine, { |out=0, gate=1, amp=0.65, throttle=0.5, grit=0.65, pan=0,
    motion=0.12, cycle=6, malfunction=0, sand=0.28|
    var speed, rpm, sweep, fault, dropout, engines, sub, turbine, air, sputter, sig, env;
    RandSeed.ir(1, 1977);
    // Slow irregular load drift; no periodic melodic pitch movement.
    speed = (Lag.kr(throttle.clip(0, 1), 0.8)
        + (LFNoise2.kr(cycle.clip(3, 12).reciprocal) * motion.clip(0, 0.45))).clip(0.05, 1);
    fault = Lag.kr(malfunction.clip(0, 1), 0.12);
    rpm = speed.linexp(0, 1, 25, 82);
    // Three unequal startup surges; the last decays to zero by 4.2 seconds.
    // No repeating trigger remains once the engine settles.
    sweep = EnvGen.kr(Env(
        [0, 0.8, 0.05, 0.55, 0.02, 0.3, 0],
        [0.18, 0.63, 0.29, 1.03, 0.34, 1.73],
        [-2, -3, -2, -3, -2, -3]
    ));
    dropout = 1 - (fault * LFPulse.kr(11 + LFNoise1.kr(3, 4), 0, 0.62) * 0.96);
    engines = Mix.fill(2, { |i|
        var damage = fault * [1, 0.35][i];
        var motor = LPF.ar(BrownNoise.ar(1.2), 180 + (speed * 260))
            + BPF.ar(PinkNoise.ar(0.7), 110 + (speed * 210), 1.1);
        motor = motor * (0.65 + (sweep * 0.7)) * LFNoise2.kr(7).range(0.9, 1)
            * (1 - damage + (damage * dropout));
        Pan2.ar(motor, [-0.55, 0.55][i]);
    });
    sub = LPF.ar(BrownNoise.ar(0.55), 85) * (0.35 + sweep) * (1 - (fault * 0.5));
    turbine = LPF.ar(PinkNoise.ar(0.10), 180 + (rpm * 2)) * (0.3 + speed) * dropout;
    // Sand ingestion: continuous coarse rasp plus irregular grain impacts.
    air = HPF.ar(LPF.ar(PinkNoise.ar(0.7 ! 2), 650 + (speed * 950)), 170);
    air = air + (BPF.ar(WhiteNoise.ar(0.4 ! 2), 450 + (speed * 650), 1.2)
        * Decay2.ar(Dust.ar(120 + (speed * 240)), 0.0003, 0.009));
    air = air * sand.clip(0, 1.5) * (0.45 + (sweep * 0.65))
        * LFNoise2.kr(6).range(0.85, 1) * (0.15 + (dropout * 0.85));
    sputter = BPF.ar(WhiteNoise.ar(1.1), 750, 1.1)
        * Decay2.ar(Impulse.ar(13), 0.001, 0.035) * fault;
    sig = engines + (sub ! 2) + (turbine ! 2) + air + (sputter ! 2);
    sig = (sig * (1.5 + grit.clip(0, 1))).tanh * 0.75;
    // No resonant delay: keep the engine dry, coarse, and non-musical.
    sig = Balance2.ar(sig[0], sig[1], Lag.kr(pan.clip(-1, 1), 0.4));
    env = EnvGen.kr(Env.asr(0.8, 1, 2.5), gate, doneAction: 2);
    Out.ar(out, Limiter.ar(LeakDC.ar(sig) * env * amp, 0.88));
});
var instrument1 = SynthDef(\launchBeep, { |out=0, freq=880, dur=0.12, amp=0.16|
    var env = EnvGen.ar(Env.linen(0.004, (dur - 0.012).max(0.01), 0.008), doneAction: 2);
    Out.ar(out, (SinOsc.ar(freq) * env * amp) ! 2);
});
events = [
    [0.1, [\s_new, \launchBeep, 1100, 0, 0]],
    [1.1, [\s_new, \launchBeep, 1101, 0, 0]],
    [2.1, [\s_new, \launchBeep, 1102, 0, 0]],
    [3.1, [\s_new, \launchBeep, 1103, 0, 0]],
    [4.1, [\s_new, \launchBeep, 1104, 0, 0]],
    [5.1, [\s_new, \launchBeep, 1105, 0, 0, \freq, 1320, \dur, 0.35]],
    [5.1, [\s_new, \rocketEngine, 1000, 0, 0, \throttle, 0.45]],
    [11.0, [\n_set, 1000, \throttle, 0.62]],
    [17.0, [\n_set, 1000, \throttle, 0.5]],
    [20.0, [\n_set, 1000, \malfunction, 0.95]],
    [22.0, [\n_set, 1000, \malfunction, 0.55, \throttle, 0.3]],
    [24.0, [\n_set, 1000, \malfunction, 0, \throttle, 0.8]],
    [30.0, [\n_set, 1000, \throttle, 0.5]],
    [34.0, [\n_set, 1000, \malfunction, 0.7]],
    [35.2, [\n_set, 1000, \malfunction, 0, \throttle, 0.72]],
    [39.0, [\n_set, 1000, \gate, 0]]
];
nodeIDs = IdentityDictionary.new;
server.waitForBoot {
    var group;
    instrument0.send(server); instrument1.send(server);
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
        (43 - previous + server.latency).wait;
        group.free;
    }.play(SystemClock);
};
)
