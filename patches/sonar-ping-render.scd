// Standalone batch renderer. Exits sclang when finished.
(
var root = thisProcess.nowExecutingPath.dirname;
(root +/+ "sonar-ping.scd").load;
Score([
    [0, [\d_recv, ~sonarPingDef.asBytes]],
    [0.1, [\s_new, \sonarPing, 1000, 0, 0,
        \freq, 960, \decay, 4.2, \reverb, 0.42, \water, 0.14,
        \hull, 0.34, \creakRate, 0.28]]
]).recordNRT(
    oscFilePath: root.dirname +/+ "audio/sonar-ping.osc",
    outputFilePath: root.dirname +/+ "audio/sonar-ping.wav",
    sampleRate: 48000, headerFormat: "WAV", sampleFormat: "int24",
    options: ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0),
    duration: 9, action: { |code| ("sonar-ping render exit: " ++ code).postln; code.exit }
);
)
