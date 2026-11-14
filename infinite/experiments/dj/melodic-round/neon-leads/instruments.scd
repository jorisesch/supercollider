// Low-order harmonic tones: no distortion, detuned stack, resonance or sub-octave.
[
    SynthDef(\neonRoundLead,{|out=0,freq=440,amp=0.06,sustain=0.4,pan=0|
        var env=EnvGen.kr(Env.linen(0.022,sustain.max(0.04),0.16),doneAction:2);
        var sig=SinOsc.ar(freq,0,0.78)+SinOsc.ar(freq*2,0,0.11)
            +SinOsc.ar(freq*3,0,0.08)+SinOsc.ar(freq*5,0,0.025);
        Out.ar(out,Pan2.ar(sig,pan)*env*amp);
    }),
    SynthDef(\neonSoftKeys,{|out=0,freq=440,amp=0.085,sustain=0.4,pan=0|
        var env=EnvGen.kr(Env.linen(0.010,sustain.max(0.04),0.16),doneAction:2);
        var body=EnvGen.kr(Env.perc(0.008,0.90,curve:-2));
        var upper=EnvGen.kr(Env.perc(0.008,0.22,curve:-4));
        var sig=SinOsc.ar(freq,0,0.76*body)+SinOsc.ar(freq*2,0,0.19*upper)
            +SinOsc.ar(freq*3,0,0.08*upper.squared)+SinOsc.ar(freq*4,0,0.025*upper.squared);
        Out.ar(out,Pan2.ar(sig,pan)*env*amp);
    }),
    SynthDef(\neonCleanPluck,{|out=0,freq=440,amp=0.095,sustain=0.4,pan=0|
        var env=EnvGen.kr(Env.linen(0.014,sustain.max(0.04),0.12),doneAction:2);
        var body=EnvGen.kr(Env.perc(0.010,0.54,curve:-3));
        var upper=EnvGen.kr(Env.perc(0.014,0.11,curve:-4));
        var sig=SinOsc.ar(freq,0,0.78*body)+SinOsc.ar(freq*2,0,0.13*upper)
            +SinOsc.ar(freq*3,0,0.07*upper)+SinOsc.ar(freq*5,0,0.025*upper);
        Out.ar(out,Pan2.ar(sig,pan)*env*amp);
    })
]
