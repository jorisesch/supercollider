// Standalone batch renderer; exits after completion. Never overwrites studies 1..5.
(
var root=thisProcess.nowExecutingPath.dirname,repo=root.dirname.dirname.dirname.dirname;
var outputDir=repo +/+ "audio",score=List.new,node=1000,events,spec,end,duration,osc;
try {
    (root +/+ "instruments.scd").load;
    (root +/+ "track.scd").load;
    if(~discoDefs.isNil or: { ~discoSpec.isNil }) { Error("Disco source failed to load").throw };
    outputDir.mkdir;
    spec=~discoSpec; events=~discoEvents.value;
    end=0.1+(128*60/spec.bpm); duration=end+6;
    osc=Platform.defaultTempDir +/+ (spec.id ++ ".osc");
    events.do { |event|
        if(event.lane < 2 and: { [0,2,4,5,7,9,11].includes(event.midinote%12).not }) {
            Error("Out-of-key note: " ++ event.midinote).throw;
        };
        if(event.beat < 0 or: { event.beat >= 128 } or: { event.duration <= 0 }) {
            Error("Invalid note timing").throw;
        };
    };
    if(events != ~discoEvents.value) { Error("Composition is not reproducible").throw };
    TempoClock.default.tempo=1;
    score.add([0] ++ ~discoDefs.collect { |def| [\d_recv,def.asBytes] });
    score.add([0.01,[\g_new,100,0,1],[\s_new,\discoMix,999,1,1] ++ ~discoMixArgs.value(16)]);
    events.do { |event|
        score.add([0.1+(event.beat*60/spec.bpm),~discoMessage.value(event,node,100,16)]);
        node=node+1;
    };
    score.add([end+4,[\n_set,999,\gate,0]]);
    score.add([duration,[\c_set,0,0]]);
    ("Rendering " ++ spec.title ++ " / 120 BPM / 32 bars / " ++ events.size ++ " events").postln;
    Score(score.asArray).recordNRT(
        oscFilePath:osc,outputFilePath:outputDir +/+ (spec.id ++ ".wav"),
        sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",
        options:ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false),
        duration:duration,action:{ |code|
            File.delete(osc);
            if(code != 0) { ("Render failed: " ++ code).postln; 1.exit } {
                ("Completed " ++ spec.id).postln; 0.exit;
            };
        }
    );
} { |error| error.reportError; 1.exit };
)
