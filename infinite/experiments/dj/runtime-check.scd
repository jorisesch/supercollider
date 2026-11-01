// Muted real-time test of a complete handover, UI, transport, and internal signal.
// Takes approximately 30 seconds. No WAV or recording is created.
(
var root=thisProcess.nowExecutingPath.dirname, server, failures=List.new, levels=List.new;
var initialNodes, alive=Set.new, onGo,onEnd,onFail,onLevel, testing=false, buses=List.new;
var assert={ |condition,message| if(condition.not) { Error(message).throw } };
var ui={ |function|
    var done=false,error;
    { try { function.value } { |caught| error=caught }; done=true }.defer;
    while { done.not } { 0.02.wait }; if(error.notNil) { error.throw };
};
var waitFor={ |condition,seconds=10|
    var deadline=Main.elapsedTime+seconds;
    while { condition.value.not and: { Main.elapsedTime < deadline } } { 0.05.wait };
    assert.value(condition.value,"Runtime timeout");
};
(root +/+ "live.scd").load; (root +/+ "controls.scd").load;
server=Server(\djCheck,NetAddr("127.0.0.1",57135),ServerOptions.new
    .numInputBusChannels_(0).numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false));
server.volume.mute;
onGo=OSCFunc({ |message| alive.add(message[1]) },'/n_go',server.addr);
onEnd=OSCFunc({ |message| alive.remove(message[1]) },'/n_end',server.addr);
onFail=OSCFunc({ |message| if(testing) { failures.add(message); message.postln } },'/fail',server.addr);
onLevel=OSCFunc({ |message| levels.add(message[3..4]) },'/djCheckLevel',server.addr);
SystemClock.sched(75,{ "FAIL: DJ runtime watchdog".postln; ~djStop.value; server.quit; 1.exit; nil });
server.waitForBoot({
    Routine {
        try {
            var output,meter,buttons,oldEngine,oldKey,oldPalette,target,transport,hotButtons;
            server.sync; 0.3.wait; initialNodes=alive.copy;
            SynthDef(\djCheckMeter,{ |in=0|
                SendReply.kr(Impulse.kr(10),'/djCheckLevel',Amplitude.kr(In.ar(in,2),0.001,0.08));
            }).send(server); server.sync;
            testing=true;
            ~djStart.value(2600,128,server);
            // Queue NEXT before the first bar so the complete handover starts now.
            ui.value {
                ~djShow.value;
                buttons=~djWindow.view.children.select { |view| view.isKindOf(Button) };
                buttons.detect { |button| button.states.first.first == "NEXT record" }.valueAction_(0);
                transport=buttons.detect { |button| button.states.first.first == "STOP" };
                hotButtons=buttons.select { |button|
                    button.states.first.first.beginsWith("HOT ") or: {
                        button.states.first.first.beginsWith("STUTTER ")
                    }
                };
                assert.value(hotButtons.size==6,"Hot FX buttons did not load");
                assert.value(~djStutterBars==0.5,"Half-bar stutter is not the default");
                ~djWindow.view.children.detect { |view| view.isKindOf(PopUpMenu) }.valueAction_(3);
                assert.value(~djStutterBars==4,"Stutter duration menu did not reach the controls");
                buttons.detect { |b| b.states.first.first=="Auto stutter OFF" }.valueAction_(0);
                assert.value(~djEngine.controls.autoStutter.not,"Automatic stutter switch did not reach the engine");
            };
            waitFor.value { ~djRoutine.notNil }; buses.add(~djBus);
            output=Bus.audio(server,2); ~djMaster.set(\out,output.index);
            meter=Synth.after(~djGroup,\djCheckMeter,[\in,output.index]);
            waitFor.value { ~djEngine.state.mixing };
            oldKey=~djEngine.state.decks[0].key;
            oldPalette=~djEngine.state.decks[0].palette.id;
            target=~djEngine.state.decks[1].targetBpm;
            ui.value {
                buttons.detect { |button| button.states.first.first == "Bass hook" }.valueAction_(0);
                buttons.detect { |button| button.states.first.first == "Fill" }.valueAction_(0);
                buttons.detect { |button| button.states.first.first == "Hold record" }.valueAction_(1);
                ~djWindow.view.children.select { |view| view.isKindOf(Knob) }.do { |knob| knob.valueAction_(0.5) };
            };
            // Click separately, wait for consumption, and read the synth's actual control.
            hotButtons.do { |button,i|
                var kinds=[\filter,\echo,\wash,\stutter4,\stutter8,\stutter16];
                var control,level=nil,rate=nil,hotTarget,state;
                ui.value {button.valueAction_(0)};
                waitFor.value {~djEngine.state.lastFX==kinds[i]};
                if(i>=3) {
                    assert.value(~djEngine.state.stutter.bars==4,"Stutter button ignored the selected duration");
                };
                0.4.wait;
                control=[\fxFilter,\fxEcho,\fxReverb,\fxStutter,\fxStutter,\fxStutter][i];
                state=~djEngine.state;
                hotTarget=state.currentSerial%2;
                if(state.mixing and: {state.phase>=(state.mixBars/2)}) {hotTarget=1-hotTarget};
                ~djDecks[hotTarget].get(control,{ |value| level=value });
                waitFor.value {level.notNil};
                assert.value(level>0.12,"HOT button did not set the server FX: " ++ kinds[i]);
                if(i>=3) {
                    ~djDecks[hotTarget].get(\fxStutterRate,{ |value| rate=value });
                    waitFor.value {rate.notNil};
                    assert.value(rate==[1,2,4][i-3],"Wrong server stutter division: " ++ kinds[i]);
                };
            };
            waitFor.value({ ~djEngine.state.currentSerial == 1 },40);
            assert.value(~djEngine.state.decks[1].key != oldKey,"Handover did not change key");
            assert.value(~djEngine.state.decks[1].palette.id != oldPalette,
                "Handover did not change instrument palette");
            0.15.wait;
            ui.value {
                var name=~djEngine.state.decks[1].palette.name;
                assert.value(~djWindow.view.children.select { |view| view.isKindOf(StaticText) }.any { |view|
                    view.string.find(name).notNil
                },"Deck display does not identify its new instrument palette");
            };
            assert.value((~djBpm-target).abs < 0.05,"Handover tempo did not reach the target");
            {
                var queuedBar=~djEngine.state.bar,deck,level=nil,hitBar;
                ui.value {
                    ~djWindow.view.children.detect { |view| view.isKindOf(PopUpMenu) }.valueAction_(0);
                    hotButtons[5].valueAction_(0);
                };
                waitFor.value {
                    ~djEngine.state.bar>queuedBar and: {~djEngine.state.stutter.notNil}
                        and: {~djEngine.state.stutter.bars==0.5}
                };
                hitBar=~djEngine.state.bar; deck=~djEngine.state.stutter.deck;
                waitFor.value {~djFxState[deck].stutter>0}; 0.25.wait;
                ~djDecks[deck].get(\fxStutter,{ |value| level=value }); waitFor.value {level.notNil};
                assert.value(level>0.12,"Half-bar UI hit did not reach the actual server");
                waitFor.value {~djEngine.state.bar>hitBar}; 0.3.wait; level=nil;
                ~djDecks[deck].get(\fxStutter,{ |value| level=value }); waitFor.value {level.notNil};
                assert.value(level<0.01,"Half-bar UI hit failed to release");
            }.value;
            oldEngine=~djEngine;
            ui.value { transport.valueAction_(1); assert.value(transport.value == 1,"STOP did not become START") };
            ui.value { transport.valueAction_(0) };
            waitFor.value { ~djRoutine.notNil }; buses.add(~djBus);
            ~djMaster.set(\out,output.index);
            assert.value(~djEngine === oldEngine,"START reset the DJ set");
            assert.value(~djEngine.controls.hold,"START lost Hold record");
            2.wait;
            assert.value(levels.notEmpty and: { levels.asArray.flat.maxItem > 0.01 },"Silent internal output");
            assert.value(levels.every { |pair| pair.every { |level| level >= 0 and: { level < 0.8 } } },"Non-finite or excessive levels");
            ui.value { ~djWindow.close };
            waitFor.value { ~djPlaying.not }; 3.4.wait;
            meter.free; output.free; server.sync; 0.1.wait;
            assert.value(buses.every { |bus| bus.index.isNil },"DJ bus leak");
            assert.value(alive == initialNodes,"DJ node leak");
            assert.value(failures.isEmpty,"DJ server error");
            "PASS: complete key/tempo handover, both decks, Hook/Fill/Hold controls, six separate HOT requests including queried 1/4, 1/8, 1/16 stutter rates, all knobs, STOP/START continuation, finite non-silent internal levels, window close and node/bus cleanup. Hardware stayed muted; no audio files.".postln;
            onGo.free; onEnd.free; onFail.free; onLevel.free; server.quit; 0.exit;
        } { |error| error.reportError; ~djStop.value; server.quit; 1.exit };
    }.play(SystemClock);
},onFailure:{ "FAIL: DJ test server boot".postln; 1.exit });
)
