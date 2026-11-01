(
~neonDefs = [
SynthDef(\neonKick, { |out=0, amp=0.7|
    var e=EnvGen.kr(Env.perc(0.002,0.36),doneAction:2);
    var f=EnvGen.kr(Env([145,48,43],[0.035,0.25],-6));
    var sig=SinOsc.ar(f)*e + (HPF.ar(WhiteNoise.ar,6000)*EnvGen.kr(Env.perc(0.001,0.018))*0.16);
    Out.ar(out,Pan2.ar(sig.tanh*amp));
}),
SynthDef(\neonHat, { |out=0, amp=0.1, dur=0.08, pan=0|
    RandSeed.ir(1,197);
    Out.ar(out,Pan2.ar(HPF.ar(WhiteNoise.ar,7500)*EnvGen.kr(Env.perc(0.001,dur),doneAction:2)*amp,pan));
}),
SynthDef(\neonClap, { |out=0, amp=0.2|
    RandSeed.ir(1,201);
    Out.ar(out,Pan2.ar(BPF.ar(WhiteNoise.ar,1700,0.8)*EnvGen.kr(Env([0,1,0.1,0.8,0.1,0.65,0],[0.001,0.009,0.001,0.009,0.001,0.15]),doneAction:2)*amp));
}),
SynthDef(\neonBass, { |out=0, freq=110, amp=0.25, dur=0.16|
    var e=EnvGen.kr(Env.perc(0.003,dur),doneAction:2);
    var sig=LPF.ar(Saw.ar(freq*[1,1.004]).sum*0.4,350+(e*1800))+SinOsc.ar(freq)*0.6;
    Out.ar(out,Pan2.ar(LeakDC.ar(sig)*e*amp));
}),
SynthDef(\neonLead, { |out=0, freq=440, amp=0.12, dur=0.14, bright=6000, pan=0|
    var e=EnvGen.kr(Env.perc(0.006,dur,1,-3),doneAction:2);
    var sig=Mix(Saw.ar(freq*[0.989,0.996,1,1.004,1.011]))*0.17;
    sig=RLPF.ar(sig,(bright* (0.4+(e*0.6))).clip(200,14000),0.7);
    Out.ar(out,Pan2.ar(sig*e*amp,pan));
}),
SynthDef(\neonPad, { |out=0, freq=220, amp=0.08, dur=1.5|
    var e=EnvGen.kr(Env.linen(0.15,dur,0.6),doneAction:2);
    var sig=Splay.ar(Saw.ar(freq*[0.997,1,1.003]))*0.3;
    Out.ar(out,LPF.ar(sig,1900)*e*amp);
}),
SynthDef(\neonRise, { |out=0, amp=0.15, dur=7|
    var e=EnvGen.kr(Env.linen(dur,0,0.1),doneAction:2);
    Out.ar(out,Pan2.ar(BPF.ar(WhiteNoise.ar,XLine.kr(350,10000,dur),0.4)*e*amp));
}),
SynthDef(\neonMaster, { |out=0, in=16, amp=0.8|
    var dry=In.ar(in,2);
    var wet=CombC.ar(HPF.ar(dry,650),0.5,[0.326087,0.434783],1.1)*0.12;
    var sig=LeakDC.ar(dry+wet+FreeVerb2.ar(dry[0],dry[1],0.16,0.65,0.5));
    Out.ar(out,Limiter.ar(sig*amp,0.88));
})
];
)
