// Standalone 32-bar EDM D preview. Renders and exits; no GUI or live clock.
(
var root=thisProcess.nowExecutingPath.dirname, repo=root.dirname.dirname;
var engine, score=List.new, time=0.1, node=1000, bars=32, duration, osc;
try {
    (root +/+ "live.scd").load;
    (root +/+ "d-engine.scd").load;
    (root +/+ "d-instruments.scd").load;
    engine=~makeDExperimentEngine.value(\edm, 2600);
    engine.bpm=126;
    score.add([0] ++ ~experimentDefs.collect { |def| [\d_recv, def.asBytes] });
    score.add([0.01, [\g_new, 1, 0, 0],
        [\s_new, \xpMaster, 999, 1, 1, \in, 16, \bpm, engine.bpm, \fade, 4]]);
    bars.do { |bar|
        engine[\nextBar].value.do { |event|
            score.add([time + ((bar * 4 + event.beat) * 60 / engine.bpm),
                ~experimentMessage.value(event, engine, node, 1, 16)]);
            node=node + 1;
        };
    };
    duration=0.1 + (bars * 4 * 60 / engine.bpm);
    score.add([duration, [\n_set, 999, \gate, 0]]);
    duration=duration + 4;
    score.add([duration, [\c_set, 0, 0]]);
    osc=Platform.defaultTempDir +/+ "infinite-edm-d.osc";
    Score(score.asArray).recordNRT(
        oscFilePath:osc,
        outputFilePath:repo +/+ "audio/infinite-edm-d.wav",
        sampleRate:48000, headerFormat:"WAV", sampleFormat:"int24",
        options:ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false),
        duration:duration,
        action:{ |code| File.delete(osc); if(code == 0) { 0.exit } { 1.exit } }
    );
} { |error| error.reportError; 1.exit };
)
