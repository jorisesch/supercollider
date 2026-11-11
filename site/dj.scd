// Browser transport for the existing Infinite DJ and Soundscape engines.
(
var root = ~webSourceRoot ? "/infinite";
var server = Server.default, ready = false, generation = 0;
var graph, engine, clock, player, mode, energy = 0.5;
var close, reportError, applyEnergy, playDJ, playSoundscape, loadError, failureListener;

reportError = { |message| ("WEB_DJ error " ++ message).postln };
close = {
    var old = graph;
    generation = generation + 1;
    if(player.notNil) { player.stop; player = nil };
    if(clock.notNil) { clock.stop; clock = nil };
    graph = nil;
    engine = nil;
    if(old.notNil) {
        if(old[\output].notNil) { old[\output].set(\gain, 0) };
        SystemClock.sched(0.24, {
            old[\group].free;
            old[\bus].free;
            nil;
        });
    };
};
applyEnergy = {
    if(engine.notNil) {
        engine.controls.chaos = 0.08 + (energy * 0.34);
        engine.controls.density = 0.28 + (energy * 0.54);
        engine.controls.mutation = 0.12 + (energy * 0.36);
        engine.controls.tension = 0.02 + (energy * 0.36);
    };
};
playDJ = { |session, currentGraph, beatClock|
    var announced, bpm = session.state.bpm;
    loop {
        var frame = session[\nextBar].value, previous = 0;
        var plan = frame.decks.detect { |deck|
            deck.notNil and: { deck.serial == session.state.currentSerial }
        };
        var actions = frame.automation.collect { |point| (beat: point.beat, automation: point) }
            ++ frame.events.collect { |event| (beat: event.beat, note: event) };
        if(plan.notNil and: { plan.serial != announced }) {
            announced = plan.serial;
            ("WEB_DJ track " ++ plan.keyName ++ " / " ++ if(plan.edmAnthem == true) {
                "Anthem"
            } {
                plan.palette.name
            }).postln;
        };
        actions.sort { |a, b|
            if(a.beat == b.beat) { a.automation.notNil and: { b.automation.isNil } } { a.beat < b.beat }
        }.do { |action|
            (action.beat - previous).max(0).wait;
            previous = action.beat;
            if(action.automation.notNil) {
                bpm = action.automation.bpm;
                beatClock.tempo = bpm / 60;
                server.sendBundle(server.latency, *~djAutomation.value(
                    action.automation, currentGraph[\decks].collect(_.nodeID), currentGraph[\eqNodes]
                ));
            } {
                var note = action.note;
                server.sendBundle(server.latency, ~djMessage.value(
                    note, -1, currentGraph[\sources][note.deck].nodeID, currentGraph[\bus].index, bpm
                ));
            };
        };
        (4 - previous).max(0).wait;
    };
};
playSoundscape = { |session, currentGraph|
    "WEB_DJ track Evolving soundscape".postln;
    loop {
        var previous = 0;
        session[\nextBar].value.do { |event|
            (event.beat - previous).max(0).wait;
            previous = event.beat;
            server.sendBundle(server.latency, ~infiniteMessage.value(
                event, session, -1, currentGraph[\sources][0].nodeID, currentGraph[\bus].index
            ));
        };
        (4 - previous).max(0).wait;
    };
};

~webStop = { close.value; "WEB_DJ stopped".postln };
~webNext = {
    if(engine.notNil) {
        if(mode == \soundscape) { ~webStart.value(nil, mode) } { engine[\requestNext].value };
    };
};
~webEnergy = { |value| energy = value.clip(0, 1); applyEnergy.value };
~webStart = { |seed, channel = \edm|
    var token;
    if(ready.not) {
        reportError.value("Audio engine is still loading");
    } {
        close.value;
        token = generation;
        Routine {
            if(token == generation) {
                try {
                    var currentGraph, soundscape, bpm, mix, mixBus, actualSeed;
                    mode = channel.asSymbol;
                    soundscape = mode == \soundscape;
                    actualSeed = if(seed.isNil) { ~djFreshSeed.value } { seed };
                    if(soundscape) {
                        engine = ~makeInfiniteEngine.value(\soundscape, actualSeed);
                        bpm = engine.bpm;
                    } {
                        mode = ~djResolveChannel.value(mode);
                        bpm = if(mode == \edme) { 134 } { ~djDefaultBpm.value(mode) };
                        engine = ~makeDJEngine.value(actualSeed, bpm, (channel: mode, openWithHook: true));
                    };
                    applyEnergy.value;
                    currentGraph = (bus: Bus.audio(server, if(soundscape) { 4 } { 16 }), group: Group.new(server));
                    graph = currentGraph;
                    mixBus = currentGraph[\bus].index;
                    if(soundscape) {
                        currentGraph[\sources] = [Group.head(currentGraph[\group])];
                        Synth.tail(currentGraph[\group], \igMaster, [\in, mixBus, \out, mixBus + 2]);
                        mixBus = mixBus + 2;
                    } {
                        mix = ~djMixSpec.value(mode, engine.controls.rockToneVersion);
                        currentGraph[\sources] = Array.fill(2, { Group.head(currentGraph[\group]) });
                        currentGraph[\decks] = Array.fill(2, { |id|
                            Synth.tail(currentGraph[\group], mix.deck, [
                                \in, mixBus + (id * 6), \out, mixBus + 12,
                                \musicGain, 0, \bassGain, 0, \drumsGain, 0, \bpm, bpm
                            ]);
                        });
                        if(mix.inputEQ == true) {
                            currentGraph[\eqNodes] = currentGraph[\decks].collect { |deck, id|
                                Synth.before(deck, \rockBluesEQ, [\in, mixBus + (id * 6)]).nodeID;
                            };
                        };
                        Synth.tail(currentGraph[\group], mix.master, [\in, mixBus + 12, \out, mixBus + 14, \drive, mix.drive]);
                        mixBus = mixBus + 14;
                    };
                    currentGraph[\output] = Synth.tail(currentGraph[\group], \webDJOutput, [\in, mixBus]);
                    server.sync;
                    if(token == generation) {
                        var session = engine, beatClock = TempoClock.new(bpm / 60);
                        clock = beatClock;
                        currentGraph[\output].set(\gain, 0.55);
                        "WEB_DJ playing".postln;
                        player = Routine {
                            try {
                                if(soundscape) {
                                    playSoundscape.value(session, currentGraph);
                                } {
                                    playDJ.value(session, currentGraph, beatClock);
                                };
                            } { |error|
                                if(token == generation) { reportError.value(error.errorString); close.value };
                            };
                        }.play(beatClock, quant: 0);
                    };
                } { |error|
                    if(token == generation) { close.value; reportError.value(error.errorString) };
                };
            };
        }.play(SystemClock);
    };
};

try {
    (root +/+ "experiments/dj/engine.scd").load;
    (root +/+ "experiments/dj/instruments.scd").load;
    (root +/+ "infinite-engine.scd").load;
    (root +/+ "infinite-instruments.scd").load;
    if(~makeDJEngine.isNil or: { ~djDefs.isNil or: { ~makeInfiniteEngine.isNil or: { ~infiniteDefs.isNil } } }) {
        Error("Missing music engine or instruments").throw;
    };
    server.options.numInputBusChannels = 0;
    server.options.numOutputBusChannels = 2;
    server.options.numWireBufs = 128;
    // The pinned WebAssembly build reserves a 16 MiB linear memory.
    server.options.memSize = 8192;
    // Leave space for the old and new graphs during the channel fade.
    server.options.numAudioBusChannels = 512;
    server.options.numControlBusChannels = 256;
    server.options.numBuffers = 64;
    server.options.loadDefs = false;
    server.latency = 0.05;
    server.waitForBoot({
        try {
            var output = SynthDef(\webDJOutput, { |in = 0, gain = 0|
                Out.ar(0, In.ar(in, 2) * Lag.kr(gain, 0.04));
            });
            failureListener = OSCFunc({ |message|
                var detail = message.drop(1).join(" ");
                if(ready.not) {
                    loadError = detail;
                } {
                    if(graph.notNil) {
                        reportError.value(detail);
                        close.value;
                    };
                };
            }, '/fail', server.addr);
            // Use OSC directly. Large Rock graphs otherwise use /d_load, which
            // cannot share files between the two WebAssembly modules.
            (~djDefs ++ ~infiniteDefs ++ [output]).do { |def|
                server.sendMsg('/d_recv', def.asBytes);
            };
            server.sync;
            if(loadError.notNil) {
                Error(loadError).throw;
            };
            ready = true;
            "WEB_DJ ready".postln;
        } { |error|
            if(failureListener.notNil) { failureListener.free };
            reportError.value(error.errorString);
        };
    }, onFailure: { reportError.value("Audio server could not start") });
} { |error| reportError.value(error.errorString) };
)
