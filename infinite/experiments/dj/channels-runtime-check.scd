// Muted integration check: real channel/mode widgets, Rock audio, mixing and cleanup.
(
var root=thisProcess.nowExecutingPath.dirname,server,failures=List.new,startupFailures=List.new,levels=List.new;
var assert={|ok,msg|if(ok.not){Error(msg).throw}},waitFor,ui,onFail,onLevel;
ui={|fn|var done=false,error;{try {fn.value} {|e|error=e};done=true}.defer;
    while {done.not}{0.02.wait};if(error.notNil){error.throw};};
waitFor={|fn,seconds=12|var end=Main.elapsedTime+seconds;
    while {fn.value.not and:{Main.elapsedTime<end}}{0.05.wait};assert.value(fn.value,"Channel runtime timeout");};
~djRecipeDir=Platform.defaultTempDir+/+"dj-channel-ui-recipes";
(root+/+"live.scd").load;(root+/+"controls.scd").load;
server=Server(\channelCheck,NetAddr("127.0.0.1",57149),ServerOptions.new.numInputBusChannels_(0)
    .numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false));
server.volume.mute;
onFail=OSCFunc({|msg|if(msg[1]=="/d_load"){startupFailures.add(msg)}{failures.add(msg)};msg.postln},'/fail',server.addr);
onLevel=OSCFunc({|msg|levels.add(msg[3])},'/channelLevel',server.addr);
SystemClock.sched(90,{server.quit;1.exit;nil});
server.waitForBoot {
    Routine {
        try {
            var oldBus,output,meter,engine,rockBus;
            ~djStart.value(2600,128,server);waitFor.value {~djRoutine.notNil};oldBus=~djBus;
            ui.value {
                ~djShow.value;~djWindow.minimize;
                assert.value(~djUI.channel.items==["EDM","Pop","Rock"],"Duplicate/missing channel");
                assert.value(~djUI.modeChoice.parent===~djWindow.view,"Mode choice is hidden in another window");
                ~djUI.modeChoice.valueAction_(3);~djUI.pentatonicChoice.valueAction_(true);~djUI.modeApply.valueAction_(0);
            };
            waitFor.value {~djRoutine.notNil and:{~djEngine.controls.tonality==\dorian}};
            3.4.wait;assert.value(oldBus.index.isNil,"Inline Apply leaked its bus");
            ui.value {~djUI.channel.valueAction_(1)};
            waitFor.value {~djRoutine.notNil and:{~djEngine.channel==\pop}};
            assert.value(~djEngine.controls.tonality==\dorian and:{~djEngine.controls.melody==\pentatonic},"Pop lost the mode overlay");
            ui.value {~djUI.channel.valueAction_(2)};
            waitFor.value {~djRoutine.notNil and:{~djEngine.channel==\rock}};rockBus=~djBus;
            assert.value(~djInitialBpm==102 and:{~djEngine.controls.autoStutter.not},"Rock defaults are wrong");
            assert.value(~djEngine.controls.tonality==\dorian and:{~djEngine.controls.melody==\pentatonic},"Rock lost musical settings");
            SynthDef(\channelMeter,{|in=0|SendReply.kr(Impulse.kr(10),'/channelLevel',Amplitude.kr(In.ar(in,2)).sum)}).send(server);server.sync;
            output=Bus.audio(server,2);~djMaster.set(\out,output.index);
            meter=Synth.after(~djGroup,\channelMeter,[\in,output.index]);
            ui.value {~djSpectrum.scopes.do {|scope,i|scope.inBus_(output.index+i)}};
            "ROCK UI READY / spectrum reads the internal stereo mix / hardware muted".postln;
            3.4.wait;levels.clear;
            ui.value {~djUI.hook.valueAction_(0);~djUI[\next].valueAction_(0)};
            waitFor.value {~djEngine.state.mixing};
            ui.value {~djUI.fxMenu.valueAction_(1);~djUI.fxButton.valueAction_(1)};
            waitFor.value {~djEngine.state.manualFX.notNil};
            assert.value(~djEngine.state.manualFX.kind==\echo,"Rock effect did not reach engine");
            ui.value {~djUI.fxButton.valueAction_(0)};
            waitFor.value({~djEngine.state.currentSerial==1},24);
            assert.value(levels.notEmpty and:{levels.maxItem>0.01},"Rock output is silent");
            engine=~djEngine;
            ui.value {~djUI.transport.valueAction_(1);~djUI.transport.valueAction_(0)};
            waitFor.value {~djRoutine.notNil};assert.value(~djEngine===engine,"Rock resume reset the record");
            3.4.wait;assert.value(rockBus.index.isNil,"Rock resume leaked its old bus");oldBus=~djBus;
            ui.value {~djUI.channel.valueAction_(0)};
            waitFor.value {~djRoutine.notNil and:{~djEngine.channel==\edme}};
            3.4.wait;assert.value(oldBus.index.isNil,"Rock-to-EDM switch leaked its bus");
            ui.value {~djUI.modeChoice.valueAction_(0);~djUI.pentatonicChoice.valueAction_(false);~djUI.modeApply.valueAction_(0)};
            waitFor.value {~djRoutine.notNil and:{~djEngine.controls.tonality==\original}};
            ui.value {~djWindow.close};3.5.wait;meter.free;output.free;server.sync;
            assert.value(failures.isEmpty,"Channel server errors");
            "PASS: one EDM, inline mode overlay in EDM/Pop/Rock, Rock signal, riff, held FX, handover, resume, switch-back and fade cleanup; hardware muted".postln;
            if(startupFailures.notEmpty){("Separate startup-extension /d_load failures: "++startupFailures.size).postln};
            onFail.free;onLevel.free;server.quit;0.exit;
        } {|error|error.reportError;~djStop.value;server.quit;1.exit};
    }.play(SystemClock);
};
)
