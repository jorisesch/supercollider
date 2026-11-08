[
    SynthDef(\vhBass, { |out=18, freq=55, amp=0.26, seed=1, sustain=0.18, tone=0.55|
        var fundamental = freq.clip(25, 180);
        var duration = sustain.clip(0.025, 2);
        var brightness = tone.clip(0, 1);
        var subEnv, octaveEnv, sub, octave, pulseWidth;

        RandSeed.ir(1, seed);
        pulseWidth = Rand(0.35, 0.41);

        subEnv = EnvGen.kr(
            Env([0, 1, 0.86, 0], [0.006, duration - 0.006, 0.042], [-2, -1, -4]),
            doneAction: 2
        );
        octaveEnv = EnvGen.kr(
            Env([0, 1, 0.34, 0], [0.006, (duration * 0.56).clip(0.02, 0.15), 0.033], [-2, -4, -4])
        );

        sub = SinOsc.ar(fundamental) * subEnv * 0.82;
        octave = Pulse.ar(fundamental * 2, pulseWidth);
        octave = HPF.ar(octave, 105);
        octave = LPF.ar(octave, brightness.linexp(0, 1, 420, 1450));
        octave = octave * octaveEnv * brightness.linlin(0, 1, 0.07, 0.30);

        Out.ar(out, Pan2.ar(LeakDC.ar(sub + octave), 0, amp));
    })
]
