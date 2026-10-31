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
            var output,meter,buttons,oldEngine,oldKey,target,transport;
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
            };
            waitFor.value { ~djRoutine.notNil }; buses.add(~djBus);
            output=Bus.audio(server,2); ~djMaster.set(\out,output.index);
            meter=Synth.after(~djGroup,\djCheckMeter,[\in,output.index]);
            waitFor.value { ~djEngine.state.mixing };
            oldKey=~djEngine.state.decks[0].key;
            target=~djEngine.state.decks[1].targetBpm;
            ui.value {
                buttons.detect { |button| button.states.first.first == "Hook" }.valueAction_(0);
                buttons.detect { |button| button.states.first.first == "Fill" }.valueAction_(0);
                buttons.detect { |button| button.states.first.first == "Hold record" }.valueAction_(1);
                ~djWindow.view.children.select { |view| view.isKindOf(Knob) }.do { |knob| knob.valueAction_(0.5) };
            };
            waitFor.value({ ~djEngine.state.currentSerial == 1 },40);
            assert.value(~djEngine.state.decks[1].key != oldKey,"Handover did not change key");
            assert.value((~djBpm-target).abs < 0.05,"Handover tempo did not reach the target");
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
            "PASS: complete key/tempo handover, both decks, Hook/Fill/Hold controls, all knobs, STOP/START continuation, finite non-silent internal levels, window close and node/bus cleanup. Hardware stayed muted; no audio files.".postln;
            onGo.free; onEnd.free; onFail.free; onLevel.free; server.quit; 0.exit;
        } { |error| error.reportError; ~djStop.value; server.quit; 1.exit };
    }.play(SystemClock);
},onFailure:{ "FAIL: DJ test server boot".postln; 1.exit });
)
