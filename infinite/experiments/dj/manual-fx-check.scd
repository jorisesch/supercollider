// Offline signal probe: a held sixteenth stutter lasts six bars, then releases.
// No hardware playback. Optional output path; the default stays in the temp dir.
(
var root=thisProcess.nowExecutingPath.dirname;
var output=thisProcess.argv.at(0) ? (Platform.defaultTempDir +/+ "dj-manual-fx-check.wav");
var score=List.new,engine,probe,beat=60/128,time=0.1,duration,osc;
try {
    (root +/+ "engine.scd").load;(root +/+ "instruments.scd").load;
    engine=~makeDJEngine.value(2600,128,(hold:true,autoStutter:false));
    probe=SynthDef(\djFXProbe,{Out.ar(16,SinOsc.ar(997,0,0.12)!2)});
    TempoClock.default.tempo=1;
    score.add([0] ++ (~djDefs ++ [probe]).collect { |def| [\d_recv,def.asBytes] });
    score.add([0.01,[\g_new,100,0,1],[\s_new,\djFXProbe,700,0,100],
        [\s_new,\djDeck,800,1,100,\in,16,\out,28,\musicGain,1,\bassGain,0,\drumsGain,0],
        [\s_new,\djDeck,801,1,100,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0],
        [\s_new,\djMaster,999,1,100,\in,28]]);
    10.do { |bar|
        var frame;
        if(bar==2) {engine[\startFX].value(\stutter16)};
        if(bar==8) {engine[\stopFX].value};
        frame=engine[\nextBar].value;
        frame.automation.do { |point|
            score.add([time+(point.beat*beat)] ++ ~djAutomation.value(point,[800,801]));
        };
        time=time+(4*beat);
    };
    score.add([time,[\n_set,999,\gate,0]]);duration=time+4;
    score.add([duration,[\c_set,0,0]]);
    osc=Platform.defaultTempDir +/+ "dj-manual-fx-check.osc";
    Score(score.asArray).recordNRT(oscFilePath:osc,outputFilePath:output,
        sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:duration,
        options:ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false),
        action:{ |code|File.delete(osc);("Manual FX signal probe: " ++ output).postln;code.exit});
} { |error|error.reportError;1.exit};
)
