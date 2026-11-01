// Instrument definitions only. No samples, boot, playback, or file writes.
(
~studyDefs=[
    SynthDef(\studyKick,{ |out=0,amp=0.6,freq=49,decay=0.34,edge=0.03,seed=1|
        var env=EnvGen.kr(Env.perc(0.0015,decay,curve:-5),doneAction:2);
        var pitch=EnvGen.kr(Env([2.9,1.13,1],[0.018,0.105],[-5,-3])) * freq.clip(35,65);
        var click=EnvGen.kr(Env.perc(0.0004,0.008)), sig;
        RandSeed.ir(1,seed);
        sig=(SinOsc.ar(pitch) * 1.45).tanh * env + (HPF.ar(WhiteNoise.ar,2500) * click * edge);
        Out.ar(out,Pan2.ar(sig * amp,0));
    }),
    SynthDef(\studyClap,{ |out=0,amp=0.16,pan=0,seed=1,bright=6500|
        var burst=EnvGen.kr(Env([0,1,0.1,0.8,0.1,0.65,0],[0.001,0.008,0.001,0.012,0.001,0.12],-3),doneAction:2);
        var sig;
        RandSeed.ir(1,seed);
        sig=BPF.ar(WhiteNoise.ar,1800,0.8) + (HPF.ar(WhiteNoise.ar,3500) * 0.25);
        sig=LPF.ar(sig,bright.clip(3000,10000)) * burst;
        Out.ar(out,Pan2.ar(sig * amp,pan));
    }),
    SynthDef(\studySnare,{ |out=0,amp=0.15,pan=0,seed=1,sustain=0.12|
        var env=EnvGen.kr(Env.perc(0.0015,sustain.max(0.035),curve:-4),doneAction:2);
        var bodyEnv=EnvGen.kr(Env.perc(0.001,0.055)),sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(LPF.ar(WhiteNoise.ar,7500),1100) * 0.65 + (SinOsc.ar(185) * bodyEnv * 0.4);
        Out.ar(out,Pan2.ar((sig * 1.6).tanh * env * amp,pan));
    }),
    SynthDef(\studyHat,{ |out=0,amp=0.065,sustain=0.065,pan=0.25,seed=1|
        var env=EnvGen.kr(Env.perc(0.001,sustain.max(0.012),curve:-5),doneAction:2);
        var sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(WhiteNoise.ar,6500) * 0.8 + (BPF.ar(WhiteNoise.ar,9500,0.4) * 0.15);
        Out.ar(out,Pan2.ar(LPF.ar(sig,12500) * env * amp,pan));
    }),
    SynthDef(\studyShake,{ |out=0,amp=0.045,pan=0,seed=1|
        var env=EnvGen.kr(Env.perc(0.002,0.032),doneAction:2),sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(PinkNoise.ar,4200);
        Out.ar(out,Pan2.ar(sig * env * amp,pan));
    }),
    SynthDef(\studyRim,{ |out=0,amp=0.07,freq=430,pan= -0.3|
        var env=EnvGen.kr(Env.perc(0.0008,0.055,curve:-7),doneAction:2);
        var sig=SinOsc.ar(freq,SinOsc.ar(freq * 2.17) * env * 2) + (SinOsc.ar(freq * 3.11) * 0.2);
        Out.ar(out,Pan2.ar(sig * env * amp,pan));
    }),
    SynthDef(\studyCrash,{ |out=0,amp=0.1,seed=1|
        var env=EnvGen.kr(Env.perc(0.008,1.5,curve:-5),doneAction:2),sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(WhiteNoise.ar(0.7!2),3500);
        Out.ar(out,LPF.ar(sig,10500) * env * amp);
    }),
    SynthDef(\studyRise,{ |out=0,amp=0.055,sustain=3,seed=1|
        var env=EnvGen.kr(Env([0,0.3,1,0],[sustain*0.65,sustain*0.3,sustain*0.05],[-2,1,-4]),doneAction:2);
        var sweep=Line.kr(500,6500,sustain),sig;
        RandSeed.ir(1,seed);
        sig=BPF.ar(PinkNoise.ar(1!2),sweep,0.5);
        Out.ar(out,sig * env * amp);
    }),
    SynthDef(\studyBass,{ |out=0,freq=55,amp=0.26,sustain=0.2,family=0,tone=0.4|
        var env=EnvGen.kr(Env([0,1,0.78,0],[0.008,0.045,sustain.max(0.045)],[-2,-2,-4]),doneAction:2);
        var pitch=freq.clip(25,600),core,sub;
        core=Select.ar(family.clip(0,4),[
            Saw.ar(pitch) * 0.5, Pulse.ar(pitch,0.38) * 0.45,
            Saw.ar(pitch * [0.998,1.002]).sum * 0.25,
            SinOsc.ar(pitch,SinOsc.ar(pitch * 2) * 0.9) * 0.65,
            (Saw.ar(pitch) * 0.3) + (LFTri.ar(pitch) * 0.3)
        ]);
        core=LPF.ar(core,450 + (tone.clip(0,1)*2100) + (env*300));
        core=HPF.ar((core*1.8).tanh,95) * 0.6;
        sub=SinOsc.ar(pitch) * 0.55;
        Out.ar(out,Pan2.ar(LeakDC.ar(core+sub) * env * amp,0));
    }),
    SynthDef(\studyBell,{ |out=0,freq=440,amp=0.14,sustain=0.3,tone=0.5,pan=0|
        var env=EnvGen.kr(Env.perc(0.008,sustain.max(0.08)+0.45,curve:-3),doneAction:2);
        var index=EnvGen.kr(Env.perc(0.004,0.32));
        var sig=SinOsc.ar(freq.clip(80,7000),SinOsc.ar(freq*2.002) * index * (0.7+tone));
        Out.ar(out,Pan2.ar(LPF.ar(sig,6500) * env * amp,pan));
    }),
    SynthDef(\studyPluck,{ |out=0,freq=440,amp=0.15,sustain=0.3,tone=0.5,pan=0|
        var env=EnvGen.kr(Env.perc(0.008,sustain.max(0.07)+0.3,curve:-3),doneAction:2);
        var sig=VarSaw.ar(freq.clip(80,7000)*[0.998,1.002],0,0.32).sum * 0.4;
        sig=RLPF.ar(sig,900+(tone.clip(0,1)*3200)+(env*1800),0.65);
        Out.ar(out,Pan2.ar(LeakDC.ar(sig) * env * amp,pan));
    }),
    SynthDef(\studyStab,{ |out=0,freq=440,amp=0.13,sustain=0.15,tone=0.5,pan=0|
        var env=EnvGen.kr(Env.perc(0.008,sustain.max(0.04)+0.12,curve:-4),doneAction:2);
        var sig=(Pulse.ar(freq.clip(70,6000),0.37) * 0.5) + (Saw.ar(freq) * 0.2);
        sig=LPF.ar(sig,700+(tone.clip(0,1)*2400)+(env*650));
        Out.ar(out,Pan2.ar((sig*1.6).tanh * env * amp,pan));
    }),
    SynthDef(\studyKeys,{ |out=0,freq=440,amp=0.12,sustain=0.3,tone=0.5,pan=0|
        var env=EnvGen.kr(Env([0,1,0.5,0],[0.008,sustain.max(0.04),0.65],[-2,-3,-4]),doneAction:2);
        var strike=EnvGen.kr(Env.perc(0.002,0.12));
        var sig=SinOsc.ar(freq.clip(40,6000),SinOsc.ar(freq*2) * (0.35+(strike*1.3))) * 0.8
            + (SinOsc.ar(freq*3.001) * strike * 0.09);
        Out.ar(out,Pan2.ar(LPF.ar(sig,1800+(tone.clip(0,1)*4500)) * env * amp,pan));
    }),
    SynthDef(\studyWide,{ |out=0,freq=440,amp=0.17,sustain=0.8,tone=0.5,pan=0|
        var env=EnvGen.kr(Env.linen(0.045,sustain.max(0.05),0.35,curve:-2),doneAction:2);
        var sig=Splay.ar(Saw.ar(freq.clip(60,5000)*[0.993,0.996,0.999,1.001,1.004,1.007]),0.7,0.50,pan);
        sig=HPF.ar(LPF.ar(sig,1700+(tone.clip(0,1)*4200)),170);
        Out.ar(out,sig * env * amp);
    }),
    SynthDef(\studyPad,{ |out=0,freq=220,amp=0.055,sustain=2,tone=0.4,pan=0|
        var env=EnvGen.kr(Env.linen(0.25,sustain.max(0.05),0.9,curve:\sin),doneAction:2);
        var sig=(Saw.ar(freq.clip(35,5000)*[0.998,1.002]).sum * 0.25) + (SinOsc.ar(freq) * 0.2);
        sig=LPF.ar(sig,750+(tone.clip(0,1)*1700));
        Out.ar(out,Pan2.ar(LeakDC.ar(sig) * env * amp,pan));
    }),
    SynthDef(\studyMix,{ |out=0,in=16,gate=1,bpm=124,gain=1.8,room=0.75,wet=0.2,delay=0.16,duck=0.45|
        var env=EnvGen.kr(Env.asr(0.04,1,1),gate,doneAction:2);
        var music=In.ar(in,2),bass=In.ar(in+2,2),drums=In.ar(in+4,2),pump,echo,space,sig;
        pump=1-(Amplitude.kr(LPF.ar(drums.sum,170),0.003,0.17)*3.3).clip(0,duck.clip(0,0.65));
        echo=LPF.ar(CombC.ar(HPF.ar(music,450),2,[0.75,1]*(60/bpm.clip(90,150)),1.8),3300)*delay;
        space=FreeVerb2.ar(music[0]+echo[0],music[1]+echo[1],wet,room,0.65);
        sig=(space*(0.7+(pump*0.3)))+(bass*pump)+drums;
        sig=Compander.ar(sig,sig,0.4,1,0.65,0.01,0.12)*gain;
        Out.ar(out,Limiter.ar(HPF.ar(LeakDC.ar(sig),25),0.86)*env*0.9);
    }),

    SynthDef(\studyWarmLead,{ |out=0,freq=220,amp=0.13,sustain=0.3,family=0,tone=0.4,pan=0|
        var env=EnvGen.kr(Env.linen(0.04,sustain.max(0.045),0.18,curve:-2),doneAction:2);
        var pitch=freq.clip(65,3500),strike=EnvGen.kr(Env.perc(0.01,0.2)),sig;
        sig=Select.ar(family.clip(0,3),[
            (SinOsc.ar(pitch)*0.65)+(LFTri.ar(pitch)*0.25)+(Saw.ar(pitch)*0.10),
            (VarSaw.ar(pitch*[0.999,1.001],0,0.5).sum*0.16)+(SinOsc.ar(pitch)*0.65),
            (Saw.ar(pitch)*0.25)+(Pulse.ar(pitch,0.46)*0.15)+(SinOsc.ar(pitch)*0.55),
            (SinOsc.ar(pitch,SinOsc.ar(pitch*2)*strike*0.18)*0.8)+(LFTri.ar(pitch)*0.15)
        ]);
        sig=LPF.ar(HPF.ar(sig,80),850+(tone.clip(0,1)*900));
        Out.ar(out,Pan2.ar(LeakDC.ar(sig)*env*amp,pan));
    }),
    SynthDef(\studyWarmAccent,{ |out=0,freq=220,amp=0.025,sustain=0.12,tone=0.3,pan=0|
        var env=EnvGen.kr(Env.linen(0.025,sustain.max(0.025),0.12,curve:-3),doneAction:2);
        var pitch=freq.clip(80,3000),sig;
        sig=(SinOsc.ar(pitch)*0.8)+(LFTri.ar(pitch)*0.15);
        sig=LPF.ar(sig,950+(tone.clip(0,1)*500));
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    })
];
)
