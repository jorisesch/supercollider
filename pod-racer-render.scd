// Standalone batch renderer. Exits sclang when finished.
(
var root = thisProcess.nowExecutingPath.dirname;
(root +/+ "pod-racer.scd").load;
TempoClock.default.tempo = 1;
Score([
    [0, [\d_recv, ~podRacerDef.asBytes]],
    // A reluctant ignition: the twin pistons carry the first seconds.
    [0.1, [\s_new, \podRacer, 1000, 0, 0,
        \speed, 0.01, \lfoRate, 0.22, \cutoff, 250, \clankRate, 0.9]],
    [2.5, [\n_set, 1000, \speed, 0.04, \lfoRate, 0.34, \cutoff, 320]],
    [5.0, [\n_set, 1000, \speed, 0.12, \lfoRate, 0.52, \cutoff, 420,
        \clankRate, 0.45]],
    // Warm-up and the first gear transition.
    [7.5, [\n_set, 1000, \speed, 0.27, \lfoRate, 0.82, \cutoff, 600, \gear, 1]],
    [8.4, [\n_set, 1000, \gear, 0]],
    [10.5, [\n_set, 1000, \speed, 0.50, \lfoRate, 1.25, \cutoff, 820,
        \clankRate, 0.65]],
    // The racer starts to work well; the first canyon wall catches a pass.
    [12.5, [\n_set, 1000, \speed, 0.70, \lfoRate, 1.9, \cutoff, 1100,
        \gear, 1, \canyon, 0.8, \flyby, 1, \pan, -0.5]],
    [14.0, [\n_set, 1000, \gear, 0, \flyby, 0, \canyon, 0.95, \pan, 0.4]],
    [16.0, [\n_set, 1000, \speed, 0.90, \lfoRate, 2.8, \cutoff, 1450,
        \canyon, 0.4, \gear, 1, \pan, 0.6]],
    [17.2, [\n_set, 1000, \gear, 0, \canyon, 0]],
    // Short max-speed burst and a second, slower fly-by.
    [19.0, [\n_set, 1000, \speed, 0.98, \lfoRate, 4.0, \cutoff, 1800,
        \flyby, 1, \pan, -0.6]],
    [20.5, [\n_set, 1000, \flyby, 0, \pan, 0]],
    [22.5, [\n_set, 1000, \speed, 0.75, \lfoRate, 2.7, \cutoff, 1250,
        \clankRate, 0.4]],
    [24.5, [\n_set, 1000, \speed, 1, \lfoRate, 4.8, \cutoff, 2100,
        \gear, 1, \canyon, 0.75, \flyby, 1]],
    [26.0, [\n_set, 1000, \gear, 0, \flyby, 0, \canyon, 0]],
    [27.5, [\n_set, 1000, \gate, 0]]
]).recordNRT(
    oscFilePath: root +/+ "audio/pod-racer.osc",
    outputFilePath: root +/+ "audio/pod-racer.wav",
    sampleRate: 48000, headerFormat: "WAV", sampleFormat: "int24",
    options: ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0),
    duration: 30, action: { |code| ("pod-racer render exit: " ++ code).postln; code.exit }
);
)
