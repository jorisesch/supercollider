// Additional Pop voices only. Uses the existing per-deck mixer and effects.
(
~djPopDefs=[
    SynthDef(\popBass, { |out=0,freq=65,amp=0.22,sustain=0.2,pan=0,tone=0.5|
        var pitch=freq.clip(25,400),env=EnvGen.kr(Env.perc(0.003,sustain.max(0.04)),doneAction:2);
        var sig=LPF.ar(Saw.ar(pitch*[1,1.004]).sum*0.35,350+(env*1800))+(SinOsc.ar(pitch)*0.6);
        Out.ar(out,Pan2.ar(LeakDC.ar(sig)*env*amp,pan));
    }),
    SynthDef(\popLead, { |out=0,freq=440,amp=0.1,sustain=0.15,pan=0,tone=0.6|
        var pitch=freq.clip(100,4000),env=EnvGen.kr(Env.linen(0.006,sustain.max(0.02),0.1),doneAction:2);
        var sig=Mix(Saw.ar(pitch*[0.989,0.996,1,1.004,1.011]))*0.17;
        sig=RLPF.ar(sig,1600+(tone.clip(0,1)*5200),0.7);
        Out.ar(out,Pan2.ar(HPF.ar(LeakDC.ar(sig),110)*env*amp,pan));
    }),
    SynthDef(\popPad, { |out=0,freq=220,amp=0.035,sustain=1.5,pan=0,tone=0.5|
        var env=EnvGen.kr(Env.linen(0.12,sustain.max(0.05),0.5),doneAction:2);
        var sig=Saw.ar(freq.clip(50,3000)*[0.997,1.003]).sum*0.25;
        Out.ar(out,Pan2.ar(LPF.ar(LeakDC.ar(sig),900+(tone.clip(0,1)*1700))*env*amp,pan));
    })
];
~djDefs=~djDefs++~djPopDefs;
)
