// Stock-UGen expressive string and guitar-only strip. Pedal-inspired colors,
// not circuit models of BD-2, Tube Screamer or DS-1 hardware.
(
~djGuitarPitch={|freq,fromFreq,slideTime,bendSemis,bendMode,vibrato,vibratoRate,hold|
    var target=freq.clip(65,1800),start=Select.kr(fromFreq>0,[target,fromFreq.clip(65,1800)]);
    var progress=Line.kr(0,1,slideTime.clip(0.004,0.25)),bend,approach,returning,vibEnv;
    returning=EnvGen.kr(Env([0,0,bendSemis,bendSemis,0,0],hold*[0.12,0.18,0.25,0.25,0.20],[-2,-2,0,-2,0]));
    approach=EnvGen.kr(Env([bendSemis.neg,0,0],hold*[0.35,0.65],[-2,0]));
    bend=Select.kr(bendMode.clip(0,2),[0,returning,approach]);
    vibEnv=EnvGen.kr(Env([0,0,1,1,0,0],hold*[0.20,0.15,0.30,0.20,0.15],\sin));
    target*(start/target).pow(1-progress)*(bend+(SinOsc.kr(vibratoRate.clip(4,7))*vibrato.clip(0,0.25)*vibEnv)).midiratio;
};
~djDefs=~djDefs++[
    SynthDef(\rockExpressiveGuitar,{|out=0,freq=110,amp=0.08,sustain=0.3,pan=0,seed=1,color=0,tone=0.5,drive=0.4,mute=0.5,fuzz=0,wah=0,slap=0,
        fromFreq=0,slideTime=0,bendSemis=0,bendMode=0,vibrato=0,vibratoRate=5.3,pedal=1,pedalGain=0.35,pick=0.45|
        var hold=sustain.clip(0.03,4),damp=mute.clip(0,1),pitch,env,excitation,wire,body,pre,clean,open,mid,hard,sig,swept,signal;
        var gain=pedalGain.clip(0,0.85),strength=(amp/0.08).sqrt.clip(0.55,1.35);
        RandSeed.ir(1,seed);
        pitch=~djGuitarPitch.value(freq,fromFreq,slideTime,bendSemis.clip(0,2),bendMode,vibrato,vibratoRate,hold);
        pitch=pitch*Rand(0.9995,1.0005);
        env=EnvGen.kr(Env.linen(0.002,hold,0.09,curve:-3));
        Line.kr(0,1,hold+0.10+((slap>0)*0.5),doneAction:2);
        excitation=((WhiteNoise.ar*0.68)+(PinkNoise.ar*0.18)+(HPF.ar(WhiteNoise.ar,2100)*0.14));
        excitation=excitation*EnvGen.kr(Env.perc(0.0004,0.008))*Rand(0.90,1.10);
        wire=Pluck.ar(excitation,Impulse.kr(0),0.04,pitch.reciprocal,5.0-(damp*4.3),0.18+(damp*0.45));
        // Pickup-position comb and a few decaying string/body modes retain attack.
        wire=wire-(DelayC.ar(wire,0.02,(pitch.reciprocal*pick.clip(0.2,0.7)))*0.30);
        body=(SinOsc.ar(pitch)*0.075)+(SinOsc.ar(pitch*2.001)*0.026)+(SinOsc.ar(pitch*3.002)*0.009);
        body=body*EnvGen.kr(Env([0,1,0.28,0.28,0],[0.003,hold*0.70,hold*0.30,0.09],[-2,-2,0,-4]));
        pre=HPF.ar(LeakDC.ar(wire+body),80)*strength;
        pre=pre+(BPF.ar(pre,850,0.85)*0.18);
        clean=pre*2.2;
        open=((pre*(2+(gain*12))+0.10).tanh-0.10.tanh)*(0.72/(1+(gain*0.35)));
        mid=HPF.ar(pre,190);mid=mid+(BPF.ar(mid,820,0.8)*0.90);
        mid=LPF.ar((mid*(3+(gain*18))).tanh,4500)*(0.55/(1+(gain*0.20)));
        hard=HPF.ar(pre,100)+(BPF.ar(pre,2800,0.8)*0.18);
        hard=(hard*(5+(gain*28))).clip2(0.72)*0.72;
        hard=hard-(BPF.ar(hard,850,0.9)*0.22);
        sig=Select.ar(pedal.clip(0,3),[clean,open,mid,hard]);
        sig=(sig*(1-fuzz.clip(0,0.6)))+(LPF.ar(LeakDC.ar((sig*7).clip2(0.65)),2800)*fuzz.clip(0,0.6)*0.75);
        sig=HPF.ar(LPF.ar(LPF.ar(sig,4000+(tone.clip(0,1)*1800)),6800),95);
        sig=sig+(BPF.ar(sig,1650,0.85)*0.12);
        swept=BPF.ar(sig,EnvGen.kr(Env([600,1800,750],[0.05,hold])),0.55)*1.8;
        sig=(sig*(1-wah.clip(0,0.7)))+(swept*wah.clip(0,0.7));
        signal=sig*env;
        signal=signal+(DelayC.ar(signal,0.2,0.115)*slap.clip(0,1)*0.35);
        Out.ar(out,Pan2.ar(LeakDC.ar(signal)*amp/strength,pan));
    }),
    SynthDef(\rockGuitarDeck,{|in=16,out=28,musicGain=1,bassGain=1,drumsGain=1,bpm=102,
        fxFilter=0,fxCutoff=12000,fxResonance=0.35,fxEcho=0,fxDelay=0.75,fxReverb=0.08,fxStutter=0,fxStutterRate=4,t_stutter=0,
        guitarComp=0,guitarChorus=0|
        var music=HPF.ar(In.ar(in,2),100)*2.0,bass=LPF.ar(In.ar(in+2,2),1800)*0.72,drums=In.ar(in+4,2)*1.15;
        var musicLevel=Lag.kr(musicGain,0.02),bassLevel=Lag.kr(bassGain,0.02),drumsLevel=Lag.kr(drumsGain,0.02);
        var delay=Lag.kr(fxDelay.clip(0.08,0.75),0.5)*(60/Lag.kr(bpm.clip(72,140),3));
        var amount=Lag.kr(guitarComp.clip(0,0.8),0.08),chorus=Lag.kr(guitarChorus.clip(0,0.35),0.2),compressed,modulated;
        var echo,verb,room,program,filtered,phase,gate;
        // Only the music input contains guitars. Bass and drums enter below this strip.
        compressed=Compander.ar(music,music.abs.sum*0.5,0.035,1,0.40,0.008,0.13)*1.16;
        music=(music*(1-amount))+(compressed*amount);
        modulated=DelayC.ar(music,0.04,SinOsc.kr([0.27,0.31],[0,1.7]).range(0.012,0.020));
        music=((music*(1-(chorus*0.35)))+(modulated*chorus*0.65));
        room=FreeVerb2.ar(drums[0],drums[1],1,0.34,0.65)*0.08;
        echo=LPF.ar(CombC.ar(HPF.ar(music,450)*Lag.kr(fxEcho.clip(0,1),0.06),2,delay,2.6),3900)*0.35;
        verb=FreeVerb2.ar(music[0],music[1],1,0.52,0.6)*Lag.kr(fxReverb.clip(0,1),0.4)*0.22;
        program=((music+echo+verb)*musicLevel)+(bass*bassLevel)+((drums+room)*drumsLevel);
        filtered=RLPF.ar(program,Lag.kr(fxCutoff.clip(500,18000),0.08),Lag.kr(fxResonance.clip(0.25,0.9),0.08));
        program=(program*(1-Lag.kr(fxFilter.clip(0,1),0.06)))+(filtered*Lag.kr(fxFilter.clip(0,1),0.06));
        phase=Phasor.kr(t_stutter,(bpm.clip(72,140)/60)*fxStutterRate.clip(1,4)*ControlDur.ir,0,1,0);
        gate=1-(Lag.kr(fxStutter.clip(0,1),0.015)*(1-Lag.kr(phase<0.48,0.006)));
        Out.ar(out,LeakDC.ar(program*gate));
    })
];
)
