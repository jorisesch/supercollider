// Mono bass foundation with a separate high-passed dub return.
(
~djDefs=~djDefs++[
    SynthDef(\djDubAcid,{|out=0,freq=55,fromFreq=55,glide=0,amp=0.2,sustain=0.15,tone=0.4|
        var pitch=Select.kr(glide>0,[freq,XLine.kr(fromFreq.max(25),freq,glide.max(0.005))]);
        var contour=EnvGen.kr(Env.perc(0.003,0.16,curve:-4));
        var env=EnvGen.kr(Env.linen(0.005,sustain,0.032),doneAction:2);
        var cutoff=(220+(tone*1450)+(contour*(680+(tone*2200)))).clip(160,6500);
        var raw=(Saw.ar(pitch)*0.68)+(Pulse.ar(pitch,0.44)*0.32);
        var acid=HPF.ar((RLPF.ar(raw,cutoff,0.18)*2.8).tanh,76);
        Out.ar(out,Pan2.ar(acid,0,env*amp));
    }),
    SynthDef(\djDubSub,{|out=0,freq=55,amp=0.2,sustain=0.22,tone=0.4|
        var env=EnvGen.kr(Env.linen(0.01,sustain,0.065),doneAction:2);
        var motion=SinOsc.kr(1.1).range(0.70,1);
        var upper=SinOsc.ar(freq*2)*motion*(0.07+(tone*0.18));
        var sig=(SinOsc.ar(freq)*0.86)+upper;
        Out.ar(out,Pan2.ar(sig,0,env*amp));
    }),
    SynthDef(\djDubRim,{|out=0,amp=0.09,pan=0,seed=1|
        var envelope=EnvGen.kr(Env.perc(0.001,0.46,curve:-5),doneAction:2), body, strike, dry, room;
        RandSeed.ir(1,seed);
        body=(SinOsc.ar(182)*0.41)+(SinOsc.ar(344)*0.17);
        strike=BPF.ar(WhiteNoise.ar,1750,0.54)*0.43;
        dry=(body+strike)*EnvGen.kr(Env.perc(0.001,0.074,curve:-5));
        room=DelayC.ar(dry,0.13,[0.052,0.091])*[0.20,0.14];
        Out.ar(out,(Pan2.ar(dry,pan)+room)*envelope*amp);
    }),
    SynthDef(\djDubEcho,{|out=0,freq=440,amp=0.04,sustain=0.08,tone=0.4,pan=0|
        var env=EnvGen.kr(Env.perc(0.005,sustain+0.08));
        var life=EnvGen.kr(Env.linen(0.005,1.28,0.25),doneAction:2);
        var dry=HPF.ar(LPF.ar(Pulse.ar(freq,0.35)+(SinOsc.ar(freq*1.5)*0.4),750+(tone*1700)),190)*env;
        var repeats=LPF.ar(CombC.ar(dry,0.44,[0.318,0.428],0.83),2100);
        Out.ar(out,(Pan2.ar(dry,pan)+(repeats*0.55))*life*amp);
    })
];
)
