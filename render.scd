(
var root = thisProcess.nowExecutingPath.dirname;
var pending = 6;
var failed = false;
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
            failed = failed or: { exitCode != 0 };
            pending = pending - 1;
            if(pending == 0) { if(failed) { 1.exit } { 0.exit } };
        }
    );
};
render.value("quindar-in", [[0, [\d_recv, ~quindarDef.asBytes]], [0.05, [\s_new, \quindar, 1000, 0, 0, \freq, 2525]]], 0.4);
render.value("quindar-out", [[0, [\d_recv, ~quindarDef.asBytes]], [0.05, [\s_new, \quindar, 1000, 0, 0, \freq, 2475]]], 0.4);
render.value("quindar-in-out", [[0, [\d_recv, ~quindarDef.asBytes]], [0.05, [\s_new, \quindar, 1000, 0, 0, \freq, 2525]], [1.3, [\s_new, \quindar, 1001, 0, 0, \freq, 2475]]], 1.8);
render.value("quindar-in-noisy", [[0, [\d_recv, ~quindarRadioDef.asBytes]], [0.05, [\s_new, \quindarRadio, 1000, 0, 0, \freq, 2525, \seed, 1962, \variant, 0]]], 0.9);
render.value("quindar-out-noisy", [[0, [\d_recv, ~quindarRadioDef.asBytes]], [0.05, [\s_new, \quindarRadio, 1000, 0, 0, \freq, 2475, \seed, 1969, \variant, 1]]], 0.9);
render.value("desert-pod-racer", [
    [0, [\d_recv, ~racerDef.asBytes]],
    [0.1, [\s_new, \desertRacer, 1000, 0, 0, \throttle, 0.45, \whompPeriod, 1.05]],
    [6, [\n_set, 1000, \throttle, 0.62, \whompPeriod, 0.9]],
    [12, [\n_set, 1000, \throttle, 0.5, \whompPeriod, 1.2]],
    [15, [\n_set, 1000, \malfunction, 0.95]],
    [17, [\n_set, 1000, \malfunction, 0.55, \throttle, 0.3]],
    [19, [\n_set, 1000, \malfunction, 0, \throttle, 0.8, \whompPeriod, 0.8]],
    [25, [\n_set, 1000, \throttle, 0.5, \whompPeriod, 1.1]],
    [29, [\n_set, 1000, \malfunction, 0.7]],
    [30.2, [\n_set, 1000, \malfunction, 0, \throttle, 0.72]],
    [34, [\n_set, 1000, \gate, 0]]
], 38);
)
