// Opt-in modal voice. The accepted motion function and live SynthDefs stay intact.
(
var acceptedMotion=~djStringMotion;
~gpMotion={|freq,fromFreq,slideTime,bendSemis,bendMode,vibrato,vibratoRate,hold,stringIndex,strength=1,pickPosition=0.12|
    var zero=DC.kr(0),offset=\pOffset.ir(0).clip(-2,0),base,motion,bend,levels,times;
    var depth=\pVDepth.ir(0).clip(0,0.55),delay=\pVDelay.ir(0.3).clip(0,(hold-0.18).max(0));
    var rise=\pVRise.ir(0.1).clip(0.01,(hold-delay-0.12).max(0.01)),span=(hold-delay-rise-0.10).max(0.01);
    var rateStart=\pRateStart.ir(5).clip(3.5,7),rateEnd=\pRateEnd.ir(5).clip(3.5,7.5),rate,wave,envelope,notch;
    var semis,delta,ea,rest,displacement,actualDelta,derivative,left,right;
    base=acceptedMotion.value(freq*offset.midiratio,fromFreq,slideTime,zero,zero,zero,vibratoRate,hold,stringIndex,strength,pickPosition);
    levels=Array.fill(7,{|i|("pB"++i).asSymbol.ir(0).clip(0,2.5)});
    times=Array.fill(6,{|i|("pT"++i).asSymbol.ir(0.2).max(0.003)});
    bend=EnvGen.kr(Env(levels,times,\sin));
    rate=XLine.kr(rateStart,rateEnd,hold)*LFNoise2.kr(1.8,\pWander.ir(0.04).clip(0,0.2),1);
    wave=((1-SinOsc.kr(rate,\pPhase.ir(0)))*0.5).pow(\pSkew.ir(1).clip(0.7,1.5));
    envelope=EnvGen.kr(Env([0,0,\pVGrow.ir(0.5).clip(0.1,1),1,1,0,0],
        [delay,rise,span*0.60,span*0.40,0.06,0.04],\sin));
    // A deliberate relaxation interrupts a few long vibratos, without stopping
    // the hand oscillator or creating a new attack when it resumes.
    notch=1-(EnvGen.kr(Env([0,0,1,1,0,0],hold*[\pNotchAt.ir(0.5),0.06,0.07,0.07,0.30],\sin))*\pNotch.ir(0).clip(0,1));
    envelope=envelope*notch;
    semis=(bend+Select.kr(\pVMode.ir(0).clip(0,2),[
        wave*depth*envelope,(wave-0.5)*depth*envelope,wave.neg*depth*envelope])).max(0);
    // Exact required extra tension (including stiffness), then solve the finger
    // displacement which produces it. A release never slackens below its fret.
    delta=(base.tension+(base.ei*pi.squared/base.length.squared))*((semis*2).midiratio-1);
    ea=(200e9*pi*base.ei).sqrt*2;rest=(0.648-base.length+0.08).max(0.08);
    displacement=(2*delta*0.728/(ea*(base.length.reciprocal+rest.reciprocal))).max(0).sqrt;
    2.do {
        left=(base.length.squared+displacement.squared).sqrt;right=(rest.squared+displacement.squared).sqrt;
        actualDelta=ea/0.728*displacement.squared*((left+base.length).reciprocal+(right+rest).reciprocal);
        derivative=ea/0.728*displacement*(left.reciprocal+right.reciprocal);
        displacement=(displacement-((actualDelta-delta)/derivative.max(1e-7))).max(0);
    };
    actualDelta=ea/0.728*displacement.squared*
        ((base.length+(base.length.squared+displacement.squared).sqrt).reciprocal
        +(rest+(rest.squared+displacement.squared).sqrt).reciprocal);
    motion=base.copy;motion.tension=base.tension+actualDelta;
    motion.fundamental=((motion.tension/motion.mass)+(motion.ei/motion.mass*(pi/motion.length).squared)).sqrt/(2*motion.length);
    Out.ar(\pTraceBus.ir(32),[K2A.ar(motion.fundamental/2000),K2A.ar(bend/4),
        K2A.ar(depth*envelope/2),K2A.ar(rate/16),K2A.ar(base.fret/32),K2A.ar(displacement*20)]);
    motion;
};
~gpBuildVoice={|name,motionFunction|
    SynthDef(name,{|out=0,freq=110,amp=0.08,sustain=0.3,pan=0,seed=1,color=0,mute=0.5,
        fromFreq=0,slideTime=0,bendSemis=0,bendMode=0,vibrato=0,vibratoRate=5.3,stringIndex=3,pickPosition=0.12,articulation=0|
        var hold=sustain.clip(0.03,4),strength=(amp/0.08).clip(0.05,3),motion,time,pluck,pickup,wire,noise,env;
        var speed2,stiffness,spatial,base,coefficient;
        RandSeed.ir(1,seed);
        motion=motionFunction.value(freq,fromFreq,slideTime,bendSemis,bendMode,vibrato,vibratoRate,hold,stringIndex,strength,pickPosition);
        time=Line.kr(0,hold+0.1,hold+0.1);
        pluck=(pickPosition/motion.length).clip(0.04,0.8);
        pickup=(Select.kr(color.clip(0,2),[0.045,0.115,0.055])/motion.length).clip(0.025,0.8);
        // Shared terms keep the graph small enough for a single portable OSC
        // definition while retaining the accepted model's 28 string modes.
        speed2=motion.tension/motion.mass;stiffness=motion.ei/motion.mass;
        spatial=pi/motion.length;base=(2*motion.length).reciprocal;
        coefficient=2*0.00038*strength/(pi.squared*pluck*(1-pluck));
        wire=Mix.fill(28,{|i|
            var n=i+1,hz=(speed2+(stiffness*(n*spatial).squared)).sqrt*n*base;
            var displacement=coefficient*(n*pi*pluck).sin/n.squared;
            var damping=0.48+(n.squared*0.012)+(mute.clip(0,1)*70*(n*0.025*spatial).sin.squared);
            var velocity=displacement*2pi*hz*(n*pi*pickup).sin;
            var aperture=n*0.003*spatial;
            SinOsc.ar(hz.min(SampleRate.ir*0.45))*velocity*(aperture.sin/aperture)*((-1*damping*time).exp)
                *(((SampleRate.ir*0.45)-hz)/1800).clip(0,1);
        });
        noise=HPF.ar(WhiteNoise.ar,2100)*EnvGen.kr(Env.perc(0.0003,0.006))*0.015*strength*(1-articulation);
        noise=noise+(BPF.ar(WhiteNoise.ar,2800,0.7)*Decay2.kr(Changed.kr(motion.fret.round(1))*(slideTime>0),0.0005,0.008)*0.003);
        wire=(wire*Select.kr(articulation,[1,0.68]))+noise;
        wire=RLPF.ar(wire,1/(2pi*(2.5*470e-12).sqrt),0.9);
        env=EnvGen.kr(Env.linen(0.0015,hold,0.085,curve:-4),doneAction:2);
        Out.ar(out,Pan2.ar(LeakDC.ar(wire)*env,pan));
    });
};
~gpVoice=~gpBuildVoice.value(\rockGesturePrototype,~gpMotion);
~gpReference=~gpBuildVoice.value(\rockGestureReference,acceptedMotion);
~djDefs=~djDefs++[~gpVoice,~gpReference];
if(~gpVoice.asBytes.size>=65000){Error("Prototype exceeds a portable OSC packet").throw};
)
