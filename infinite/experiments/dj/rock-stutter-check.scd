// Offline waveform probe for all three stutter divisions at Rock tempo limits.
// Optional output WAV path; its timing table is written beside it.
(
var root=thisProcess.nowExecutingPath.dirname,score=List.new,at=0.1,rows=List.new;
var output=thisProcess.argv.at(0) ? (Platform.defaultTempDir+/+"dj-rock-stutter-check.wav");
try {
    var probe;
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;
    TempoClock.default.tempo=1;
    probe=SynthDef(\rockStutterProbe,{Out.ar(16,SinOsc.ar(997,0,0.03)!2)});
    (~djDefs++[probe]).do {|d|score.add([0,[\d_recv,d.asBytes]])};
    score.add([0.01,[\g_new,100,0,1],[\s_new,\rockStutterProbe,700,0,100],
        [\s_new,\rockPhysicalDeck,800,1,100,\in,16,\out,0,\musicGain,1,\bassGain,0,\drumsGain,0],
        [\s_new,\rockPhysicalDeck,801,1,100,\in,22,\out,0,\musicGain,0,\bassGain,0,\drumsGain,0]]);
    [78,102,124].do {|bpm|[4,8,16].do {|division|
        var engine=~makeDJEngine.value(2600,bpm,(channel:\rock,hold:true,autoStutter:false)),seconds=4*60/bpm;
        engine[\startFX].value(("stutter"++division).asSymbol);
        2.do {|bar|
            var frame;
            if(bar==1){engine[\stopFX].value};frame=engine[\nextBar].value;
            rows.add([bpm,division,bar,at,seconds]);
            frame.automation.do {|point|
                point.gains=[[1,0,0],[0,0,0]];
                point.fx.do {|fx|fx.filter=0;fx.echo=0;fx.reverb=0;fx.guitarComp=0;fx.guitarChorus=0;fx.guitarPedal=0;fx.guitarFuzz=0};
                score.add([at+(point.beat*60/bpm)]++~djAutomation.value(point,[800,801]));
            };
            at=at+seconds;
        };
    }};
    File.use(output++".tsv","w",{|f|
        f.write("bpm\tdivision\tbypass\tstart\tduration\n");rows.do {|r|f.write(r.collect(_.asString).join("\t")++"\n")};
    });
    score.add([at+0.1,[\g_freeAll,100]]);score.add([at+0.3,[\c_set,0,0]]);
    Score(score.asArray).recordNRT(oscFilePath:Platform.defaultTempDir+/+"rock-stutter-probe.osc",outputFilePath:output,
        sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:at+0.3,
        options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2).memSize_(65536).numWireBufs_(128).loadDefs_(false),
        action:{|code|code.exit});
} {|e|e.reportError;1.exit};
)
