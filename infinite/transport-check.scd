// Muted real-time GUI regression check for every version. No recordings or WAVs.
(
var root=thisProcess.nowExecutingPath.dirname, server, failures=List.new;
var alive=Set.new, initialNodes, buses=List.new, onGo, onEnd, onFail, testing=false;
var assert={ |ok, message| if(ok.not) { Error(message).throw } };
var onUI={ |function|
    var done=false, error;
    { try { function.value } { |caught| error=caught }; done=true }.defer;
    while { done.not } { 0.02.wait };
    if(error.notNil) { error.throw };
};
var waitFor={ |condition|
    var deadline=Main.elapsedTime + 8;
    while { condition.value.not and: { Main.elapsedTime < deadline } } { 0.05.wait };
    assert.value(condition.value, "Transport timed out");
};
var profiles=[
    ["baseline EDM", false, \edm, false], ["baseline soundscape", false, \soundscape, false],
    ["EDM A", true, \edm, false], ["warm ambient", true, \soundscape, false],
    ["EDM B", true, \edm, true]
];
server=Server(\transportCheck, NetAddr("127.0.0.1", 57137),
    ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2).loadDefs_(false));
server.volume.mute;
onGo=OSCFunc({ |message| alive.add(message[1]) }, '/n_go', server.addr);
onEnd=OSCFunc({ |message| alive.remove(message[1]) }, '/n_end', server.addr);
onFail=OSCFunc({ |message| if(testing) { failures.add(message); message.postln } }, '/fail', server.addr);
SystemClock.sched(80, { "FAIL: transport watchdog".postln; server.quit; 1.exit; nil });
server.waitForBoot({
    Routine {
        try {
            server.sync; 0.3.wait; initialNodes=alive.copy; testing=true;
            profiles.do { |profile|
                var experimental=profile[1], prefix=if(experimental, "experiment", "infinite");
                var suffix=if(experimental, "Experiment", "Infinite"), directory=if(experimental, root +/+ "experiments", root);
                var get={ |part| currentEnvironment[(prefix ++ part).asSymbol] };
                var call={ |verb, arguments| currentEnvironment[(verb ++ suffix).asSymbol].valueArray(arguments ? []) };
                var button, restart, saved, savedBar;
                var remember={ buses.add(get.value("Bus")) };
                (directory +/+ if(experimental, "live.scd", "infinite-live.scd")).load;
                (directory +/+ if(experimental, "controls.scd", "infinite-controls.scd")).load;
                if(profile[3]) {
                    (directory +/+ "bite-engine.scd").load;
                    (directory +/+ "bite-instruments.scd").load;
                };
                call.value("start", [profile[2], 2600, 200, server]);
                waitFor.value { get.value("Routine").notNil }; remember.value;
                onUI.value {
                    currentEnvironment[("show" ++ suffix ++ "Controls").asSymbol].value;
                    button=get.value("Window").view.children.detect { |view|
                        view.isKindOf(Button) and: { view.states.first.first == "STOP" }
                    };
                    restart=get.value("Window").view.children.detect { |view|
                        view.isKindOf(Button) and: { view.states.first.first == "Restart seed" }
                    };
                    assert.value(button.notNil and: { button.value == 0 }, "Missing running STOP button");
                };
                1.4.wait;
                call.value("set", [nil, 0.73]); call.value("hold", [true]);
                saved=get.value("Engine"); savedBar=saved.state.bar;
                onUI.value { button.valueAction_(1); assert.value(button.value == 1, "STOP did not become START") };
                assert.value(get.value("Playing").not, "STOP left playback active");
                onUI.value { button.valueAction_(0) };
                waitFor.value { get.value("Routine").notNil }; remember.value;
                assert.value(get.value("Engine") === saved, "START discarded the composition");
                assert.value(saved.controls.hold and: { saved.controls.density == 0.73 } and: { saved.bpm == 200 }, "START lost controls or tempo");
                waitFor.value { saved.state.bar > savedBar };
                call.value("stop"); 0.35.wait;
                onUI.value {
                    assert.value(button.value == 1, "External stop did not update button");
                    button.valueAction_(0); button.valueAction_(1); button.valueAction_(0);
                };
                waitFor.value { get.value("Routine").notNil }; remember.value;
                assert.value(get.value("Engine") === saved, "Rapid toggles reset the engine");
                onUI.value { restart.valueAction_(0) };
                waitFor.value { get.value("Routine").notNil }; remember.value;
                assert.value((get.value("Engine") === saved).not, "Restart seed failed to reset");
                0.3.wait;
                onUI.value {
                    assert.value(button.value == 0, "Restart seed did not restore STOP");
                    get.value("Window").close;
                };
                waitFor.value { get.value("Playing").not };
                ("PASS " ++ profile[0] ++ ": STOP / START / STOP, phrase continuation, retained controls, rapid clicks, Restart seed, window close").postln;
            };
            8.6.wait; server.sync; 0.1.wait;
            assert.value(buses.every { |bus| bus.index.isNil }, "Stopped sessions leaked audio buses");
            assert.value(alive == initialNodes, "Stopped sessions leaked server nodes: " ++ alive.asArray ++ " vs " ++ initialNodes.asArray);
            assert.value(failures.isEmpty, "Server reported an error during transport checks");
            "PASS: every transport restored the initial server node count and freed its buses. Output stayed muted; no WAVs created.".postln;
            onGo.free; onEnd.free; onFail.free; server.quit; 0.exit;
        } { |error| error.reportError; ~stopInfinite.value; ~stopExperiment.value; server.quit; 1.exit };
    }.play(SystemClock);
}, onFailure:{ "FAIL: transport server boot".postln; 1.exit });
)
