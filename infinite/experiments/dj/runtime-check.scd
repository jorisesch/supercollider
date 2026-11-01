// Muted native UI/server check: held effects, handover, hover details and recall.
(
var root=thisProcess.nowExecutingPath.dirname,server,failures=List.new,levels=List.new;
var alive=Set.new,initialNodes,onGo,onEnd,onFail,onLevel,buses=List.new;
var assert={ |ok,message| if(ok.not) {Error(message).throw} };
var ui={ |fn|var done=false,error;{try {fn.value} { |e|error=e};done=true}.defer;
    while {done.not} {0.02.wait};if(error.notNil) {error.throw};};
var waitFor={ |fn,seconds=12|var deadline=Main.elapsedTime+seconds;
    while {fn.value.not and: {Main.elapsedTime<deadline}} {0.05.wait};assert.value(fn.value,"DJ UI runtime timeout");};
~djRecipeDir=Platform.defaultTempDir +/+ "dj-ui-recipes";
(root +/+ "live.scd").load;(root +/+ "controls.scd").load;
server=Server(\djCheck,NetAddr("127.0.0.1",57135),ServerOptions.new
    .numInputBusChannels_(0).numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false));
server.volume.mute;
onGo=OSCFunc({ |m|alive.add(m[1])},'/n_go',server.addr);
onEnd=OSCFunc({ |m|alive.remove(m[1])},'/n_end',server.addr);
onFail=OSCFunc({ |m|failures.add(m);m.postln},'/fail',server.addr);
onLevel=OSCFunc({ |m|levels.add(m[3..4])},'/djCheckLevel',server.addr);
SystemClock.sched(110,{"FAIL: DJ UI watchdog".postln;server.quit;1.exit;nil});
server.waitForBoot({
    Routine {
        try {
            var output,meter,view,oldEngine,oldKey,oldPalette,name;
            server.sync;0.2.wait;initialNodes=alive.copy;
            SynthDef(\djCheckMeter,{ |in=0|SendReply.kr(Impulse.kr(10),'/djCheckLevel',Amplitude.kr(In.ar(in,2),0.001,0.08))}).send(server);
            server.sync;
            ~djStart.value(2600,128,server);
            ui.value {
                ~djShow.value;view=~djUI;view[\next].valueAction_(0);view[\auto].valueAction_(0);
                assert.value(~djWindow.bounds.height==560,"Compact window height changed");
                assert.value(view.fxMenu.items.size==6,"An effect choice was lost");
            };
            waitFor.value {~djRoutine.notNil};buses.add(~djBus);
            output=Bus.audio(server,2);~djMaster.set(\out,output.index);
            meter=Synth.after(~djGroup,\djCheckMeter,[\in,output.index]);
            waitFor.value {~djEngine.state.mixing};
            oldKey=~djEngine.state.decks[0].key;oldPalette=~djEngine.state.decks[0].palette.id;
            0.2.wait;
            ui.value {
                view[\hook].valueAction_(0);view[\fill].valueAction_(0);view[\hold].valueAction_(1);
                view.knobs.do { |knob|knob.valueAction_(0.5)};
                assert.value(view.titles[0].toolTip.find("Chords").notNil,"Track hover details missing");
                assert.value(view.titles[0].string.find("Chords").isNil,"Technical details still visible in title");
            };
            [\filter,\echo,\wash,\stutter4,\stutter8,\stutter16].do { |kind,i|
                var level=nil,rate=nil,deck,control=[\fxFilter,\fxEcho,\fxReverb,\fxStutter,\fxStutter,\fxStutter][i];
                ui.value {view.fxMenu.valueAction_(i)};
                assert.value(~djManualFX.isNil,"Menu selection activated an effect");
                ui.value {view.fxButton.valueAction_(1)};
                waitFor.value {~djEngine.state.manualFX.notNil and: {~djEngine.state.manualFX.kind==kind}};
                if(kind==\echo) {waitFor.value({~djEngine.state.manualFX.age>=5},15)};
                if(kind==\wash) {waitFor.value {~djEngine.state.manualFX.age>=1}};
                0.6.wait;deck=~djEngine.state.manualFX.deck;
                ~djDecks[deck].get(control,{ |v|level=v});waitFor.value {level.notNil};
                assert.value(level>0.5,"Effect did not reach the server or ended early");
                if(i>=3) {
                    ~djDecks[deck].get(\fxStutterRate,{ |v|rate=v});waitFor.value {rate.notNil};
                    assert.value(rate==[1,2,4][i-3],"Wrong held stutter rate");
                };
                ui.value {view.fxButton.valueAction_(0)};
                0.7.wait;level=nil;
                ~djDecks[deck].get(control,{ |v|level=v});waitFor.value {level.notNil};
                assert.value(level<if(i>=3) {0.01} {0.5},"Stop FX failed within the current bar");
                waitFor.value {~djEngine.state.manualFX.isNil};
            };
            assert.value(~djEngine.state.currentSerial==1,"Handover did not finish");
            assert.value(~djEngine.state.decks[1].key!=oldKey,"Handover did not change key");
            assert.value(~djEngine.state.decks[1].palette.id!=oldPalette,"Handover did not change instruments");
            oldEngine=~djEngine;
            ui.value {view.transport.valueAction_(1);view.transport.valueAction_(0)};
            waitFor.value {~djRoutine.notNil};buses.add(~djBus);~djMaster.set(\out,output.index);
            assert.value(~djEngine===oldEngine,"START reset the session");
            assert.value(~djEngine.controls.hold,"START lost Hold");
            0.2.wait;
            ui.value {
                name=view.titles[1].string;view.more.valueAction_(3);
                ~djUI[\recallField].string_(name);~djUI[\recallPlay].value;
            };
            waitFor.value {~djRoutine.notNil};buses.add(~djBus);~djMaster.set(\out,output.index);
            waitFor.value {~djEngine.state.decks.any { |plan|plan.notNil and: {plan.trackName==name}}};
            assert.value(levels.notEmpty and: {levels.asArray.flat.maxItem>0.01},"Silent DJ output");
            assert.value(levels.every { |pair|pair.every { |v|v>=0 and: {v<0.8}}},"Invalid DJ levels");
            ui.value {~djWindow.close};3.5.wait;meter.free;output.free;server.sync;0.1.wait;
            assert.value(buses.every { |bus|bus.index.isNil},"DJ bus leak");
            assert.value(alive==initialNodes,"DJ/FFT node leak");
            assert.value(failures.isEmpty,"DJ server failure");
            "PASS: compact UI, hover details, six menu-selected held effects with explicit stop, >4-bar echo, queried stutter rates, handover, transport, track-name replay and node/bus cleanup. Hardware muted.".postln;
            onGo.free;onEnd.free;onFail.free;onLevel.free;server.quit;0.exit;
        } { |error|error.reportError;~djStop.value;server.quit;1.exit};
    }.play(SystemClock);
},onFailure:{"FAIL: DJ UI server boot".postln;1.exit});
)
