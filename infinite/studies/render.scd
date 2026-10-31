// Standalone batch process. Optional argument: sample number 1..5. Exits on completion.
(
var root=thisProcess.nowExecutingPath.dirname, repo=root.dirname.dirname;
var indices, position=0, run;
try {
    (root +/+ "instruments.scd").load;
    (root +/+ "tracks.scd").load;
    if(~studyDefs.isNil or: { ~studySpecs.isNil }) { Error("Study source failed to load").throw };
    indices=if(thisProcess.argv.at(0).isNil) { (0..4) } { [thisProcess.argv[0].asInteger-1] };
    if(indices.any { |i| (i < 0) or: { i >= 5 } }) { Error("Choose sample 1..5, or omit the argument for all five").throw };
    TempoClock.default.tempo=1;
    run={
        var spec=~studySpecs[indices[position]], events=~studyEvents.value(spec), score=List.new;
        var node=1000, end=0.1+(128*60/spec.bpm), duration=end+6;
        var osc=Platform.defaultTempDir +/+ (spec.id ++ ".osc");
        var allowed=spec.scale.collect { |note| (spec.keyPC+note)%12 };
        events.do { |event|
            if(event.lane < 2 and: { allowed.includes(event.midinote%12).not }) {
                Error("Out-of-key note in " ++ spec.id ++ ": " ++ event.midinote).throw;
            };
            if(event.beat < 0 or: { event.beat >= 128 } or: { event.duration <= 0 }) {
                Error("Invalid note timing in " ++ spec.id).throw;
            };
        };
        score.add([0] ++ ~studyDefs.collect { |def| [\d_recv,def.asBytes] });
        score.add([0.01,[\g_new,100,0,1],[\s_new,\studyMix,999,1,1] ++ ~studyMixArgs.value(spec,16)]);
        events.do { |event|
            score.add([0.1+(event.beat*60/spec.bpm),~studyMessage.value(event,spec,node,100,16)]);
            node=node+1;
        };
        score.add([end+4,[\n_set,999,\gate,0]]);
        score.add([duration,[\c_set,0,0]]);
        ("Rendering " ++ spec.title ++ " / " ++ spec.bpm ++ " BPM / 32 bars / " ++ events.size ++ " events").postln;
        Score(score.asArray).recordNRT(
            oscFilePath:osc,outputFilePath:repo +/+ "audio" +/+ (spec.id ++ ".wav"),
            sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",
            options:ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0)
                .numWireBufs_(128).memSize_(65536).loadDefs_(false),
            duration:duration,action:{ |code|
                File.delete(osc);
                if(code != 0) { (spec.id ++ " failed: " ++ code).postln; 1.exit } {
                    ("Completed " ++ spec.id).postln;
                    position=position+1;
                    if(position < indices.size) { run.value } { 0.exit };
                };
            }
        );
    };
    run.value;
} { |error| error.reportError; 1.exit };
)
