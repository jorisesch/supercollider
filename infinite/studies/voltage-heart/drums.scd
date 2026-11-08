// Stock SuperCollider percussion for Voltage Heart. Evaluate to get the SynthDefs.
[
    SynthDef(\vhKick, { |out=20, amp=0.53, seed=1|
        var pitch, punch, body, click, sig;
        RandSeed.ir(1, seed);
        pitch = EnvGen.ar(Env([155, 63, 50, 48], [0.014, 0.032, 0.233], \exp));
        punch = EnvGen.ar(Env.perc(0.001, 0.278, curve: -4.2), doneAction: 2);
        body = (SinOsc.ar(pitch) * 1.52).tanh;
        click = BPF.ar(WhiteNoise.ar, Rand(1700, 2300), 0.92)
            * EnvGen.ar(Env.perc(0.0007, 0.018, curve: -5)) * 0.19;
        sig = (HPF.ar(body, 27) * punch) + click;
        Out.ar(out, Pan2.ar(LeakDC.ar(sig), 0, amp));
    }),

    SynthDef(\vhClap, { |out=20, amp=0.23, seed=1|
        var slap, tail, smack, room, sig;
        RandSeed.ir(1, seed);
        slap = EnvGen.ar(Env([0, 1, 0.13, 0.87, 0.09, 0.67, 0],
            [0.001, 0.008, 0.001, 0.009, 0.001, 0.084], -3));
        tail = EnvGen.ar(Env.perc(0.021, 0.148, curve: -4), doneAction: 2);
        smack = BPF.ar(WhiteNoise.ar, Rand(1370, 1510), 0.86) * slap * 1.40;
        room = HPF.ar(LPF.ar({ WhiteNoise.ar } ! 2, 5300), 1300) * tail * 0.55;
        sig = Pan2.ar(smack, 0) + room;
        Out.ar(out, LeakDC.ar(sig) * amp);
    }),

    SynthDef(\vhHat, { |out=20, amp=0.075, seed=1, sustain=0.07, pan=0|
        var env, noise, metal, sig;
        RandSeed.ir(1, seed);
        env = EnvGen.ar(Env.perc(0.002, sustain.clip(0.025, 0.28), curve: -4.4), doneAction: 2);
        noise = HPF.ar(PinkNoise.ar, 4900) + (BPF.ar(WhiteNoise.ar, 6500, 0.86) * 0.32);
        metal = Mix(Pulse.ar([301, 411, 497, 663] * Rand(0.995, 1.005), 0.43)) * 0.25;
        sig = LPF.ar(noise + (HPF.ar(metal, 5300) * 0.22), 9500) * env;
        Out.ar(out, Pan2.ar(LeakDC.ar(sig), pan, amp));
    }),

    SynthDef(\vhTom, { |out=20, amp=0.17, seed=1, freq=133, pan=0|
        var env, pitch, drum, head, sig;
        RandSeed.ir(1, seed);
        env = EnvGen.ar(Env.perc(0.002, 0.208, curve: -4.6), doneAction: 2);
        pitch = freq.clip(88, 245) * EnvGen.ar(Env([1.46, 1.02, 1], [0.026, 0.17], \exp));
        drum = SinOsc.ar(pitch) + (SinOsc.ar(pitch * 1.61) * 0.23);
        head = BPF.ar(WhiteNoise.ar, Rand(950, 1310), 0.92)
            * EnvGen.ar(Env.perc(0.001, 0.039, curve: -4)) * 0.37;
        sig = HPF.ar((drum * env * 0.84) + head, 75);
        Out.ar(out, Pan2.ar(LeakDC.ar(sig), pan, amp));
    }),

    SynthDef(\vhSnare, { |out=20, amp=0.21, seed=1, sustain=0.135, pan=0|
        var env, bodyEnv, pitch, shell, wires, sig;
        RandSeed.ir(1, seed);
        env = EnvGen.ar(Env.perc(0.001, sustain.clip(0.035, 0.35), curve: -3.5), doneAction: 2);
        bodyEnv = EnvGen.ar(Env.perc(0.001, 0.052, curve: -5));
        pitch = EnvGen.ar(Env([244, 171], [0.028], \exp));
        shell = (SinOsc.ar(pitch) + (SinOsc.ar(pitch * 1.82) * 0.21)) * bodyEnv * 0.57;
        wires = (BPF.ar(WhiteNoise.ar, Rand(1710, 1930), 0.98) * 0.86)
            + (HPF.ar(WhiteNoise.ar, 3300) * 0.24);
        sig = HPF.ar(shell + (wires * env), 125);
        Out.ar(out, Pan2.ar(LeakDC.ar(sig), pan, amp));
    }),

    SynthDef(\vhRiser, { |out=20, amp=0.16, seed=1, sustain=3.58|
        var rise, elapsed, env, noise, sweep, sig;
        RandSeed.ir(1, seed);
        rise = sustain.clip(0.25, 16);
        elapsed = Line.kr(0, 1, rise);
        env = EnvGen.kr(Env([0, 0.16, 1, 0], [0.44, 0.56, 0.025], [1.8, 2.4, -5]),
            timeScale: rise, doneAction: 2);
        noise = ({ WhiteNoise.ar } ! 2) * 0.60 + ({ PinkNoise.ar } ! 2);
        sweep = elapsed.linexp(0, 1, 425, 4900);
        sig = LPF.ar(HPF.ar(noise, sweep * 0.51), sweep * 2.4)
            + (BPF.ar(noise, sweep, 1.2) * 0.37);
        Out.ar(out, LeakDC.ar(sig) * env * amp);
    }),

    SynthDef(\vhImpact, { |out=20, amp=0.23, seed=1|
        var washEnv, snapEnv, cutoff, wind, snap, sig;
        RandSeed.ir(1, seed);
        washEnv = EnvGen.ar(Env.perc(0.005, 1.36, curve: -5.2), doneAction: 2);
        snapEnv = EnvGen.ar(Env.perc(0.001, 0.077, curve: -4));
        cutoff = XLine.kr(7300, 790, 1.12);
        wind = LPF.ar(HPF.ar({ WhiteNoise.ar } ! 2, 420), cutoff) * washEnv;
        snap = BPF.ar(PinkNoise.ar, 1250, 1.08) * snapEnv;
        sig = (wind * 0.73) + Pan2.ar(snap, 0, 0.64);
        Out.ar(out, LeakDC.ar(sig) * amp);
    })
]
