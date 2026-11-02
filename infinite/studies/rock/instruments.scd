// Stock-UGen instrument definitions only. No boot or playback side effects.
(
~rockDefs=[
    SynthDef(\rkGuitar,{ |out=0,freq=110,amp=0.08,sustain=0.3,pan=0,drive=0.45,mute=0.5,seed=1,overdrive=0,fuzz=0,wah=0,slap=0|
        var pitch=freq.clip(55,1400),damp=mute.clip(0,1),grit=drive.clip(0,1),env,string,pick,sig,boost,fuzzed,swept,echo,signal;
        RandSeed.ir(1,seed);
        pitch=pitch*Rand(0.999,1.001);
        env=EnvGen.kr(Env.linen(0.001,sustain.clip(0.025,3.0),0.065,curve:-3));
        Line.kr(0,1,sustain.clip(0.025,3.0)+0.07+((slap>0)*0.6),doneAction:2);
        pick=WhiteNoise.ar*EnvGen.kr(Env.perc(0.0005,0.008));
        string=Pluck.ar(pick,Impulse.kr(0),0.03,pitch.reciprocal,
            0.35+((1-damp)*2.8),0.28+(damp*0.35));
        sig=HPF.ar(LeakDC.ar(string),65);
        sig=(sig*(2+(grit*12))).tanh;
        // Small cabinet resonances and a high-frequency rolloff after saturation.
        sig=LPF.ar(sig,4800-(damp*1600));
        sig=sig+(BPF.ar(sig,1400,0.8)*0.18)+(BPF.ar(sig,2800,0.6)*0.08);
        boost=(sig*3.2).tanh*0.60;
        sig=(sig*(1-overdrive.clip(0,1)))+(boost*overdrive.clip(0,1));
        fuzzed=LPF.ar(LeakDC.ar((sig*11).clip2(0.65)),3000)*0.75;
        sig=(sig*(1-fuzz.clip(0,1)))+(fuzzed*fuzz.clip(0,1));
        swept=BPF.ar(sig,EnvGen.kr(Env([650,1900,700],[0.04,sustain.max(0.06)],[-2,-3])),0.5)*2.0;
        sig=(sig*(1-wah.clip(0,0.8)))+(swept*wah.clip(0,0.8));
        signal=sig*env;
        echo=CombC.ar(signal,0.25,0.115,0.30)*slap.clip(0,1)*0.40;
        Out.ar(out,Pan2.ar((signal+echo)*amp,pan));
    }),
    SynthDef(\rkBass,{ |out=0,freq=55,amp=0.24,sustain=0.3,pan=0,seed=1,grit=0|
        var pitch=freq.clip(30,300),env,string,sig;
        RandSeed.ir(1,seed);
        env=EnvGen.kr(Env.linen(0.004,sustain.clip(0.025,3),0.08,curve:-3),doneAction:2);
        string=Pluck.ar(WhiteNoise.ar(0.5),Impulse.kr(0),0.04,pitch.reciprocal,1.7,0.6);
        sig=LPF.ar(string*2,950)+(SinOsc.ar(pitch)*0.50)+(SinOsc.ar(pitch*2)*0.08);
        // Preserve the low fundamental; add grit only in the upper bass band.
        sig=(sig*1.4).tanh+(HPF.ar((sig*4).tanh,190)*grit.clip(0,0.4)*0.25);
        Out.ar(out,Pan2.ar(LeakDC.ar(sig)*env*amp,pan));
    }),
    SynthDef(\rkKick,{ |out=0,amp=0.5,seed=1|
        var env=EnvGen.kr(Env.perc(0.001,0.29,curve:-5),doneAction:2);
        var pitch=EnvGen.kr(Env([125,57,48],[0.014,0.10],[-5,-3])),click,sig;
        RandSeed.ir(1,seed);
        click=BPF.ar(WhiteNoise.ar,2800,0.7)*EnvGen.kr(Env.perc(0.001,0.011))*0.12;
        sig=(SinOsc.ar(pitch)*1.3).tanh*env+click;
        Out.ar(out,Pan2.ar(sig*amp));
    }),
    SynthDef(\rkSnare,{ |out=0,amp=0.28,pan= -0.06,seed=1|
        var body,wire,env,sig;
        RandSeed.ir(1,seed);
        env=EnvGen.kr(Env.perc(0.001,0.21,curve:-4),doneAction:2);
        body=(SinOsc.ar(185)*0.55)+(SinOsc.ar(330)*0.16);
        body=body*EnvGen.kr(Env.perc(0.001,0.09,curve:-4));
        wire=HPF.ar(LPF.ar(WhiteNoise.ar,8500),1200)*env*0.48;
        sig=body+wire;
        Out.ar(out,Pan2.ar(sig*amp,pan));
    }),
    SynthDef(\rkHat,{ |out=0,amp=0.065,sustain=0.06,pan=0.28,seed=1|
        var env=EnvGen.kr(Env.perc(0.001,sustain.clip(0.025,0.30),curve:-5),doneAction:2),sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(WhiteNoise.ar,6500)+(BPF.ar(WhiteNoise.ar,9300,0.3)*0.35);
        Out.ar(out,Pan2.ar(LPF.ar(sig,12500)*env*amp,pan));
    }),
    SynthDef(\rkTom,{ |out=0,freq=120,amp=0.24,pan=0,seed=1|
        var env=EnvGen.kr(Env.perc(0.002,0.30,curve:-5),doneAction:2),pitch,sig;
        RandSeed.ir(1,seed);
        pitch=freq.clip(70,220)*EnvGen.kr(Env([1.3,1],[0.045],-4));
        sig=SinOsc.ar(pitch)+(SinOsc.ar(pitch*1.57)*0.18);
        sig=sig+(LPF.ar(WhiteNoise.ar,2000)*EnvGen.kr(Env.perc(0.001,0.012))*0.12);
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    }),
    SynthDef(\rkCrash,{ |out=0,amp=0.10,pan= -0.25,seed=1|
        var env=EnvGen.kr(Env.perc(0.003,1.8,curve:-4),doneAction:2),sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(PinkNoise.ar,3000)+(BPF.ar(WhiteNoise.ar,7200,0.6)*0.30);
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    }),
    SynthDef(\rkMix,{ |in=16,out=0,gate=1,amp=1.2,attack=0.05|
        var guitar=In.ar(in,2),bass=In.ar(in+2,2),drums=In.ar(in+4,2),room,sig;
        var env=EnvGen.kr(Env.asr(attack.max(0.01),1,1.3),gate,doneAction:2);
        guitar=HPF.ar(guitar,95);
        room=FreeVerb2.ar(guitar[0]+(drums[0]*0.18),guitar[1]+(drums[1]*0.18),0.12,0.38,0.6);
        sig=(room*0.75)+(guitar*0.25)+bass+drums;
        sig=HPF.ar(LeakDC.ar(sig),27);
        sig=Compander.ar(sig,sig,0.48,1,0.72,0.008,0.14);
        Out.ar(out,Limiter.ar(sig*Lag.kr(amp.clip(0,2),0.1),0.85)*env);
    })
];
)
