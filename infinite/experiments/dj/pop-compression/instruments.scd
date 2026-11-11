// Audition processing only. Stereo channels share one detector and gain envelope.
(
~popComparisonDefs=[
    SynthDef(\popComparisonMix,{|in=28,out=0,gate=1|
        var env=EnvGen.kr(Env.asr(0.08,1,2.3),gate,doneAction:2);
        Out.ar(out,HPF.ar(LeakDC.ar(In.ar(in,2)),25)*env);
    }),
    SynthDef(\popComparisonCompression,{|buffer=0,threshold=0.055,ratio=2.5,attack=0.02,release=0.16|
        var audio=PlayBuf.ar(2,buffer,BufRateScale.kr(buffer),doneAction:2);
        var gain=~djPopCompressionGain.value(audio,threshold,ratio,attack,release);
        // The third channel records the applied gain for numerical verification.
        Out.ar(0,(audio*gain)++[gain*0.5]);
    })
];
)
