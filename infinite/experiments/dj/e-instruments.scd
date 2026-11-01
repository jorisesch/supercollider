// EDM E instruments. Stock UGens; loading definitions starts no playback.
(
~djEDefs=[
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
