// Audition only: common source, no live master or limiter, diagnostic gain channel.
(
~edmComparisonDefs=[
    SynthDef(\edmComparisonMix,{|in=28,out=0,gate=1|
        var env=EnvGen.kr(Env.asr(0.08,1,2.3),gate,doneAction:2);
        Out.ar(out,HPF.ar(LeakDC.ar(In.ar(in,2)),25)*env);
    }),
    SynthDef(\edmComparisonCompression,{|buffer=0,legacy=0,threshold=0.055,ratio=1,attack=0.02,release=0.16|
        var audio=PlayBuf.ar(2,buffer,BufRateScale.kr(buffer),doneAction:2);
        var linkedGain=~djPopCompressionGain.value(audio,threshold,ratio,attack,release);
        // Same detector, drive and timing as djMaster. Remove the constant drive
        // afterward so the package can match levels without favoring louder takes.
        var driven=audio*3.4;
        var legacyGain=Compander.ar(DC.ar([1,1]),driven,0.48,1,0.55,0.006,0.12);
        var gain=Select.ar(legacy,[linkedGain,legacyGain]);
        Out.ar(0,(audio*gain)++[gain[0].min(gain[1])*0.5]);
    })
];
)
