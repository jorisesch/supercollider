// Renders the standalone study into the repository audio directory.
(
var root = thisProcess.nowExecutingPath.dirname;
var output = root +/+ "../../../audio";
var score = List.new, defs, track, start = 0.14, end, duration, osc, target;
try {
    defs = (root +/+ "instruments.scd").load;
    track = (root +/+ "track.scd").load.value;
    end = start + track[\seconds];
    duration = end + 2.94;
    TempoClock.default.tempo = 1;
    defs.do { |def| score.add([0, [\d_recv, def.asBytes]]) };
    score.add([0.025, [\g_new, 100, 0, 1], [\s_new, \vhMix, 999, 1, 1, \bpm, track[\bpm]]]);
    track[\events].do { |event, i|
        score.add([start + event[0], [\s_new, event[1], 1000 + i, 0, 100] ++ event[2]]);
    };
    score.add([end + 1.45, [\n_set, 999, \gate, 0]]);
    score.add([duration, [\c_set, 0, 0]]);
    osc = output +/+ "voltage-heart-e-minor.osc";
    target = output +/+ "voltage-heart-e-minor.wav";
    "Rendering % events to %".format(track[\events].size, target).postln;
    Score(score.asArray.sort { |a,b| a[0] < b[0] }).recordNRT(
        oscFilePath: osc, outputFilePath: target, sampleRate: 48000, headerFormat: "WAV",
        sampleFormat: "int24", duration: duration,
        options: ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false),
        action: { |code| File.delete(osc); code.exit }
    );
} { |error| error.reportError; 1.exit };
)
