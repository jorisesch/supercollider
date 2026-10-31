// Definitions only. No server boot or playback.
(
~infiniteDefs = [
    SynthDef(\igKick, { |out=0, amp=0.3, freq=48, sustain=0.4, pan=0|
        var env = EnvGen.kr(Env.perc(0.002, sustain), doneAction:2);
        var pitch = freq + EnvGen.kr(Env.perc(0.001, 0.035), levelScale:100);
        Out.ar(out, Pan2.ar(SinOsc.ar(pitch) * env * amp, pan));
    }),
    SynthDef(\igBass, { |out=0, amp=0.12, freq=55, sustain=0.25, pan=0|
        var env = EnvGen.kr(Env.perc(0.008, sustain), doneAction:2);
        var sig = LPF.ar(Saw.ar(freq.clip(25, 2000)) * 0.65 + SinOsc.ar(freq) * 0.35, 180 + (env * 1400));
        Out.ar(out, Pan2.ar(LeakDC.ar(sig) * env * amp, pan));
    }),
    SynthDef(\igLead, { |out=0, amp=0.07, freq=440, sustain=0.5, pan=0|
        var env = EnvGen.kr(Env.perc(0.02, sustain), doneAction:2);
        var sig = LPF.ar(Pulse.ar(freq.clip(40, 8000), 0.35), 2200);
        Out.ar(out, Pan2.ar(sig * env * amp, pan));
    }),
    SynthDef(\igArp, { |out=0, amp=0.06, freq=220, sustain=0.12, pan=0|
        var env = EnvGen.kr(Env.perc(0.003, sustain), doneAction:2);
        var sig = LPF.ar(Saw.ar(freq.clip(40, 8000)), 700 + (env * 2600));
        Out.ar(out, Pan2.ar(sig * env * amp, pan));
    }),
    SynthDef(\igSnare, { |out=0, amp=0.12, freq=147, sustain=0.16, pan=0|
        var env = EnvGen.kr(Env.perc(0.002, sustain), doneAction:2);
        var body = SinOsc.ar(freq.clip(80, 400)) * EnvGen.kr(Env.perc(0.002, 0.06));
        var sig;
        RandSeed.ir(1, 441);
        sig = HPF.ar(WhiteNoise.ar, 1500) * 0.65 + (body * 0.35);
        Out.ar(out, Pan2.ar(sig * env * amp, pan));
    }),
    SynthDef(\igHat, { |out=0, amp=0.05, freq=7000, sustain=0.07, pan=0|
        var env = EnvGen.kr(Env.perc(0.001, sustain), doneAction:2);
        RandSeed.ir(1, 773);
        Out.ar(out, Pan2.ar(HPF.ar(WhiteNoise.ar, freq.clip(2000, 12000)) * env * amp, pan));
    }),
    SynthDef(\igCloud, { |out=0, amp=0.09, freq=110, sustain=8, pan=0|
        var env = EnvGen.kr(Env.linen(2, sustain.max(2), 4), doneAction:2);
        var sig = Mix(SinOsc.ar(freq.clip(25, 4000) * [1, 1.003, 1.5], [0, 0.4, 1], [0.5, 0.25, 0.15]));
        Out.ar(out, Pan2.ar(sig * env * amp, pan));
    }),
    SynthDef(\igAir, { |out=0, amp=0.08, freq=1500, sustain=6, pan=0|
        var env = EnvGen.kr(Env.linen(2, sustain.max(2), 3), doneAction:2);
        RandSeed.ir(1, 991);
        Out.ar(out, Pan2.ar(BPF.ar(PinkNoise.ar, freq.clip(200, 8000), 0.3) * env * amp, pan));
    }),
    SynthDef(\igMaster, { |out=0, in=16, gate=1, amp=0.8|
        var env = EnvGen.kr(Env.asr(0.05, 1, 3), gate, doneAction:2);
        var dry = In.ar(in, 2);
        var wet = FreeVerb2.ar(dry[0], dry[1], 0.17, 0.8, 0.5);
        Out.ar(out, Limiter.ar(LeakDC.ar(wet), 0.85) * env * amp);
    })
];
)
