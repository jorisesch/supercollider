// Extra stock-UGen voices and three complete drum kits. Definitions only.
(
var extra,kits;
extra=[
    SynthDef(\djReeseBass,{ |out=0,freq=65,amp=0.19,sustain=0.2,tone=0.4,pan=0,drive=0.35|
        var pitch=freq.clip(25,400),grit=drive.clip(0,1),env,sig;
        env=EnvGen.kr(Env([0,1,0.78,0],[0.009,0.04,sustain.max(0.06)],[-2,-2,-4]),doneAction:2);
        sig=Saw.ar(pitch*[0.997,1.003]).sum*0.27;
        sig=LPF.ar(sig,480+(tone.clip(0,1)*1700)+(env*350));
        sig=(sig*(1.4+(grit*2))).tanh*(0.58/(1+(grit*0.15)))+(SinOsc.ar(pitch)*0.34);
        Out.ar(out,Pan2.ar(LeakDC.ar(sig)*env*amp,pan));
    }),
    SynthDef(\djFMBass,{ |out=0,freq=65,amp=0.19,sustain=0.2,tone=0.4,pan=0,drive=0.35|
        var pitch=freq.clip(25,400),grit=drive.clip(0,1),env,index,sig;
        env=EnvGen.kr(Env([0,1,0.74,0],[0.006,0.045,sustain.max(0.06)],[-2,-2,-4]),doneAction:2);
        index=EnvGen.kr(Env.perc(0.003,0.19))*1.8+(tone.clip(0,1)*0.7);
        sig=SinOsc.ar(pitch,SinOsc.ar(pitch*2)*index)*0.50+(SinOsc.ar(pitch)*0.38);
        sig=LPF.ar((sig*(1+(grit*1.4))).tanh/(1+(grit*0.12)),600+(tone.clip(0,1)*1600));
        Out.ar(out,Pan2.ar(LeakDC.ar(sig)*env*amp,pan));
    }),
    SynthDef(\djAcidBass,{ |out=0,freq=65,amp=0.19,sustain=0.2,tone=0.4,pan=0,drive=0.35|
        var pitch=freq.clip(25,400),grit=drive.clip(0,1),env,sweep,sig;
        env=EnvGen.kr(Env([0,1,0.65,0],[0.004,0.04,sustain.max(0.06)],[-2,-2,-4]),doneAction:2);
        sweep=EnvGen.kr(Env.perc(0.004,0.18,curve:-4));
        sig=RLPF.ar(Saw.ar(pitch)*0.55,220+(tone.clip(0,1)*1250)+(sweep*2500),0.25);
        sig=(sig*(1.7+(grit*2.2))).tanh*(0.53/(1+(grit*0.15)))+(SinOsc.ar(pitch)*0.32);
        Out.ar(out,Pan2.ar(LeakDC.ar(sig)*env*amp,pan));
    }),
    SynthDef(\djBrassLead,{ |out=0,freq=440,amp=0.075,sustain=0.5,tone=0.4,pan=0|
        var pitch=freq.clip(100,4000),env,sweep,sig;
        env=EnvGen.kr(Env.linen(0.026,sustain.max(0.03),0.15,curve:-2),doneAction:2);
        sweep=EnvGen.kr(Env([0.45,1,0.72],[0.065,sustain.max(0.03)],[-1,-2]));
        sig=VarSaw.ar(pitch*[0.9985,1,1.0015],[0,0.02,0.04],0.8).sum*0.17;
        sig=sig+(Pulse.ar(pitch*0.5,0.48)*0.25);
        sig=RLPF.ar(sig,950+(tone.clip(0,1)*1800)+(sweep*2100),0.72);
        sig=HPF.ar(LeakDC.ar((sig*2).tanh),90)*env*amp*0.9;
        Out.ar(out,Pan2.ar(sig,pan));
    }),
    SynthDef(\djFMLead,{ |out=0,freq=440,amp=0.075,sustain=0.5,tone=0.4,pan=0|
        var pitch=freq.clip(100,4000),env,index,sig,body;
        env=EnvGen.kr(Env.linen(0.012,sustain.max(0.03),0.13,curve:-2),doneAction:2);
        index=1.1+(tone.clip(0,1)*1.7)+EnvGen.kr(Env.perc(0.02,0.28))*0.6;
        body=(Saw.ar(pitch)*0.20)+(Pulse.ar(pitch*0.5,0.47)*0.24);
        sig=(SinOsc.ar(pitch,SinOsc.ar(pitch*2)*index)*0.48)+body;
        sig=LPF.ar((sig*2.2).tanh,2800+(tone.clip(0,1)*2200));
        Out.ar(out,Pan2.ar(HPF.ar(LeakDC.ar(sig),90)*env*amp*0.79,pan));
    }),
    SynthDef(\djSyncLead,{ |out=0,freq=440,amp=0.075,sustain=0.5,tone=0.4,pan=0|
        var pitch=freq.clip(100,4000),env,sweep,sig;
        env=EnvGen.kr(Env.linen(0.013,sustain.max(0.03),0.14,curve:-2),doneAction:2);
        sweep=EnvGen.kr(Env([1,0.35],[sustain.max(0.08)+0.1],-2));
        sig=SyncSaw.ar(pitch,pitch*(1.6+(tone.clip(0,1)*1.1)+(sweep*0.65)))*0.43;
        sig=sig+(Pulse.ar(pitch,0.39)*0.15)+(Saw.ar(pitch*0.5)*0.25);
        sig=RLPF.ar(sig,1800+(tone.clip(0,1)*2300),0.75);
        Out.ar(out,Pan2.ar(HPF.ar(LeakDC.ar((sig*2).tanh),90)*env*amp*0.82,pan));
    }),
    SynthDef(\djStringPad,{ |out=0,freq=220,amp=0.027,sustain=2,tone=0.4,pan=0|
        var pitch=freq.clip(40,4000),env,sig;
        env=EnvGen.kr(Env.linen(0.24,sustain.max(0.05),0.75,curve:\sin),doneAction:2);
        sig=(Saw.ar(pitch*[0.998,1.002]).sum*0.23)+(LFTri.ar(pitch*0.5)*0.16);
        sig=LPF.ar(sig,1100+(tone.clip(0,1)*1700));
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    }),
    SynthDef(\djGlassPad,{ |out=0,freq=220,amp=0.027,sustain=2,tone=0.4,pan=0|
        var pitch=freq.clip(40,4000),env,sig;
        env=EnvGen.kr(Env.linen(0.3,sustain.max(0.05),0.7,curve:\sin),doneAction:2);
        sig=(SinOsc.ar(pitch,SinOsc.ar(pitch*2)*1.2)*0.50)+(VarSaw.ar(pitch,0,0.55)*0.19);
        sig=LPF.ar(sig,1800+(tone.clip(0,1)*1400));
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    })
];
kits=[
    (prefix:"djAnalog",pitch:52,decay:1.12,drive:1.7),
    (prefix:"djElectro",pitch:46,decay:0.72,drive:1.3),
    (prefix:"djDust",pitch:54,decay:0.92,drive:3.0)
];
kits.do { |kit,index|
    extra=extra.add(SynthDef((kit.prefix ++ "Kick").asSymbol,{ |out=0,amp=0.4,sustain=0.3,seed=2600|
        var env,pitch,sig,click;
        RandSeed.ir(1,seed);
        env=EnvGen.kr(Env.perc(0.001,sustain.clip(0.12,0.45)*kit.decay,curve:-5),doneAction:2);
        pitch=kit.pitch*EnvGen.kr(Env([if(index==1) {4.5} {3.2},1],[if(index==1) {0.025} {0.05}],-5));
        sig=SinOsc.ar(pitch);
        if(index==2) {sig=sig+(LFTri.ar(pitch*1.005)*0.20)};
        click=BPF.ar(WhiteNoise.ar,[4200,2800,1800][index],0.7)
            *EnvGen.kr(Env.perc(0.001,[0.012,0.007,0.018][index]))*0.11;
        Out.ar(out,Pan2.ar(((sig*kit.drive).tanh*env+click)*amp*0.92,0));
    }));
    extra=extra.add(SynthDef((kit.prefix ++ "Clap").asSymbol,{ |out=0,amp=0.12,pan=0,seed=2600|
        var env,sig,noise,body;
        RandSeed.ir(1,seed);
        env=if(index==1) {
            EnvGen.kr(Env.perc(0.001,0.095,curve:-4),doneAction:2)
        } {
            EnvGen.kr(Env([0,1,0.08,0.8,0.1,0.7,0],
                [0.001,0.009,0.001,0.013,0.001,if(index==2) {0.15} {0.11}],-3),doneAction:2)
        };
        noise=if(index==2) {PinkNoise.ar} {WhiteNoise.ar};
        sig=BPF.ar(noise,[1300,2400,1000][index],0.9)+(HPF.ar(noise,[3500,5000,2500][index])*0.18);
        body=SinOsc.ar([230,190,155][index])*EnvGen.kr(Env.perc(0.001,0.04))*[0.06,0.28,0.13][index];
        Out.ar(out,Pan2.ar((sig+body)*env*amp*[1.45,1.2,1.6][index],pan));
    }));
    extra=extra.add(SynthDef((kit.prefix ++ "Snare").asSymbol,{ |out=0,amp=0.11,sustain=0.12,pan=0,seed=2600|
        var env,noise,body,sig;
        RandSeed.ir(1,seed);
        env=EnvGen.kr(Env.perc(0.001,sustain.max(0.04)*[1.1,0.75,1.2][index],curve:-4),doneAction:2);
        noise=BPF.ar(WhiteNoise.ar,[2200,3200,1400][index],0.9)*0.85;
        body=SinOsc.ar([185,215,150][index])*EnvGen.kr(Env.perc(0.001,0.05))*0.35;
        sig=(noise+body)*env*amp*[1.1,1.0,1.2][index];
        Out.ar(out,Pan2.ar(sig,pan));
    }));
    extra=extra.add(SynthDef((kit.prefix ++ "Hat").asSymbol,{ |out=0,amp=0.06,sustain=0.1,pan=0,seed=2600|
        var env,metal,noise,sig;
        RandSeed.ir(1,seed);
        env=EnvGen.kr(Env.perc(0.001,sustain.max(0.015)*[1.1,0.7,0.9][index],curve:-5),doneAction:2);
        metal=Pulse.ar([401,547,701,943,1319,1733]*(1+(index*0.13)),0.5).sum*0.11;
        noise=HPF.ar(WhiteNoise.ar,[6400,7200,5100][index]);
        sig=if(index==1) {noise*0.85} {HPF.ar(metal,4300)*0.65+(noise*0.5)};
        Out.ar(out,Pan2.ar(sig*env*amp*1.35,pan));
    }));
    extra=extra.add(SynthDef((kit.prefix ++ "Perc").asSymbol,{ |out=0,amp=0.03,sustain=0.08,pan=0,seed=2600|
        var env,sig;
        RandSeed.ir(1,seed);
        env=EnvGen.kr(Env.perc(0.001,sustain.max(0.025),curve:-6),doneAction:2);
        sig=SinOsc.ar([1500,970,610][index])*0.55
            +BPF.ar(PinkNoise.ar,[2100,3400,1000][index],0.6)*0.5;
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    }));
};
~djDefs=~djDefs ++ extra;
)
