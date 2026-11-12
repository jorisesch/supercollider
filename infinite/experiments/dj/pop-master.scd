// The selected EDM and Pop compressor. Stereo channels share the same gain envelope.
(
~djPopCompressionGain={|audio,threshold=0.027,ratio=4,attack=0.004,release=0.18|
    var sidechain=HPF.ar(audio,110);
    var detector=sidechain[0].abs.max(sidechain[1].abs);
    Compander.ar(DC.ar(1),detector,threshold.clip(0.005,0.8),1,
        ratio.clip(1,10).reciprocal,attack.clip(0.001,0.1),release.clip(0.03,0.6));
};
~djDefs=~djDefs++[
    SynthDef(\djPopMaster,{|in=28,out=0,gate=1,amp=0.92,attack=0.1,drive=3.4|
        var env=EnvGen.kr(Env.asr(attack.max(0.02),1,3),gate,doneAction:2);
        var audio=HPF.ar(LeakDC.ar(In.ar(in,2)),25);
        var compressed=audio*~djPopCompressionGain.value(audio);
        // Restore the compression loss before the existing output safety limiter.
        var output=compressed*Lag.kr(drive.clip(0.5,4),0.1)*1.9;
        Out.ar(out,Limiter.ar(output,0.82)*amp*env);
    })
];
)
