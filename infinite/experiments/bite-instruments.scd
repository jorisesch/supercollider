// Additional definitions only. A and ambient voices are unchanged.
(
~experimentDefs=~experimentDefs ++ [
    SynthDef(\xbBass, { |out=0, freq=65, amp=0.2, sustain=0.12, pan=0, tone=0.7, accent=0.5|
        var env=EnvGen.kr(Env.perc(0.002, sustain.max(0.025), curve:-5), doneAction:2);
        var filterEnv=EnvGen.kr(Env.perc(0.001, 0.095 + (accent.clip(0, 1) * 0.045), curve:-6));
        var pitch=freq.clip(25, 1200), core, cutoff, mid, sub;
        core=Saw.ar(pitch) * 0.6 + Pulse.ar(pitch * 1.001, 0.38 + (filterEnv * 0.08)) * 0.25;
        cutoff=((170 + (tone.clip(0, 1) * 480)) * (1 + (filterEnv * (4 + (accent * 3))))).clip(80, 6500);
        mid=RLPF.ar(core, cutoff, 0.3);
        mid=HPF.ar((mid * (2.8 + (tone.clip(0, 1) * 2))).tanh, 110) * 0.65;
        sub=SinOsc.ar(pitch) * 0.45;
        Out.ar(out, Pan2.ar(LeakDC.ar(mid + sub) * env * amp, pan));
    }),
    SynthDef(\xbKick, { |out=0, freq=49, amp=0.42, sustain=0.24, pan=0, seed=2600|
        var env=EnvGen.kr(Env.perc(0.001, sustain.max(0.15), curve:-5), doneAction:2);
        var pitch=EnvGen.kr(Env([3.2, 1.22, 1], [0.016, 0.1], [-6, -3])) * freq.clip(35, 80);
        var clickEnv=EnvGen.kr(Env.perc(0.0005, 0.006));
        var sig;
        RandSeed.ir(1, seed);
        sig=SinOsc.ar(pitch) * env + (HPF.ar(WhiteNoise.ar, 2300) * clickEnv * 0.09);
        Out.ar(out, Pan2.ar(LeakDC.ar((sig * 1.5).tanh) * amp * 0.8, pan));
    }),
    SynthDef(\xbSnare, { |out=0, freq=147, amp=0.12, sustain=0.09, pan=0, seed=2600|
        var env=EnvGen.kr(Env.perc(0.001, sustain.max(0.045), curve:-4), doneAction:2);
        var bodyEnv=EnvGen.kr(Env.perc(0.001, 0.045));
        var noise, body, sig;
        RandSeed.ir(1, seed);
        noise=HPF.ar(LPF.ar(WhiteNoise.ar, 8500), 1200) * env;
        body=SinOsc.ar(freq.clip(100, 250) * [1.15, 2.1], 0, [0.3, 0.1]).sum * bodyEnv;
        sig=((noise + body) * 1.8).tanh * 0.7;
        Out.ar(out, Pan2.ar(sig * amp, pan));
    }),
    SynthDef(\xbMaster, { |out=0, in=16, gate=1, amp=0.85, bpm=126, fade=5|
        var env=EnvGen.kr(Env.asr(0.1, 1, fade), gate, doneAction:2);
        var music=In.ar(in, 2), drums=In.ar(in + 2, 2), bass=In.ar(in + 4, 2);
        var duck, echo, wet, sig;
        duck=1 - (Amplitude.kr(LPF.ar(drums.sum, 180), 0.002, 0.14) * 4).clip(0, 0.6);
        echo=LPF.ar(CombC.ar(HPF.ar(music, 450), 2, [0.75, 1] * (60 / bpm.clip(40, 200)), 1.3), 3200) * 0.10;
        wet=FreeVerb2.ar(music[0] + echo[0], music[1] + echo[1], 0.14, 0.72, 0.65);
        sig=(bass * duck) + drums + (wet * (0.8 + (duck * 0.2)));
        Out.ar(out, Limiter.ar(HPF.ar(LeakDC.ar(sig), 25), 0.85) * amp * env);
    })
];
)
