(
var root = thisProcess.nowExecutingPath.dirname;
var pending = 4;
var render;
(root +/+ "instruments.scd").load;
TempoClock.default.tempo = 1;
render = { |name, events, duration|
    var options = ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0);
    Score(events).recordNRT(
        oscFilePath: root +/+ "audio" +/+ (name ++ ".osc"),
        outputFilePath: root +/+ "audio" +/+ (name ++ ".wav"),
        sampleRate: 48000, headerFormat: "WAV", sampleFormat: "int24",
        options: options, duration: duration,
        action: { |exitCode|
            (name ++ " render exit: " ++ exitCode).postln;
            pending = pending - 1;
            if(pending == 0) { 0.exit };
        }
    );
};
render.value("quindar-in", [[0, [\d_recv, ~quindarDef.asBytes]], [0.05, [\s_new, \quindar, 1000, 0, 0, \freq, 2525]]], 0.4);
render.value("quindar-out", [[0, [\d_recv, ~quindarDef.asBytes]], [0.05, [\s_new, \quindar, 1000, 0, 0, \freq, 2475]]], 0.4);
render.value("quindar-in-out", [[0, [\d_recv, ~quindarDef.asBytes]], [0.05, [\s_new, \quindar, 1000, 0, 0, \freq, 2525]], [1.3, [\s_new, \quindar, 1001, 0, 0, \freq, 2475]]], 1.8);
render.value("desert-pod-racer", [
    [0, [\d_recv, ~racerDef.asBytes]],
    [0.1, [\s_new, \desertRacer, 1000, 0, 0, \throttle, 0.13]],
    [5, [\n_set, 1000, \throttle, 0.42]],
    [10, [\n_set, 1000, \throttle, 0.78, \grit, 0.7, \pan, -0.2]],
    [16, [\n_set, 1000, \throttle, 0.52, \pan, 0.25]],
    [21, [\n_set, 1000, \throttle, 1, \grit, 0.85, \pan, 0]],
    [27, [\n_set, 1000, \throttle, 0.18]],
    [32, [\n_set, 1000, \gate, 0]]
], 37);
)
