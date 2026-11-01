// Definitions only: stock UGens, no samples, boot, playback, or file writes.
(
~discoDefs=[
    SynthDef(\discoKick,{ |out=0,amp=0.52,seed=1|
        var env=EnvGen.kr(Env.perc(0.002,0.29,curve:-5),doneAction:2);
        var pitch=EnvGen.kr(Env([115,56,49],[0.018,0.09],[-5,-3]));
        var click=EnvGen.kr(Env.perc(0.001,0.007)),sig;
        RandSeed.ir(1,seed);
        sig=(SinOsc.ar(pitch)*1.4).tanh*env;
        sig=sig+(HPF.ar(WhiteNoise.ar,2000)*click*0.018);
        Out.ar(out,Pan2.ar(sig*amp,0));
    }),
    SynthDef(\discoClap,{ |out=0,amp=0.18,pan=0,seed=1|
        var env=EnvGen.kr(Env([0,1,0.15,0.75,0.1,0.6,0],
            [0.001,0.007,0.002,0.008,0.002,0.10],-3),doneAction:2),sig;
        RandSeed.ir(1,seed);
        sig=BPF.ar(WhiteNoise.ar,1750,0.8)+(HPF.ar(WhiteNoise.ar,3400)*0.15);
        Out.ar(out,Pan2.ar(LPF.ar(sig,6200)*env*amp,pan));
    }),
    SynthDef(\discoHat,{ |out=0,amp=0.055,sustain=0.045,pan=0.22,seed=1|
        var env=EnvGen.kr(Env.perc(0.002,sustain.clip(0.02,0.24),curve:-5),doneAction:2),sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(WhiteNoise.ar,6100);
        Out.ar(out,Pan2.ar(LPF.ar(sig,11200)*env*amp,pan));
    }),
    SynthDef(\discoShake,{ |out=0,amp=0.045,pan= -0.3,seed=1|
        var env=EnvGen.kr(Env.perc(0.004,0.033,curve:-4),doneAction:2),sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(PinkNoise.ar,3800);
        Out.ar(out,Pan2.ar(LPF.ar(sig,10000)*env*amp,pan));
    }),
    SynthDef(\discoRim,{ |out=0,amp=0.06,pan= -0.25|
        var env=EnvGen.kr(Env.perc(0.001,0.045,curve:-6),doneAction:2);
        var sig=(SinOsc.ar(380)*0.7)+(SinOsc.ar(1110)*0.3);
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    }),
    SynthDef(\discoBass,{ |out=0,freq=55,amp=0.3,sustain=0.2,tone=0.4,seed=1|
        var env=EnvGen.kr(Env([0,1,0.82,0.67,0],
            [0.008,0.035,sustain.max(0.025),0.045],[-2,-2,-1,-4]),doneAction:2);
        var pitch=freq.clip(30,220),pluck=EnvGen.kr(Env.perc(0.002,0.018)),body,sig;
        RandSeed.ir(1,seed);
        // Fixed pitch and gently filtered harmonics: no elastic pitch/filter sweep.
        body=(VarSaw.ar(pitch,0,0.32)*0.38)+(SinOsc.ar(pitch*2)*0.10);
        body=LPF.ar((body*1.8).tanh,650+(tone.clip(0,1)*900));
        sig=(SinOsc.ar(pitch)*0.67)+(body*0.60);
        sig=sig+(BPF.ar(WhiteNoise.ar,1100,0.8)*pluck*0.018);
        Out.ar(out,Pan2.ar(LeakDC.ar(sig)*env*amp,0));
    }),
    SynthDef(\discoKeys,{ |out=0,freq=220,amp=0.11,sustain=0.5,tone=0.4,pan=0|
        var env=EnvGen.kr(Env([0,1,0.63,0],
            [0.012,sustain.max(0.04),0.28],[-2,-2,-4]),doneAction:2);
        var strike=EnvGen.kr(Env.perc(0.008,0.14)),pitch=freq.clip(80,1500),sig;
        sig=SinOsc.ar(pitch,SinOsc.ar(pitch*2)*((strike*0.28)+0.14))*0.8;
        sig=sig+(SinOsc.ar(pitch*2)*0.13)+(SinOsc.ar(pitch*3)*strike*0.035);
        sig=LPF.ar(sig,1500+(tone.clip(0,1)*1600));
        sig=sig*(0.96+(SinOsc.kr(4.8,pan)*0.04));
        Out.ar(out,Pan2.ar((sig*1.2).tanh*env*amp,pan));
    }),
    SynthDef(\discoChop,{ |out=0,freq=220,amp=0.17,sustain=0.13,tone=0.4,pan=0,seed=1|
        var env=EnvGen.kr(Env.perc(0.003,sustain.clip(0.05,0.3)+0.09,curve:-4),doneAction:2);
        var pitch=freq.clip(100,1600),sig;
        RandSeed.ir(1,seed);
        // A short, damped string resonator. A guitar-like rhythmic role, not a sample.
        sig=Pluck.ar(WhiteNoise.ar(0.8),Impulse.kr(0),0.02,pitch.reciprocal,
            sustain.clip(0.05,0.3)+0.09,0.42);
        sig=HPF.ar(LPF.ar(sig,1700+(tone.clip(0,1)*2400)),180);
        Out.ar(out,Pan2.ar((sig*2).tanh*env*amp,pan));
    }),
    SynthDef(\discoReed,{ |out=0,freq=220,amp=0.11,sustain=0.25,tone=0.4,pan=0|
        var env=EnvGen.kr(Env.linen(0.024,sustain.max(0.035),0.11,curve:-2),doneAction:2);
        var pitch=freq.clip(100,1000)*(1+(SinOsc.kr(5.1)*0.0009)),sig;
        sig=(SinOsc.ar(pitch)*0.60)+(SinOsc.ar(pitch*2)*0.18)
            +(VarSaw.ar(pitch,0,0.48)*0.20);
        sig=LPF.ar(sig,1100+(tone.clip(0,1)*1300));
        Out.ar(out,Pan2.ar((sig*1.3).tanh*env*amp,pan));
    }),
    SynthDef(\discoMix,{ |out=0,in=16,gate=1,bpm=120,gain=1.75,wet=0.10,delay=0.085,brightness=4200|
        var env=EnvGen.kr(Env.asr(0.04,1,1),gate,doneAction:2);
        var music=In.ar(in,2),bass=In.ar(in+2,2),drums=In.ar(in+4,2),pump,echo,space,sig;
        pump=1-(Amplitude.kr(LPF.ar(drums.sum,130),0.004,0.12)*0.9).clip(0,0.18);
        music=HPF.ar(LPF.ar(music,Lag.kr(brightness.clip(800,12000),0.2)),140);
        echo=LPF.ar(CombC.ar(HPF.ar(music,450),1,[0.75,1]*(60/bpm.clip(90,140)),1.2),2200)*delay;
        space=FreeVerb2.ar(music[0]+echo[0],music[1]+echo[1],wet.clip(0,0.4),0.48,0.7);
        sig=(space*(0.92+(pump*0.08)))+(bass*pump)+drums;
        sig=Compander.ar(sig,sig,0.42,1,0.75,0.012,0.1)*gain;
        Out.ar(out,Limiter.ar(HPF.ar(LeakDC.ar(sig),25),0.86)*env*0.92);
    })
];
)
