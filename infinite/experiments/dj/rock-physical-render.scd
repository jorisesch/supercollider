// Isolated listening study + instrument/control/routing probes. No live playback.
(
var root=thisProcess.nowExecutingPath.dirname,repo=root.dirname.dirname.dirname;
var score=List.new,probe=List.new,strip=List.new,node=2000,pending=3,finish,add;
try {
    var trace,testTone,interaction;
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;TempoClock.default.tempo=1;
    finish={|code|pending=pending-1;if(code!=0){Error("Physical guitar render failed").throw};if(pending==0){0.exit}};
    add={|list,at,note=69,hold=2.9,extra=#[ ],amp=0.08,mute=0.04|
        list.add([at,[\s_new,\rockPhysicalGuitar,node,0,110,\out,16,\freq,note.midicps,\amp,amp,\sustain,hold,
            \stringIndex,5,\mute,mute,\color,0,\pickPosition,0.115,\seed,731]++extra]);node=node+1;
    };
    ~djDefs.do {|d|score.add([0,[\d_recv,d.asBytes]])};
    score.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],
        [\s_new,\rockPhysicalDeck,800,1,100,\in,16,\out,0,\guitarPedal,0,\fxReverb,0]]);
    add.value(score,0.1);add.value(score,4.1,69,2.9,[\bendSemis,2,\bendMode,1]);
    add.value(score,8.1,69,2.9,[\bendSemis,2,\bendMode,2]);
    add.value(score,12.1,69,2.9,[\vibrato,0.35,\vibratoRate,5.2]);
    add.value(score,16.1,69,2.9,[\fromFreq,64.midicps,\slideTime,0.65]);
    8.do {|i|add.value(score,20.1+(i*0.42),52,0.29,[\stringIndex,2],0.10,if(i<4){0.04}{0.85})};
    6.do {|id|
        var start=24.1+(id*6);
        score.add([start-0.02,[\n_set,800,\guitarPedal,[0,1,2,3,0,0][id],\guitarDrive,0.35,
            \guitarFuzz,if(id==4){1}{0},\guitarChorus,if(id==5){0.35}{0},\guitarComp,0.30]]);
        [64,67,69,71,69,67,64].do {|note,i|
            add.value(score,start+(i*0.47),note,if(i==6){1.5}{0.40},
                if(i==6){[\vibrato,0.25]}{[ ]},0.08,0.04);
        };
        [52,59,64].do {|note,i|add.value(score,start+4.1+(i*0.012),note,1.25,[\stringIndex,[2,3,4][i]],0.04,0.06)};
    };
    score.add([60.1,[\n_free,100]]);score.add([60.5,[\c_set,0,0]]);
    Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:Platform.defaultTempDir+/+"rock-physical-study.osc",
        outputFilePath:repo+/+"audio/rock-guitar-study.wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:60.5,
        options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2).numWireBufs_(256).memSize_(65536).loadDefs_(false),action:finish);
    // Probe channels: actual string L/R, fundamental/2000, fret/32, tension/200, zero.
    trace=SynthDef(\rockPhysicalTrace,{|fromFreq=0,slideTime=0,bendSemis=0,bendMode=0,vibrato=0|
        var m=~djStringMotion.value(440,fromFreq,slideTime,bendSemis,bendMode,vibrato,5.2,2.9,5,1);
        Out.ar(2,[K2A.ar(m.fundamental/2000),K2A.ar(m.fret/32),K2A.ar(m.tension/200),DC.ar(0)]);
        Line.kr(0,1,3.0,doneAction:2);
    });
    ~djDefs.do {|d|probe.add([0,[\d_recv,d.asBytes]])};probe.add([0,[\d_recv,trace.asBytes]]);
    probe.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100]]);
    [[],[\bendSemis,2,\bendMode,1],[\bendSemis,2,\bendMode,2],[\vibrato,0.35],
        [\fromFreq,64.midicps,\slideTime,0.65]].do {|args,i|
        var at=0.1+(i*3.4);
        add.value(probe,at,69,2.9,args++[\out,0]);
        probe.add([at,[\s_new,\rockPhysicalTrace,node,1,100]++args]);node=node+1;
    };
    probe.add([17.2,[\c_set,0,0]]);
    Score(probe.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:Platform.defaultTempDir+/+"rock-physical-pitch.osc",
        outputFilePath:Platform.defaultTempDir+/+"rock-physical-pitch.wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:17.2,
        options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(6).numWireBufs_(256).memSize_(65536).loadDefs_(false),action:finish);
    testTone=SynthDef(\rockCircuitProbe,{
        |hz=220|
        var x=SinOsc.ar(hz)*0.2,diode=~djDiode.value(x*8,2200);
        var raw=~djDiodeRoot.value(x*8,2200),comp=~djGuitarCompressor.value([x,x],0.8);
        Out.ar(4,[x,diode,raw,comp[0]]);
    });
    ~djDefs.do {|d|strip.add([0,[\d_recv,d.asBytes]])};strip.add([0,[\d_recv,testTone.asBytes]]);
    strip.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],
        [\s_new,\rockDeck,800,1,100,\in,16,\out,0,\fxReverb,0],
        [\s_new,\rockPhysicalDeck,801,1,100,\in,16,\out,2,\fxReverb,0,\guitarPedal,3,\guitarFuzz,1,\guitarComp,0.8,\guitarChorus,0.35]]);
    8.do {|i|strip.add([0.1+(i*0.5),[\s_new,\rockBass,node,0,110,\out,18,\freq,110,\sustain,0.25,\amp,0.22,\seed,731+i],
        [\s_new,if(i.even){\rockKick}{\rockSnare},node+1,0,110,\out,20,\amp,0.3,\seed,731+i]]);node=node+2};
    strip.add([4.4,[\s_new,\rockCircuitProbe,node,1,100]]);strip.add([5.4,[\n_free,node]]);
    strip.add([5.6,[\s_new,\rockCircuitProbe,node+1,1,100,\hz,6300]]);strip.add([6.6,[\n_free,node+1]]);
    interaction=SynthDef(\rockInteractionProbe,{
        var a=SinOsc.ar(220)*0.12,b=SinOsc.ar(330)*0.12;
        var joined=~djTubeScreamer.value(a+b,0.5,0.5);
        var separate=~djTubeScreamer.value(a,0.5,0.5)+~djTubeScreamer.value(b,0.5,0.5);
        Out.ar(4,[a+b,joined,separate,DC.ar(0)]);
    });
    strip.add([0,[\d_recv,interaction.asBytes]]);
    strip.add([6.8,[\s_new,\rockInteractionProbe,node+2,1,100]]);strip.add([7.8,[\n_free,node+2]]);
    strip.add([8.0,[\c_set,0,0]]);
    Score(strip.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:Platform.defaultTempDir+/+"rock-physical-strip.osc",
        outputFilePath:Platform.defaultTempDir+/+"rock-physical-strip.wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:8,
        options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(8).numWireBufs_(256).memSize_(65536).loadDefs_(false),action:finish);
} {|e|e.reportError;1.exit};
)
