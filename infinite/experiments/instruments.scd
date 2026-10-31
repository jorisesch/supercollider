// New voices only; baseline definitions remain intact and provide drum subvoices.
(
var root=thisProcess.nowExecutingPath.dirname;
(root.dirname +/+ "infinite-instruments.scd").load;
~experimentDefs=~infiniteDefs ++ [
    SynthDef(\xpBass, { |out=0, freq=65, amp=0.2, sustain=0.1, pan=0, tone=0.4|
        var env=EnvGen.kr(Env.perc(0.005, sustain.max(0.02)), doneAction:2);
        var sig=Saw.ar(freq.clip(25, 1000)) * 0.45 + SinOsc.ar(freq) * 0.55;
        sig=LPF.ar(sig, 170 + (env * (500 + (tone.clip(0, 1) * 2000))));
        Out.ar(out, Pan2.ar(LeakDC.ar((sig * 1.5).tanh) * env * amp, pan));
    }),
    SynthDef(\xpPluck, { |out=0, freq=440, amp=0.1, sustain=0.2, pan=0, tone=0.4|
        var env=EnvGen.kr(Env.perc(0.006, sustain.max(0.02) + 0.2), doneAction:2);
        var sig=VarSaw.ar(freq.clip(40, 8000) * [0.998, 1.002], 0, 0.35).sum * 0.35;
        sig=RLPF.ar(sig, 600 + (env * (1000 + (tone.clip(0, 1) * 4000))), 0.5);
        Out.ar(out, Pan2.ar(LeakDC.ar(sig) * env * amp, pan));
    }),
    SynthDef(\xpArp, { |out=0, freq=220, amp=0.08, sustain=0.12, pan=0, tone=0.4|
        var env=EnvGen.kr(Env.perc(0.004, sustain.max(0.02) + 0.1), doneAction:2);
        var sig=SinOsc.ar(freq.clip(40, 8000), SinOsc.ar(freq * 2) * env * (0.5 + tone.clip(0, 1)));
        Out.ar(out, Pan2.ar(sig * env * amp, pan));
    }),
    SynthDef(\xpChord, { |out=0, freq=220, amp=0.04, sustain=1, pan=0, attack=0.18, release=1.2, tone=0.4|
        var env=EnvGen.kr(Env.linen(attack.max(0.01), sustain.max(0.02), release.max(0.02), curve:\sin), doneAction:2);
        var sig=LPF.ar(VarSaw.ar(freq.clip(30, 4000) * [0.997, 1.003], 0, 0.5).sum * 0.25,
            700 + (tone.clip(0, 1) * 2400));
        Out.ar(out, Pan2.ar(sig * env * amp, pan));
    }),
    SynthDef(\xpDrone, { |out=0, freq=65, amp=0.16, sustain=30, pan=0, attack=4, release=6, seed=2600|
        var env=EnvGen.kr(Env.linen(attack.max(0.1), sustain.max(0.1), release.max(0.1), curve:\sin), doneAction:2);
        var sig;
        RandSeed.ir(1, seed);
        sig=SinOsc.ar(freq.clip(25, 300)) * 0.65 + SinOsc.ar(freq * 0.5) * 0.15
            + (SinOsc.ar(freq * 2.001) * SinOsc.kr(0.017, Rand(0, 6)).range(0.05, 0.15));
        Out.ar(out, Pan2.ar(HPF.ar(sig, 25) * env * amp, pan));
    }),
    SynthDef(\xpCloud, { |out=0, freq=220, amp=0.075, sustain=10, pan=0, attack=6, release=12, tone=0.4, seed=2600|
        var env=EnvGen.kr(Env.linen(attack.max(0.1), sustain.max(0.1), release.max(0.1), curve:\sin), doneAction:2);
        var motion, sig, position;
        RandSeed.ir(1, seed);
        motion=SinOsc.kr(0.021, Rand(0, 6)).range(0.6, 1);
        sig=Mix(SinOsc.ar(freq.clip(30, 4000) * [0.998, 1.002, 2.001], 0, [0.36, 0.36, 0.1]));
        sig=sig + (LPF.ar(VarSaw.ar(freq, 0, 0.45), (700 + (tone.clip(0, 1) * 1600)) * motion) * 0.1);
        position=(pan + SinOsc.kr(0.013, Rand(0, 6), 0.15)).clip(-0.85, 0.85);
        Out.ar(out, Pan2.ar(LeakDC.ar(sig) * env * amp * motion, position));
    }),
    SynthDef(\xpBell, { |out=0, freq=660, amp=0.05, sustain=2.5, pan=0, attack=0.04, release=4|
        var env=EnvGen.kr(Env.linen(attack.max(0.01), sustain.max(0.02), release.max(0.1), curve:\sin), doneAction:2);
        var strike=EnvGen.kr(Env.perc(0.01, 1.2));
        var sig=SinOsc.ar(freq.clip(80, 5000), SinOsc.ar(freq * 2) * strike * 0.4);
        Out.ar(out, Pan2.ar(sig * env * amp, pan));
    }),
    SynthDef(\xpAir, { |out=0, freq=500, amp=0.11, sustain=10, pan=0, attack=4, release=10, seed=2600|
        var env=EnvGen.kr(Env.linen(attack.max(0.1), sustain.max(0.1), release.max(0.1), curve:\sin), doneAction:2);
        var sig;
        RandSeed.ir(1, seed);
        sig=BPF.ar(PinkNoise.ar, freq.clip(200, 2000) * SinOsc.kr(0.012).range(0.8, 1.2), 0.5);
        Out.ar(out, Pan2.ar(sig * env * amp, pan + SinOsc.kr(0.011, 0, 0.2)));
    }),
    SynthDef(\xpMaster, { |out=0, in=16, gate=1, amp=0.85, ambient=0, bpm=126, fade=5|
        var env=EnvGen.kr(Env.asr(0.1, 1, fade), gate, doneAction:2);
        var music=In.ar(in, 2), drums=In.ar(in + 2, 2), duck, echo, wet, sig;
        duck=1 - (Amplitude.kr(LPF.ar(drums.sum, 180), 0.005, 0.18) * 3).clip(0, 0.5);
        echo=LPF.ar(CombC.ar(HPF.ar(music, 350), 2, [0.75, 1] * (60 / bpm.clip(40, 200)), 1.8), 3500) * 0.16;
        wet=FreeVerb2.ar(music[0] + echo[0], music[1] + echo[1], 0.2 + (ambient * 0.3), 0.78 + (ambient * 0.2), 0.6);
        sig=(wet * duck) + drums;
        Out.ar(out, Limiter.ar(HPF.ar(LeakDC.ar(sig), 25), 0.85) * amp * env);
    })
];
)
