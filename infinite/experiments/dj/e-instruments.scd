// EDM E instruments. Stock UGens; loading definitions starts no playback.
(
~djEDefs=[
    SynthDef(\edmAnthemLead,{ |out=0,freq=440,amp=0.23,seed=1,sustain=0.18,tone=0.65,pan=0|
        var pitch,env,attack,center,sides,sig,cutoff;
        RandSeed.ir(1,seed);
        pitch=freq.clip(120,2400)*(1+(SinOsc.kr(5.4)*Line.kr(0,0.004,0.28)));
        env=EnvGen.kr(Env([0,1,0.81,0],[0.008,sustain.max(0.02),0.084],[-2,-2,-4]),doneAction:2);
        attack=EnvGen.kr(Env.perc(0.008,0.095,curve:-3));
        center=(VarSaw.ar(pitch,0,0.31)*0.62)+(SinOsc.ar(pitch)*0.21)+(SinOsc.ar(pitch*2)*attack*0.09);
        sides=VarSaw.ar(pitch*[0.988,1.007,0.995,1.014],
            [Rand(0,1),Rand(0,1),Rand(0,1),Rand(0,1)],0.44);
        sig=(Pan2.ar(center,pan)*0.82)+Splay.ar(sides,0.88,0.51,pan);
        cutoff=tone.clip(0,1).linexp(0,1,950,6700)*(1+(attack*0.24));
        sig=HPF.ar(LPF.ar(sig,cutoff),210);
        Out.ar(out,LeakDC.ar((sig*1.14).tanh)*env*amp);
    }),
    SynthDef(\edmAnthemBass,{ |out=0,freq=55,amp=0.24,seed=1,sustain=0.18,tone=0.55|
        var pitch=freq.clip(25,180),duration=sustain.clip(0.025,2),brightness=tone.clip(0,1);
        var subEnv,octaveEnv,sub,octave,pulseWidth;
        RandSeed.ir(1,seed);
        pulseWidth=Rand(0.35,0.41);
        subEnv=EnvGen.kr(Env([0,1,0.86,0],[0.006,duration-0.006,0.042],[-2,-1,-4]),doneAction:2);
        octaveEnv=EnvGen.kr(Env([0,1,0.34,0],[0.006,(duration*0.56).clip(0.02,0.15),0.033],[-2,-4,-4]));
        sub=SinOsc.ar(pitch)*subEnv*0.82;
        octave=HPF.ar(Pulse.ar(pitch*2,pulseWidth),105);
        octave=LPF.ar(octave,brightness.linexp(0,1,420,1450));
        octave=octave*octaveEnv*brightness.linlin(0,1,0.07,0.30);
        Out.ar(out,Pan2.ar(LeakDC.ar(sub+octave),0,amp));
    }),
    SynthDef(\edmEBass,{ |out=0,freq=65,fromFreq=65,glide=0,amp=0.19,sustain=0.25,tone=0.4,drive=0.35,color=0,pan=0|
        var target=freq.clip(25,400),pitch,env,harmonic,grit=drive.clip(0,1),sig;
        pitch=Select.kr(glide>0,[target,XLine.kr(fromFreq.clip(25,400),target,glide.clip(0.001,0.16))]);
        env=EnvGen.kr(Env([0,1,0.76,0],[0.008,0.045,sustain.max(0.06)],[-2,-2,-4]),doneAction:2);
        harmonic=Select.ar(color.clip(0,3),[
            Saw.ar(pitch)*0.5,
            Saw.ar(pitch*[0.998,1.002]).sum*0.26,
            SinOsc.ar(pitch,SinOsc.ar(pitch*2)*(0.9+(tone*0.7)))*0.5,
            RLPF.ar(Saw.ar(pitch)*0.40,350+(tone.clip(0,1)*2200)+(env*600),0.4)
        ]);
        sig=(LPF.ar(harmonic,230+(tone.clip(0,1)*1800)+(env*320))*(1.2+(grit*2))).tanh
            *(0.60/(1+(grit*0.20)))+(SinOsc.ar(pitch)*0.45);
        Out.ar(out,Pan2.ar(LeakDC.ar(sig)*env*amp,pan));
    }),
    SynthDef(\edmEStab,{ |out=0,freq=220,amp=0.02,sustain=0.12,tone=0.4,pan=0|
        var env=EnvGen.kr(Env.perc(0.008,sustain.max(0.04)+0.14,curve:-5),doneAction:2);
        var sig=VarSaw.ar(freq.clip(100,2200)*[0.999,1.001],0,0.38).sum*0.26;
        sig=sig+(LFTri.ar(freq)*0.18);
        sig=RLPF.ar(sig,750+(tone.clip(0,1)*1900)+(env*450),0.78);
        Out.ar(out,Pan2.ar(HPF.ar(LeakDC.ar((sig*1.5).tanh),180)*env*amp,pan));
    }),
    SynthDef(\edmEShaker,{ |out=0,amp=0.02,sustain=0.04,pan=0,seed=2600|
        var env=EnvGen.kr(Env.perc(0.004,sustain.clip(0.02,0.09),curve:-4),doneAction:2),sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(LPF.ar(WhiteNoise.ar,10000),4300);
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    }),
    SynthDef(\edmETom,{ |out=0,freq=150,amp=0.045,sustain=0.18,pan=0,seed=2600|
        var env=EnvGen.kr(Env.perc(0.002,sustain.clip(0.06,0.30),curve:-5),doneAction:2),sig,pitch;
        RandSeed.ir(1,seed);
        pitch=freq.clip(110,320)*EnvGen.kr(Env([1.25,1],[0.035],-5));
        sig=(SinOsc.ar(pitch)*0.8)+(BPF.ar(WhiteNoise.ar,1800,0.45)*0.14);
        Out.ar(out,Pan2.ar(HPF.ar(sig,100)*env*amp,pan));
    }),
    SynthDef(\edmESignature,{ |out=0,freq=220,amp=0.03,sustain=0.18,tone=0.4,pan=0|
        var env=EnvGen.kr(Env.perc(0.012,sustain.max(0.05)+0.09,curve:-4),doneAction:2),sig,vowel;
        vowel=EnvGen.kr(Env([0,1,0.25],[0.05,sustain.max(0.05)],[-2,-3]));
        sig=Pulse.ar(freq.clip(100,700),0.42)*0.4;
        sig=BPF.ar(sig,550+(vowel*550),0.7)+(BPF.ar(sig,1400-(vowel*350),0.55)*0.35)
            +(LFTri.ar(freq)*0.18);
        Out.ar(out,Pan2.ar(HPF.ar(LPF.ar(sig,2600),160)*env*amp,pan));
    }),
    SynthDef(\edmEReverse,{ |out=0,amp=0.035,sustain=0.22,pan=0,seed=2600|
        var duration=sustain.clip(0.08,0.35),env,sig;
        RandSeed.ir(1,seed);
        env=EnvGen.kr(Env([0,0.12,1,0],[duration*0.65,duration*0.35,0.025],[2,3,-4]),doneAction:2);
        sig=BPF.ar(PinkNoise.ar,XLine.kr(700,2700,duration),0.6);
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    })
];
~djDefs=~djDefs++~djEDefs;
)
