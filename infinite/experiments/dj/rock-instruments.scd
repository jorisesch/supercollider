// Channel-specific stock-UGen instruments: plucked strings, cabinet and a room kit.
// Separate from EDM/Pop graphs so refining Rock leaves their sound intact.
(
var root=thisProcess.nowExecutingPath.dirname;
~djDefs=~djDefs++[
    SynthDef(\rockGuitar,{|out=0,freq=110,amp=0.08,sustain=0.3,pan=0,seed=1,color=0,tone=0.5,drive=0.4,mute=0.5,fuzz=0,wah=0,slap=0|
        var pitch=freq.clip(65,1600),damp=mute.clip(0,1),env,pick,wire,body,pre,sig,fuzzed,swept,signal;
        RandSeed.ir(1,seed);pitch=pitch*Rand(0.9988,1.0012);
        env=EnvGen.kr(Env.linen(0.002,sustain.clip(0.03,4),0.09,curve:-3));
        Line.kr(0,1,sustain.clip(0.03,4)+0.10+((slap>0)*0.5),doneAction:2);
        pick=(WhiteNoise.ar*0.75)+(HPF.ar(WhiteNoise.ar,1800)*0.2);
        pick=pick*EnvGen.kr(Env.perc(0.0004,0.009));
        wire=Pluck.ar(pick,Impulse.kr(0),0.04,pitch.reciprocal,3.8-(damp*3.3),0.22+(damp*0.4));
        body=(SinOsc.ar(pitch)*0.065)+(SinOsc.ar(pitch*2)*0.022);
        body=body*EnvGen.kr(Env.perc(0.002,0.12+(sustain.clip(0.03,4)*0.35)));
        pre=HPF.ar(LeakDC.ar(wire+body),85);
        pre=pre+(BPF.ar(pre,850,0.8)*0.22);
        sig=(pre*(1.5+(drive.clip(0,1)*18))).tanh/(1+(drive.clip(0,1)*0.9));
        fuzzed=LPF.ar(LeakDC.ar((sig*8).clip2(0.65)),2600)*0.8;
        sig=(sig*(1-fuzz.clip(0,0.8)))+(fuzzed*fuzz.clip(0,0.8));
        // A small cabinet: broad mids, restrained fizz, no resonant synth sweep.
        sig=LPF.ar(LPF.ar(sig,4100+(tone.clip(0,1)*1600)),6500);
        sig=HPF.ar(sig,100)+(BPF.ar(sig,1700,0.85)*0.16);
        swept=BPF.ar(sig,EnvGen.kr(Env([600,1800,750],[0.05,sustain.max(0.06)])),0.55)*1.8;
        sig=(sig*(1-wah.clip(0,0.7)))+(swept*wah.clip(0,0.7));
        signal=sig*env;
        signal=signal+(DelayC.ar(signal,0.2,0.115)*slap.clip(0,1)*0.35);
        Out.ar(out,Pan2.ar(LeakDC.ar(signal)*amp,pan));
    }),
    SynthDef(\rockBass,{|out=0,freq=55,amp=0.22,sustain=0.35,seed=1,pan=0,tone=0.5,drive=0.3|
        var pitch=freq.clip(28,250),env,string,sig;
        RandSeed.ir(1,seed);
        env=EnvGen.kr(Env.linen(0.004,sustain.clip(0.04,4),0.08,curve:-3),doneAction:2);
        string=Pluck.ar(WhiteNoise.ar(0.45),Impulse.kr(0),0.04,pitch.reciprocal,2.2,0.55);
        sig=LPF.ar(string*1.4,850)+(SinOsc.ar(pitch)*0.55)+(LFTri.ar(pitch)*0.10);
        sig=(sig*1.3).tanh+(HPF.ar((sig*4).tanh,220)*drive.clip(0,1)*0.12);
        Out.ar(out,Pan2.ar(LeakDC.ar(sig)*env*amp,pan));
    }),
    SynthDef(\rockKick,{|out=0,amp=0.4,seed=1|
        var env=EnvGen.kr(Env.perc(0.001,0.28,curve:-5),doneAction:2),pitch,beater,sig;
        RandSeed.ir(1,seed);
        pitch=EnvGen.kr(Env([135,62,49],[0.012,0.10],[-5,-3]));
        beater=BPF.ar(WhiteNoise.ar,2400,0.7)*EnvGen.kr(Env.perc(0.0005,0.012))*0.14;
        sig=(SinOsc.ar(pitch)*1.1).tanh*env+beater;
        Out.ar(out,Pan2.ar(sig*amp));
    }),
    SynthDef(\rockSnare,{|out=0,amp=0.25,pan= -0.06,seed=1|
        var body,wire,sig,env;
        RandSeed.ir(1,seed);
        env=EnvGen.kr(Env.perc(0.001,0.20,curve:-4),doneAction:2);
        body=(SinOsc.ar(185)*0.60)+(SinOsc.ar(335)*0.18);
        body=body*EnvGen.kr(Env.perc(0.001,0.085,curve:-3));
        wire=HPF.ar(LPF.ar(WhiteNoise.ar,7800),1200)*env*0.55;
        sig=body+wire;
        Out.ar(out,Pan2.ar(sig*amp,pan));
    }),
    SynthDef(\rockHat,{|out=0,amp=0.05,sustain=0.06,pan=0.25,seed=1|
        var env=EnvGen.kr(Env.perc(0.001,sustain.clip(0.025,0.35),curve:-5),doneAction:2),sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(WhiteNoise.ar,6200)+(BPF.ar(WhiteNoise.ar,9100,0.3)*0.25);
        Out.ar(out,Pan2.ar(LPF.ar(sig,12000)*env*amp,pan));
    }),
    SynthDef(\rockTom,{|out=0,freq=130,amp=0.20,pan=0,seed=1|
        var env=EnvGen.kr(Env.perc(0.001,0.30,curve:-5),doneAction:2),pitch,sig;
        RandSeed.ir(1,seed);pitch=freq.clip(70,220)*EnvGen.kr(Env([1.25,1],[0.04],-4));
        sig=SinOsc.ar(pitch)+(SinOsc.ar(pitch*1.58)*0.16);
        sig=sig+(LPF.ar(WhiteNoise.ar,2200)*EnvGen.kr(Env.perc(0.001,0.01))*0.10);
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    }),
    SynthDef(\rockCrash,{|out=0,amp=0.075,pan= -0.25,seed=1|
        var env=EnvGen.kr(Env.perc(0.002,1.7,curve:-4),doneAction:2),sig;
        RandSeed.ir(1,seed);sig=HPF.ar(PinkNoise.ar,2800)+(BPF.ar(WhiteNoise.ar,7400,0.6)*0.3);
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    }),
    SynthDef(\rockDeck,{|in=16,out=28,musicGain=1,bassGain=1,drumsGain=1,bpm=102,
        fxFilter=0,fxCutoff=12000,fxResonance=0.35,fxEcho=0,fxDelay=0.75,fxReverb=0.08,fxStutter=0,
        fxStutterRate=4,t_stutter=0|
        var music=HPF.ar(In.ar(in,2),100)*2.0,bass=LPF.ar(In.ar(in+2,2),1800)*0.72,drums=In.ar(in+4,2)*1.15;
        var musicLevel=Lag.kr(musicGain,0.02),bassLevel=Lag.kr(bassGain,0.02),drumsLevel=Lag.kr(drumsGain,0.02);
        var delay=Lag.kr(fxDelay.clip(0.08,0.75),0.5)*(60/Lag.kr(bpm.clip(72,140),3));
        var echo,verb,room,program,filtered,phase,gate;
        // A short drum room and a stable bass level replace EDM sidechain pumping.
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
(root+/+"rock-expressive-instruments.scd").load;
(root+/+"rock-circuits.scd").load;
(root+/+"rock-physical-instruments.scd").load;
)
