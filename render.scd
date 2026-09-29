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
render.value("rocket-launch", [
    [0, [\d_recv, ~rocketDef.asBytes], [\d_recv, ~countdownDef.asBytes]],
    [0.1, [\s_new, \launchBeep, 1100, 0, 0]],
    [1.1, [\s_new, \launchBeep, 1101, 0, 0]],
    [2.1, [\s_new, \launchBeep, 1102, 0, 0]],
    [3.1, [\s_new, \launchBeep, 1103, 0, 0]],
    [4.1, [\s_new, \launchBeep, 1104, 0, 0]],
    [5.1, [\s_new, \launchBeep, 1105, 0, 0, \freq, 1320, \dur, 0.35]],
    [5.1, [\s_new, \rocketEngine, 1000, 0, 0, \throttle, 0.45]],
    [11.0, [\n_set, 1000, \throttle, 0.62]],
    [17.0, [\n_set, 1000, \throttle, 0.5]],
    [20.0, [\n_set, 1000, \malfunction, 0.95]],
    [22.0, [\n_set, 1000, \malfunction, 0.55, \throttle, 0.3]],
    [24.0, [\n_set, 1000, \malfunction, 0, \throttle, 0.8]],
    [30.0, [\n_set, 1000, \throttle, 0.5]],
    [34.0, [\n_set, 1000, \malfunction, 0.7]],
    [35.2, [\n_set, 1000, \malfunction, 0, \throttle, 0.72]],
    [39.0, [\n_set, 1000, \gate, 0]]
], 43);
)
