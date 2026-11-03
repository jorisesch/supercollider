// Fixed modal initial conditions from contact mechanics; independent finger
// trajectories can then bend each sounding string. Stock UGens only.
(
~gcVoice=SynthDef(\rockContactGuitar,{|out=16,freq=330,amp=1,sustain=0.6,pan=0,stringIndex=4,seed=731|
    var hold=sustain.clip(0.05,4),zero=DC.kr(0),motion,time,energy,tension,speed2,stiffness,spatial,base;
    var signal,env,ratio=\cHorizontal.ir(0.065),pitch;
    RandSeed.ir(1,seed);
    motion=~gpMotion.value(freq,zero,zero,zero,zero,zero,5.3,hold,stringIndex,0,0.115);
    time=Line.kr(0,hold+0.1,hold+0.1);
    energy=\cEnergy.ir(0)*(((time* -8).exp*0.5)+((time* -1.5).exp*0.5));
    tension=motion.tension+energy;speed2=tension/motion.mass;stiffness=motion.ei/motion.mass;
    spatial=pi/motion.length;base=(2*motion.length).reciprocal;
    pitch=(speed2+(stiffness*spatial.squared)).sqrt*base;
    signal=Mix.fill(40,{|i|
        var n=i+1,hz=(speed2+(stiffness*(n*spatial).squared)).sqrt*n*base;
        var q=("cQ"++i).asSymbol.ir(0),phase=("cP"++i).asSymbol.ir(0),damping=("cD"++i).asSymbol.ir(1);
        var vertical,horizontal=0;
        vertical=SinOsc.ar(hz.min(SampleRate.ir*0.45),phase)*((-1*damping*time).exp);
        if(i<12){
            // Small end-compliance difference and separate loss for the second
            // transverse polarization. Not a measured bridge admittance.
            horizontal=SinOsc.ar((hz*motion.length/(motion.length+0.00008)).min(SampleRate.ir*0.45),phase)
                *((time*damping* -0.76).exp)*ratio;
        };
        (vertical+horizontal)*q*2pi*hz*(((SampleRate.ir*0.45)-hz)/1800).clip(0,1);
    });
    signal=RLPF.ar(signal,1/(2pi*(2.5*470e-12).sqrt),0.9);
    env=EnvGen.kr(Env.linen(0.0003,hold,0.07,curve:-4),doneAction:2);
    Out.ar(\cTraceBus.ir(48),[K2A.ar(pitch/2000),K2A.ar(tension/200)]);
    Out.ar(out,Pan2.ar(LeakDC.ar(signal)*env*amp,pan));
});
~djDefs=~djDefs++[~gcVoice];
if(~gcVoice.asBytes.size>=65000){Error("Contact voice exceeds a portable OSC packet").throw};
)
