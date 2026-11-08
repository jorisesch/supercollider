[
    SynthDef(\vhLead, { |out=24, freq=440, amp=0.32, seed=1, sustain=0.18, tone=0.65, pan=0|
        var pitch, env, attack, center, sides, sig, cutoff;
        RandSeed.ir(1, seed);
        pitch = freq.clip(120, 1400) * (1 + (SinOsc.kr(5.4) * Line.kr(0, 0.004, 0.28)));
        env = EnvGen.kr(Env([0, 1, 0.81, 0], [0.008, sustain.max(0.02), 0.084], [-2, -2, -4]), doneAction: 2);
        attack = EnvGen.kr(Env.perc(0.008, 0.095, curve: -3));
        center = (VarSaw.ar(pitch, 0, 0.31) * 0.62) + (SinOsc.ar(pitch) * 0.21)
            + (SinOsc.ar(pitch * 2) * attack * 0.09);
        sides = VarSaw.ar(pitch * [0.988, 1.007, 0.995, 1.014],
            [Rand(0.0, 1.0), Rand(0.0, 1.0), Rand(0.0, 1.0), Rand(0.0, 1.0)], 0.44);
        sig = (Pan2.ar(center, pan) * 0.82) + Splay.ar(sides, 0.88, 0.51, pan);
        cutoff = tone.clip(0, 1).linexp(0, 1, 950, 6700) * (1 + (attack * 0.24));
        sig = HPF.ar(LPF.ar(sig, cutoff), 210);
        Out.ar(out, LeakDC.ar((sig * 1.14).tanh) * env * amp);
    }),

    SynthDef(\vhMix, { |out=0, in=16, gate=1, bpm=134, gain=1.42|
        var chords = In.ar(in, 2), bass = In.ar(in + 2, 2);
        var drums = In.ar(in + 4, 2), kick = In.ar(in + 6, 2), lead = In.ar(in + 8, 2);
        var beat = 60 / bpm.max(60), level, pump, delay, reverbIn, space, sig, env;
        level = Amplitude.kr(kick.sum * 0.5, 0.002, 0.105);
        pump = (level * 4.6).clip(0, 0.72);
        delay = CombC.ar(HPF.ar(lead.reverse, 480), 0.8, [0.75, 1] * beat, 0.84);
        delay = LPF.ar(delay, 2650) * 0.13;
        reverbIn = HPF.ar((lead * 0.77) + (chords * 0.65) + (drums * 0.14), 370);
        space = FreeVerb2.ar(reverbIn[0], reverbIn[1], 1, 0.68, 0.49) * 0.16;
        sig = (bass * (1 - pump)) + (chords * (1 - (pump * 0.60)))
            + (lead * (1 - (pump * 0.27))) + kick + drums + delay + space;
        sig = HPF.ar(LeakDC.ar(sig), 25);
        sig = Compander.ar(sig, sig, 0.49, 1, 0.66, 0.006, 0.12);
        env = EnvGen.kr(Env.asr(0.02, 1, 0.9), gate, doneAction: 2);
        Out.ar(out, Limiter.ar(sig * gain, 0.89) * env);
    })
]
