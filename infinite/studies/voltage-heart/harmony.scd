[
    SynthDef(\vhPad, { |out=16, freq=440, amp=0.065, sustain=1.6, pan=0, tone=0.46, seed=1|
        var pitch = freq.clip(100, 1600);
        var color = tone.clip(0, 1);
        var duration = sustain.max(0.1);
        var attack = (duration * 0.26).clip(0.09, 0.34);
        var phrase = EnvGen.kr(Env([0, 1, 0.82, 0], [attack, duration - attack, 0.54], [-3, -2, -4]));
        var lifetime = EnvGen.kr(Env([1, 1, 0], [duration + 1.63, 0.18]), doneAction: 2);
        var swell = SinOsc.kr(0.31 + ((seed % 7) * 0.033), (seed % 13) * 0.41);
        var pwm = SinOsc.kr(0.43 + ((seed % 5) * 0.061), (seed % 17) * 0.31, 0.075, 0.45);
        var center = VarSaw.ar(pitch, (seed % 13) / 13, pwm) * 0.21;
        var shoulders = VarSaw.ar(pitch * [0.9966, 1.0037], [0.18, 0.63], 1 - pwm) * 0.36;
        var edges = VarSaw.ar(pitch * [1.0071, 0.9932], [0.53, 0.23], pwm) * 0.19;
        var sheen = SinOsc.ar(pitch * 2, 0.3, 0.055 + (color * 0.028));
        var cutoff = (970 + (color * 2670) + (phrase * 670)) * (1 + (swell * 0.1));
        var strings = HPF.ar(LPF.ar(center + shoulders + edges + sheen, cutoff), 225);
        var mix = strings * phrase * (0.93 + (swell * 0.07));
        var wash = FreeVerb2.ar(mix[0], mix[1], 0.35, 0.72, 0.61);

        Out.ar(out, Balance2.ar(wash[0], wash[1], pan.clip(-1, 1), amp * lifetime));
    }),

    SynthDef(\vhStab, { |out=16, freq=440, amp=0.045, sustain=0.16, pan=0, tone=0.65, seed=1|
        var pitch = freq.clip(100, 1600);
        var color = tone.clip(0, 1);
        var duration = sustain.clip(0.045, 1.5);
        var phrase = EnvGen.kr(Env([0, 1, 0.48, 0], [0.007, duration, 0.13], [-4, -4, -5]));
        var lifetime = EnvGen.kr(Env([1, 1, 0], [duration + 0.21, 0.035]), doneAction: 2);
        var flash = EnvGen.kr(Env([0.22, 1, 0.19, 0], [0.008, 0.073, 0.16], [-2, -5, -3]));
        var center = VarSaw.ar(pitch, (seed % 13) / 13, 0.36) * 0.28;
        var shoulders = VarSaw.ar(pitch * [0.9955, 1.0045], [0.42, 0.79], [0.26, 0.41]) * 0.4;
        var sheen = SinOsc.ar(pitch * [2.004, 1.996], 0.15) * flash * (0.062 + (color * 0.13));
        var cutoff = 1200 + (color * 2350) + (flash * (1100 + (color * 2600)));
        var dry = HPF.ar(LPF.ar(center + shoulders + sheen, cutoff), 285) * phrase;
        var echoes = DelayC.ar(dry.reverse, 0.1, [0.049, 0.073]) * [0.16, 0.13];
        var mix = dry + echoes;

        Out.ar(out, Balance2.ar(mix[0], mix[1], pan.clip(-1, 1), amp * lifetime));
    })
]
