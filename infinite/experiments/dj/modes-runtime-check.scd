// Muted native-window test for musical mode and pentatonic melody selection.
(
var root=thisProcess.nowExecutingPath.dirname,server,failures=List.new,startupFileFailures=List.new;
var assert={|ok,msg|if(ok.not){Error(msg).throw}},ui,waitFor,onFail;
ui={|fn|var done=false,error;{try {fn.value} {|e|error=e};done=true}.defer;
    while {done.not}{0.02.wait};if(error.notNil){error.throw};};
waitFor={|fn,seconds=12|var end=Main.elapsedTime+seconds;
    while {fn.value.not and:{Main.elapsedTime<end}}{0.05.wait};assert.value(fn.value,"Mode runtime timeout");};
~djRecipeDir=Platform.defaultTempDir+/+"dj-mode-ui-recipes";
(root+/+"live.scd").load;(root+/+"controls.scd").load;
server=Server(\modeCheck,NetAddr("127.0.0.1",57148),ServerOptions.new.numInputBusChannels_(0)
    .numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false));
server.volume.mute;
// Our definitions use /d_recv. Record unrelated startup-extension file loads separately.
onFail=OSCFunc({|msg|
    if(msg[1]=="/d_load"){startupFileFailures.add(msg)}{failures.add(msg)};msg.postln;
},'/fail',server.addr);
SystemClock.sched(55,{server.quit;1.exit;nil});
server.waitForBoot {
    Routine {
        try {
            var firstBus,engine;
            ~djStart.value(2600,128,server);waitFor.value {~djRoutine.notNil};firstBus=~djBus;
            ui.value {
                ~djShow.value;
                ~djUI.modeChoice.valueAction_(3);~djUI.pentatonicChoice.valueAction_(true);
                ~djUI.modeApply.valueAction_(0);
            };
            waitFor.value {~djRoutine.notNil and:{~djEngine.controls.tonality==\dorian}};
            assert.value(~djEngine.controls.melody==\pentatonic,"Checkbox did not reach the engine");
            waitFor.value {~djEngine.state.decks[0].notNil};
            assert.value(~djEngine.state.decks[0].scale==[0,2,3,5,7,8,10],"Low Tension should keep the minor base");
            3.4.wait;assert.value(firstBus.index.isNil,"Mode restart leaked its old bus");
            engine=~djEngine;
            ui.value {~djUI.transport.valueAction_(1);~djUI.transport.valueAction_(0)};
            waitFor.value {~djRoutine.notNil};assert.value(~djEngine===engine,"Resume reset modal choice");
            ui.value {~djUI.channel.valueAction_(1)};
            waitFor.value {~djRoutine.notNil and:{~djEngine.channel==\pop}};
            assert.value(~djEngine.controls.tonality==\dorian,"Pop switch lost selected mode");
            ui.value {
                ~djUI.modeChoice.valueAction_(0);
                ~djUI.pentatonicChoice.valueAction_(false);~djUI.modeApply.valueAction_(0);
            };
            waitFor.value {~djRoutine.notNil and:{~djEngine.controls.tonality==\original}};
            assert.value(~djEngine.controls.melody==\full,"Return to full melody failed");
            ui.value {~djWindow.close};3.5.wait;
            assert.value(failures.isEmpty,"Mode UI server error");
            "PASS: inline mode selector, checkbox and Apply; musical scale, fade cleanup, resume, Pop switch and reset; hardware muted".postln;
            if(startupFileFailures.notEmpty){("Separate startup-extension /d_load failures: "++startupFileFailures.size).postln};
            onFail.free;server.quit;0.exit;
        } {|error|error.reportError;~djStop.value;server.quit;1.exit};
    }.play(SystemClock);
};
)
