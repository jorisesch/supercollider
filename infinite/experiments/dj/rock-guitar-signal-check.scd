// NRT probes for audible pitch gestures and guitar-only dynamics/routing.
// Writes temporary six-channel pitch and four-channel strip measurements.
(
var root=thisProcess.nowExecutingPath.dirname,pending=2,failed=false,finish;
try {
    var cases,score=List.new,probe,node=1000,strip=List.new,stimulus,osc;
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;TempoClock.default.tempo=1;
    finish={|code|failed=failed or:{code!=0};pending=pending-1;if(pending==0){if(failed){1.exit}{0.exit}}};
    cases=[
        [0,0,0,0,0], // plain reference
        [392,0.18,0,0,0], // slide up to A
        [0,0,2,1,0], // bend and return
        [0,0,2,2,0], // bend into the target
        [0,0,0,0,0.20], // delayed vibrato
        [0,0,1,2,0.10] // expressive chord-tone arrival
    ];
    probe=SynthDef(\guitarPitchProbe,{|freq=440,fromFreq=0,slideTime=0,bendSemis=0,bendMode=0,vibrato=0,hold=1.6|
        var model=~djGuitarPitch.value(freq,fromFreq,slideTime,bendSemis,bendMode,vibrato,5.3,hold);
        var measured=Pitch.kr(In.ar(0,2).sum,initFreq:440,minFreq:120,maxFreq:1000,execFreq:100,median:7,ampThreshold:0.001,peakThreshold:0.5);
        Out.ar(2,[K2A.ar(model/2000),K2A.ar(measured[0]/2000),K2A.ar(measured[1]),DC.ar(0)]);
        Line.kr(0,1,hold+0.15,doneAction:2);
    });
    ~djDefs.do {|def|score.add([0,[\d_recv,def.asBytes]])};score.add([0,[\d_recv,probe.asBytes]]);
    cases.do {|c,i|
        var at=0.1+(i*2.2),args=[\freq,440,\fromFreq,c[0],\slideTime,c[1],\bendSemis,c[2],\bendMode,c[3],\vibrato,c[4]];
        score.add([at,[\s_new,\rockExpressiveGuitar,node,0,1,\out,0,\amp,0.25,\sustain,1.6,\mute,0.025,\seed,731,\pedal,0]++args,
            [\s_new,\guitarPitchProbe,node+1,1,1,\hold,1.6]++args]);node=node+2;
    };
    score.add([13.3,[\c_set,0,0]]);osc=Platform.defaultTempDir+/+"rock-guitar-pitch.osc";
    Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:osc,
        outputFilePath:Platform.defaultTempDir+/+"rock-guitar-pitch.wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:13.3,
        options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(6).numWireBufs_(128).memSize_(65536).loadDefs_(false),
        action:{|code|("Pitch signal probe / "++code).postln;finish.value(code)});
    // Both decks read the same buses. Full guitar FX must leave bass/drums identical.
    stimulus=SynthDef(\guitarTestTone,{|out=16,amp=0.1|
        var env=EnvGen.kr(Env.linen(0.01,0.65,0.04),doneAction:2);
        Out.ar(out,Pan2.ar(SinOsc.ar(330)*env*amp));
    });
    ~djDefs.do {|def|strip.add([0,[\d_recv,def.asBytes]])};strip.add([0,[\d_recv,stimulus.asBytes]]);
    strip.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],
        [\s_new,\rockDeck,800,1,100,\in,16,\out,0,\fxReverb,0,\fxEcho,0],
        [\s_new,\rockGuitarDeck,801,1,100,\in,16,\out,2,\fxReverb,0,\fxEcho,0,\guitarComp,0.8,\guitarChorus,0.28]]);
    8.do {|i|
        strip.add([0.1+(i*0.5),[\s_new,\rockBass,2000+(i*3),0,110,\out,18,\freq,110,\sustain,0.25,\amp,0.22,\seed,731+i],
            [\s_new,if(i.even){\rockKick}{\rockSnare},2001+(i*3),0,110,\out,20,\amp,0.3,\seed,731+i]]);
    };
    strip.add([4.2,[\n_set,801,\guitarChorus,0]]);
    [0.01,0.035,0.12,0.24].do {|amp,i|strip.add([5.3+i,[\s_new,\guitarTestTone,3000+i,0,110,\out,16,\amp,amp]])};
    strip.add([10.0,[\c_set,0,0]]);osc=Platform.defaultTempDir+/+"rock-guitar-strip.osc";
    Score(strip.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:osc,
        outputFilePath:Platform.defaultTempDir+/+"rock-guitar-strip.wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:10,
        options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(4).numWireBufs_(128).memSize_(65536).loadDefs_(false),
        action:{|code|("Guitar-only strip probe / "++code).postln;finish.value(code)});
} {|e|e.reportError;1.exit};
)
