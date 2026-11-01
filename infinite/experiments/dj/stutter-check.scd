// NRT signal test: one quarter-note bar, two eighth-note bars,
// four sixteenth-note bars, bypass, a half-bar sixteenth hit, then bypass.
// Args: optional output WAV path. The score is temporary; the WAV stays for checking.
(
var root=thisProcess.nowExecutingPath.dirname,engine,score=List.new,bpm=120,barSeconds=2;
var output=thisProcess.argv.at(0) ? (Platform.defaultTempDir +/+ "dj-stutter-check.wav");
var osc=Platform.defaultTempDir +/+ "dj-stutter-check.osc",duration=20.2,cursor=0;
try {
    (root +/+ "engine.scd").load; (root +/+ "instruments.scd").load;
    engine=~makeDJEngine.value(2600,bpm,(autoStutter:false));
    TempoClock.default.tempo=1;
    score.add([0] ++ ~djDefs.collect { |def| [\d_recv,def.asBytes] });
    score.add([0,[\d_recv,SynthDef(\djStutterProbe,{ |out=16|
        Out.ar(out,SinOsc.ar(440)!2 * 0.06);
    }).asBytes]]);
    score.add([0.01,[\g_new,100,0,1],
        [\s_new,\djStutterProbe,700,0,100,\out,16],
        [\s_new,\djDeck,800,1,100,\in,16,\out,0,\fxEcho,0,\fxReverb,0,\bpm,bpm],
        [\s_new,\djDeck,801,1,100,\in,22,\out,0,\musicGain,0,\bassGain,0,\drumsGain,0,\fxEcho,0,\fxReverb,0,\bpm,bpm]]);
    [[\stutter4,1],[\stutter8,2],[\stutter16,4],[nil,1],[\stutter16,0.5],[nil,1]].do { |segment|
        if(segment[0].notNil) {engine[\requestFX].value(segment[0],segment[1])};
        segment[1].ceil.asInteger.do {
            var frame=engine[\nextBar].value;
            frame.automation.do { |point|
                // Isolate the gate from musical mutes, sends and filters.
                point.gains=[[1,0,0],[0,0,0]];
                point.fx.do { |fx| fx.filter=0; fx.echo=0; fx.reverb=0 };
                score.add([0.1+(cursor*barSeconds)+(point.beat*60/bpm)] ++ ~djAutomation.value(point,[800,801]));
            };
            cursor=cursor+1;
        };
    };
    score.add([20.1,[\g_freeAll,100]]);
    score.add([duration,[\c_set,0,0]]);
    Score(score.asArray).recordNRT(oscFilePath:osc,outputFilePath:output,
        sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",
        options:ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false),
        duration:duration,action:{ |code|
            File.delete(osc);
            if(code==0) {("Stutter signal test rendered: " ++ output).postln};
            code.exit;
        });
} { |error| error.reportError; 1.exit };
)
