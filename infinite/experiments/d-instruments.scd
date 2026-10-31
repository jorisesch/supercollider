// EDM D voices. Definitions only; no server boot or playback.
(
~experimentDefs=~experimentDefs ++ [
    SynthDef(\xdBass, { |out=0, freq=65, amp=0.16, sustain=0.16, pan=0, cutoff=500, accent=0.5, tone=0.4|
        var env=EnvGen.kr(Env.perc(0.004, sustain.max(0.04), curve:-4), doneAction:2);
        var filterEnv=EnvGen.kr(Env.perc(0.002, 0.13));
        var pitch=freq.clip(25, 1200), core, sub, sig;
        core=Mix(Saw.ar(pitch * [0.997, 1.003])) * 0.30 + Pulse.ar(pitch * 1.001, 0.38) * 0.16;
        sub=SinOsc.ar(pitch * 0.5) * 0.34;
        sig=RLPF.ar(core + sub,
            (cutoff + (filterEnv * (500 + (accent.clip(0, 1) * 1700)))
                + (tone.clip(0, 1) * 180)).clip(100, 5000), 0.30);
        Out.ar(out, Pan2.ar(LeakDC.ar((sig * (1.8 + (accent * 0.7))).tanh) * env * amp, pan));
    }),
    SynthDef(\xdLead, { |out=0, freq=440, amp=0.08, sustain=0.24, pan=0, cutoff=2600,
        accent=0.5, vibDepth=0.002, vibRate=5, vibDelay=0.12|
        var env=EnvGen.kr(Env.perc(0.008, sustain.max(0.08) + 0.12), doneAction:2);
        var vibGate=EnvGen.kr(Env([0, 0, 1], [vibDelay.max(0.02), 0.16]));
        var vib=SinOsc.kr(vibRate.clip(0.5, 12), 0, vibDepth.clip(0, 0.03)) * vibGate;
        var tuned=(freq.clip(40, 8000) * (1 + vib)).clip(40, 10000), sig;
        sig=Pulse.ar(tuned, 0.34) * 0.42 + Saw.ar(tuned * [0.999, 1.001]).sum * 0.22;
        sig=RLPF.ar(sig, (cutoff + (env * (400 + (accent * 1600)))).clip(500, 9000), 0.38);
        Out.ar(out, Pan2.ar(LeakDC.ar(sig) * env * amp, pan));
    }),
    SynthDef(\xdArp, { |out=0, freq=220, amp=0.07, sustain=0.14, pan=0, cutoff=1800, accent=0.5|
        var env=EnvGen.kr(Env.perc(0.003, sustain.max(0.035) + 0.08), doneAction:2);
        var filterEnv=EnvGen.kr(Env.perc(0.002, 0.11));
        var sig=Mix(Saw.ar(freq.clip(40, 9000) * [0.998, 1.002])) * 0.28
            + Pulse.ar(freq.clip(40, 9000), 0.44) * 0.16;
        sig=RLPF.ar(sig, (cutoff + (filterEnv * (800 + (accent * 2600)))).clip(500, 9000), 0.31);
        Out.ar(out, Pan2.ar(sig * env * amp, pan));
    }),
    SynthDef(\xdPad, { |out=0, freq=220, amp=0.035, sustain=2.5, pan=0, attack=0.18, release=1.2,
        cutoff=1500, accent=0.4|
        var env=EnvGen.kr(Env.linen(attack.max(0.02), sustain.max(0.05), release.max(0.05), curve:\sin), doneAction:2);
        var drift=SinOsc.kr(0.17, [0, 1.7], 0.002);
        var sig=Mix(VarSaw.ar(freq.clip(30, 5000) * (1 + drift), 0, [0.44, 0.50])) * 0.22;
        sig=RLPF.ar(sig, (cutoff + (SinOsc.kr(0.11).range(0, 260) * accent)).clip(350, 6000), 0.48);
        Out.ar(out, Pan2.ar(LeakDC.ar(sig) * env * amp, pan));
    }),
    SynthDef(\xdKick, { |out=0, freq=48, amp=0.42, sustain=0.32, pan=0, accent=0.8|
        var env=EnvGen.kr(Env.perc(0.001, sustain.max(0.15), curve:-5), doneAction:2);
        var pitch=EnvGen.kr(Env([3.4, 1.22, 1], [0.014, 0.10], [-6, -3])) * freq.clip(35, 80);
        var clickEnv=EnvGen.kr(Env.perc(0.0005, 0.007));
        var sig=SinOsc.ar(pitch) * env
            + (HPF.ar(WhiteNoise.ar, 2500) * clickEnv * (0.07 + (accent * 0.035)));
        Out.ar(out, Pan2.ar(LeakDC.ar((sig * 1.5).tanh) * amp * 0.82, pan));
    }),
    SynthDef(\xdSnare, { |out=0, freq=175, amp=0.12, sustain=0.14, pan=0, accent=0.7|
        var env=EnvGen.kr(Env.perc(0.001, sustain.max(0.05), curve:-4), doneAction:2);
        var bodyEnv=EnvGen.kr(Env.perc(0.001, 0.055));
        var body=SinOsc.ar(freq.clip(100, 300) * [1.15, 2.05], 0, [0.28, 0.09]).sum * bodyEnv;
        var noise=HPF.ar(LPF.ar(WhiteNoise.ar, 9000), 1300) * env;
        Out.ar(out, Pan2.ar(((noise + body) * (1.4 + (accent * 0.5))).tanh * amp, pan));
    }),
    SynthDef(\xdHat, { |out=0, freq=7200, amp=0.045, sustain=0.07, pan=0, accent=0.5|
        var env=EnvGen.kr(Env.perc(0.001, sustain.max(0.025)), doneAction:2);
        var sig=HPF.ar(WhiteNoise.ar, freq.clip(2500, 13000));
        Out.ar(out, Pan2.ar(sig * env * amp * (0.85 + (accent * 0.25)), pan));
    }),
    SynthDef(\xdGhost, { |out=0, freq=160, amp=0.035, sustain=0.08, pan=0, accent=0.3|
        var env=EnvGen.kr(Env.perc(0.001, sustain.max(0.03)), doneAction:2);
        var sig=HPF.ar(LPF.ar(WhiteNoise.ar, 7000), 900) * 0.7
            + (SinOsc.ar(freq.clip(100, 300)) * 0.18);
        Out.ar(out, Pan2.ar(sig * env * amp * (0.8 + (accent * 0.2)), pan));
    }),
    SynthDef(\xdClap, { |out=0, amp=0.045, sustain=0.11, pan=0, accent=0.4|
        var env=EnvGen.kr(Env.perc(0.001, sustain.max(0.04)), doneAction:2);
        var burst=Decay2.kr(Impulse.kr(18), 0.001, 0.035);
        var sig=BPF.ar(WhiteNoise.ar, 1550, 0.75) * (env * (0.45 + (burst * 0.9)));
        Out.ar(out, Pan2.ar(sig * amp * (0.9 + (accent * 0.2)), pan));
    }),
    SynthDef(\xdOpenHat, { |out=0, freq=6500, amp=0.05, sustain=0.20, pan=0, accent=0.6|
        var env=EnvGen.kr(Env.perc(0.001, sustain.max(0.08)), doneAction:2);
        var sig=HPF.ar(WhiteNoise.ar, freq.clip(3000, 13000));
        Out.ar(out, Pan2.ar(sig * env * amp * (0.85 + (accent * 0.2)), pan));
    })
];
)
