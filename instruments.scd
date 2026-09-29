(
~quindarDef = SynthDef(\quindar, { |out=0, freq=2525, amp=0.22|
    // Total duration 250 ms; 2 ms edges suppress digital clicks.
    var env = EnvGen.ar(Env([0, 1, 1, 0], [0.002, 0.246, 0.002]), doneAction: 2);
    Out.ar(out, (SinOsc.ar(freq) * env * amp) ! 2);
});

// Stylized mono radio channel: hiss, tiny static bursts, flutter, and saturation.
~quindarRadioDef = SynthDef(\quindarRadio, { |out=0, freq=2525, amp=0.32, noise=0.7, seed=1962|
    var toneEnv, channelEnv, flutter, tone, hiss, speckles, sig;
    RandSeed.ir(1, seed);
    // The tone starts 80 ms into the radio channel and lasts exactly 250 ms.
    toneEnv = EnvGen.ar(Env([0, 0, 1, 1, 0], [0.08, 0.002, 0.246, 0.002]));
    channelEnv = EnvGen.ar(Env([0, 1, 1, 0], [0.012, 0.426, 0.012]), doneAction: 2);
    flutter = LFNoise2.kr(37).range(0.82, 1);
    tone = SinOsc.ar(freq) * toneEnv * flutter * 0.6;
    hiss = WhiteNoise.ar(0.11) + PinkNoise.ar(0.05);
    speckles = WhiteNoise.ar(0.9) * Decay2.ar(Dust.ar(95), 0.0002, 0.0025);
    sig = tone + ((hiss + speckles) * noise.clip(0, 1));
    sig = LPF.ar(HPF.ar((sig * 1.8).tanh, 320), 3400);
    sig = LeakDC.ar(sig) * channelEnv * amp;
    Out.ar(out, sig ! 2);
});

~racerDef = SynthDef(\desertRacer, { |out=0, gate=1, amp=0.5, throttle=0.25, grit=0.55, pan=0|
    var t, rpm, engines, sub, turbine, sand, arc, sig, env;
    RandSeed.ir(1, 1977);
    t = Lag.kr(throttle.clip(0, 1), 1.4);
    rpm = (38 + (t * 76)) * (1 + LFNoise2.kr(0.65, 0.018));
    // Two uneven combustion pods, with beating and asymmetric firing.
    engines = Mix.fill(2, { |i|
        var f = rpm * [0.993, 1.007][i];
        var firing = LFPulse.ar(f * 0.49, i * 0.31, 0.24).range(0.38, 1);
        var body = VarSaw.ar(f * [1, 2.003, 3.01], 0, [0.32, 0.47, 0.61], [0.23, 0.10, 0.05]).sum;
        Pan2.ar(RLPF.ar(body * firing, 380 + (t * 2200), 0.36), [-0.48, 0.48][i]);
    });
    sub = SinOsc.ar(rpm * 0.5, 0, 0.19) ! 2;
    turbine = SinOsc.ar((rpm * 11.7) + SinOsc.ar(rpm * 2.07, 0, rpm * (0.8 + t)), 0, 0.07 + (t * 0.045));
    turbine = Pan2.ar(turbine, SinOsc.kr(0.13, 0, 0.32));
    sand = BPF.ar(PinkNoise.ar(0.4 ! 2), 650 + (t * 3400) + LFNoise2.kr(1.7, 180), 0.6) * (0.18 + (t * 0.5));
    arc = BPF.ar(WhiteNoise.ar(0.2), 2600 + (t * 1900), 0.16) * Decay2.ar(Dust.ar(3 + (t * 14)), 0.002, 0.045) * grit;
    sig = engines + sub + turbine + sand + (arc ! 2);
    sig = (sig * (1.4 + grit)).tanh * 0.65;
    sig = sig + CombC.ar(sig, 0.12, [0.071, 0.093], 0.28, 0.13);
    sig = Balance2.ar(sig[0], sig[1], Lag.kr(pan.clip(-1, 1), 0.4));
    env = EnvGen.kr(Env.asr(2.5, 1, 3.5), gate, doneAction: 2);
    Out.ar(out, Limiter.ar(LeakDC.ar(sig) * env * amp, 0.88));
});
)
