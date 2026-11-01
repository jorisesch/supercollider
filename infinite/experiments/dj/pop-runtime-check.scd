// Muted window test: select Pop, exercise Chorus, handover, transport and switch back.
(
var root=thisProcess.nowExecutingPath.dirname,server,failures=List.new,levels=List.new;
var assert={ |ok,message| if(ok.not) {Error(message).throw} };
var ui={ |fn| var done=false,error; {try {fn.value} {|e|error=e};done=true}.defer;
    while {done.not} {0.02.wait}; if(error.notNil){error.throw}; };
var waitFor={ |fn,seconds=12| var end=Main.elapsedTime+seconds;
    while {fn.value.not and:{Main.elapsedTime<end}} {0.05.wait}; assert.value(fn.value,"Pop runtime timeout"); };
var onFail,onLevel;
~djRecipeDir=Platform.defaultTempDir +/+ "dj-pop-ui-recipes";
(root+/+"live.scd").load; (root+/+"controls.scd").load;
server=Server(\popCheck,NetAddr("127.0.0.1",57139),ServerOptions.new.numInputBusChannels_(0)
    .numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false));
server.volume.mute;
onFail=OSCFunc({ |msg| failures.add(msg) },'/fail',server.addr);
onLevel=OSCFunc({ |msg| levels.add(msg[3]) },'/popCheckLevel',server.addr);
SystemClock.sched(65,{"FAIL: Pop runtime watchdog".postln;server.quit;1.exit;nil});
server.waitForBoot {
    Routine {
        try {
            var menu,buttons,transport,engine,output,meter,oldBus;
            ~djStart.value(2600,128,server); waitFor.value {~djRoutine.notNil};
            ui.value {
                ~djShow.value;
                menu=~djUI[\channel];
                menu.valueAction_(1);
            };
            waitFor.value {~djRoutine.notNil and:{~djEngine.channel==\pop}};
            engine=~djEngine;
            assert.value(~djInitialBpm==138,"Pop selector did not set its tempo");
            SynthDef(\popCheckMeter,{ |in=0| SendReply.kr(Impulse.kr(10),'/popCheckLevel',Amplitude.kr(In.ar(in,2)).sum) }).send(server);
            server.sync;
            output=Bus.audio(server,2); ~djMaster.set(\out,output.index);
            meter=Synth.after(~djGroup,\popCheckMeter,[\in,output.index]);
            0.3.wait;
            ui.value {
                buttons=~djWindow.view.children.select { |v| v.isKindOf(Button) };
                buttons.detect { |v| v.states[0][0]=="Chorus" }.valueAction_(0);
                buttons.detect { |v| v.states[0][0]=="Fill" }.valueAction_(0);
                ~djUI[\next].valueAction_(0);
            };
            waitFor.value {~djEngine.state.mixing};
            waitFor.value({~djEngine.state.currentSerial==1},24);
            assert.value(~djEngine.channel==\pop,"Pop handover changed channel");
            assert.value(levels.notEmpty and:{levels.maxItem>0.01},"Silent Pop output");
            ui.value {
                transport=buttons.detect { |v| v.states[0][0]=="STOP" };
                transport.valueAction_(1); transport.valueAction_(0);
            };
            waitFor.value {~djRoutine.notNil};
            assert.value(~djEngine===engine,"Resume reset Pop composition");
            oldBus=~djBus;
            ui.value {menu.valueAction_(0)};
            waitFor.value {~djRoutine.notNil and:{~djEngine.channel==\edme}};
            3.4.wait;
            assert.value(oldBus.index.isNil,"Channel switch leaked its old bus");
            assert.value(~djInitialBpm==128,"EDM switch changed default tempo");
            ui.value {~djWindow.close}; 3.4.wait;
            meter.free;output.free;server.sync;
            assert.value(failures.isEmpty,"Pop runtime server error");
            "PASS: actual EDM/Pop selector callbacks, Chorus/Fill, Pop handover, internal signal, STOP/START, return to EDM and fade cleanup. Hardware muted.".postln;
            onFail.free;onLevel.free;server.quit;0.exit;
        } { |e| e.reportError;~djStop.value;server.quit;1.exit };
    }.play(SystemClock);
};
)
