// The pickup weights are folded into each mode at note construction. Only
// one string is synthesized per note, and the electrical load is shared.
(
~hpString=SynthDef(\hpString,{|out=16,freq=330,amp=0.55,sustain=0.6,pan=0,stringIndex=4,seed=731,vibrato=0|
    var hold=sustain.clip(0.05,4),zero=DC.kr(0),motion,time,tension,speed2,stiffness,spatial,base,signal,env;
    var ratio=\cHorizontal.ir(0.065).clip(-0.4,0.4);
    RandSeed.ir(1,seed);
    motion=~djStringMotion.value(freq,zero,zero,zero,zero,vibrato.clip(0,0.3),5.3,hold,stringIndex,0,0.115);
    time=Line.kr(0,hold+0.1,hold+0.1);
    tension=motion.tension+(\cEnergy.ir(0)*(((time* -8).exp*0.5)+((time* -1.5).exp*0.5)));
    speed2=tension/motion.mass;stiffness=motion.ei/motion.mass;
    spatial=pi/motion.length;base=(2*motion.length).reciprocal;
    signal=Mix.fill(40,{|i|
        var n=i+1,hz=(speed2+(stiffness*(n*spatial).squared)).sqrt*n*base;
        var q=("cQ"++i).asSymbol.ir(0),phase=("cP"++i).asSymbol.ir(0),damping=("cD"++i).asSymbol.ir(1);
        var vertical,horizontal=0,limit=SampleRate.ir*0.45;
        vertical=SinOsc.ar(hz.min(limit),phase)*((-1*damping*time).exp);
        if(i<12){horizontal=SinOsc.ar((hz*motion.length/(motion.length+0.00008)).min(limit),phase)
            *((time*damping* -0.76).exp)*ratio};
        (vertical+horizontal)*q*2pi*hz*((limit-hz)/1800).clip(0,1);
    });
    env=EnvGen.kr(Env.linen(0.0003,hold,0.07,curve:-4),doneAction:2);
    Out.ar(out,Pan2.ar(LeakDC.ar(signal)*env*amp,pan));
});
~hpCircuitDef={|name,p|
    SynthDef(name,{|in=16,out=28|Out.ar(out,~hpLoad.value(In.ar(in,2),p))});
};
~hpPickupDefs=~hpPresets.collect {|preset|
    ~hpCircuitDef.value(("hpPickup"++preset[\id]).asSymbol,preset[\config])
};
~hpClean=SynthDef(\hpClean,{|in=28,out=0|Out.ar(out,Limiter.ar(LeakDC.ar(In.ar(in,2))*0.32,0.85,0.01))});
~hpDrive=SynthDef(\hpDrive,{|in=28,out=0|
    var x=~djTubeScreamer.value(In.ar(in,2),0.33,0.53),cab;
    cab=HPF.ar(x,75)+(BPF.ar(x,125,0.8)*0.20);
    Out.ar(out,Limiter.ar(LeakDC.ar(LPF.ar(LPF.ar(cab,4700),6200))*0.32,0.85,0.01));
});
// A single shared interfering field, sensed once per guitar, for diagnostics.
~hpHumProbe=SynthDef(\hpHumProbe,{|out=0,weight=1,base=60|
    var field=(SinOsc.ar(base)+(SinOsc.ar(base*2)*0.3)+(SinOsc.ar(base*3)*0.15))*0.018;
    Out.ar(out,(field*weight)!2);
});
~hpDefs=[~hpString,~hpClean,~hpDrive,~hpHumProbe]++~hpPickupDefs;
if(~hpDefs.any {|d|d.asBytes.size>=65000}){Error("Pickup prototype exceeds a portable OSC packet").throw};
)
