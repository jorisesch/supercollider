(
var root=thisProcess.nowExecutingPath.dirname;
(root+/+"instruments.scd").load;
(root+/+"track.scd").load;
TempoClock.default.tempo=1;
Score(~neonScore.value).recordNRT(
    oscFilePath: root+/+"../audio/neon-rush.osc",
    outputFilePath: root+/+"../audio/neon-rush.wav",
    sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",
    options:ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0),
    duration:~neonDuration,action:{ |code| code.exit; }
);
)
