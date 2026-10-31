// Standalone batch preview: same events and adapter as live playback.
(
var root=thisProcess.nowExecutingPath.dirname, pending=2, failed=false;
var audioDir=root.dirname +/+ "audio";
(root +/+ "infinite-instruments.scd").load;
(root +/+ "infinite-engine.scd").load;
TempoClock.default.tempo=1;
[\edm, \soundscape].do { |mode|
    var engine=~makeInfiniteEngine.value(mode, 2600), events=List.new, node=1000;
    var bars=if(mode == \edm, 32, 8), end, duration;
    events.add([0] ++ ~infiniteDefs.collect { |def| [\d_recv, def.asBytes] });
    events.add([0.01, [\g_new, 1, 0, 0], [\s_new, \igMaster, 999, 1, 1, \in, 16]]);
    bars.do { |bar|
        engine.nextBar.value.do { |event|
            events.add([0.1 + ((bar * 4 + event.beat) * 60 / engine.bpm),
                ~infiniteMessage.value(event, engine, node, 1, 16)]);
            node=node + 1;
        };
    };
    end=0.1 + (bars * 4 * 60 / engine.bpm);
    events.add([end, [\n_set, 999, \gate, 0]]);
    duration=end + 4;
    events.add([duration, [\c_set, 0, 0]]);
    Score(events.asArray).recordNRT(
        oscFilePath: Platform.defaultTempDir +/+ ("infinite-" ++ mode ++ ".osc"),
        outputFilePath: audioDir +/+ ("infinite-" ++ mode ++ ".wav"),
        sampleRate:48000, headerFormat:"WAV", sampleFormat:"int24",
        options:ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0),
        duration:duration, action: { |code|
            failed=failed or: { code != 0 }; pending=pending - 1;
            if(pending == 0) { if(failed) { 1.exit } { 0.exit } };
        }
    );
};
)
