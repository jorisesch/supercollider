// Actual Tension knob: timbre still responds, harmony enters/returns without restart.
(
var root=thisProcess.nowExecutingPath.dirname,server,errors=List.new,startupErrors=List.new;
var assert={|ok,msg|if(ok.not){Error(msg).throw}},waitFor,ui,onFail;
ui={|fn|var done=false,error;{try {fn.value} {|e|error=e};done=true}.defer;
    while {done.not}{0.02.wait};if(error.notNil){error.throw};};
waitFor={|fn,seconds=12|var end=Main.elapsedTime+seconds;
    while {fn.value.not and:{Main.elapsedTime<end}}{0.05.wait};assert.value(fn.value,"Tension runtime timeout");};
~djSettings=(chaos:0.25,density:0.55,mutation:0.3,tension:0.2,hold:false,channel:\edme,tonality:\original,melody:\full);
~djRecipeDir=Platform.defaultTempDir+/+"dj-tension-ui-recipes";
(root+/+"live.scd").load;(root+/+"controls.scd").load;
server=Server(\tensionCheck,NetAddr("127.0.0.1",57150),ServerOptions.new.numInputBusChannels_(0)
    .numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false));
server.volume.mute;
onFail=OSCFunc({|msg|if(msg[1]=="/d_load"){startupErrors.add(msg)}{errors.add(msg)};msg.postln},'/fail',server.addr);
SystemClock.sched(65,{server.quit;1.exit;nil});
server.waitForBoot {
    Routine {
        try {
            var seed,engine,bus,lastBus;
            seed=(0..63).collect {|i|731+(i*7919)}.detect {|n|~djTensionColor.value(\minor,1,n,0,0,\original,[6,6]).notNil};
            assert.value(seed.notNil,"No first-phrase test seed");
            ~djStart.value(seed,128,server);waitFor.value {~djRoutine.notNil};engine=~djEngine;bus=~djBus;
            ui.value {~djShow.value;~djWindow.minimize;~djUI.knobs[3].valueAction_(1)};
            assert.value(~djEngine===engine and:{~djBus===bus},"Tension restarted the set");
            waitFor.value({engine.state.decks[0].notNil and:{engine.state.decks[0].modalAccent}},22);
            assert.value(engine.state.decks[0].effective.tension>0.6,"Existing sound Tension did not respond");
            assert.value([\dorian,\phrygian].includes(engine.state.decks[0].activeTonality),"Tension did not reach minor color");
            ui.value {~djUI.knobs[3].valueAction_(0.2)};
            waitFor.value({engine.state.decks[0].modalAccent.not},7);
            assert.value(engine.state.decks[0].activeTonality==\aeolian and:{~djEngine===engine},"Harmony did not return without restarting");
            ui.value {~djUI.channel.valueAction_(1)};
            waitFor.value {~djRoutine.notNil and:{~djEngine.channel==\pop}};
            ui.value {~djUI.modeChoice.valueAction_(6);~djUI.modeApply.valueAction_(0)};
            waitFor.value {~djRoutine.notNil and:{~djEngine.controls.tonality==\lydian}};
            engine=~djEngine;waitFor.value {engine.state.decks[0].notNil};lastBus=~djBus;
            assert.value(engine.state.decks[0].activeTonality==\ionian,"Low-Tension major should stay Ionian");
            ui.value {~djUI.knobs[3].valueAction_(1)};
            waitFor.value {engine.state.decks[0].effective.tension>0.6};
            assert.value(~djEngine===engine and:{engine.controls.modalPolicy==\tension},"Pop Tension did not stay live");
            ui.value {~djWindow.close};3.5.wait;
            assert.value(bus.index.isNil and:{lastBus.index.isNil},"Tension/channel window leaked buses");
            assert.value(errors.isEmpty,"Tension runtime server errors");
            "PASS: real Tension knob preserves timbre response, starts/returns a sparse EDM accent without restart; Pop Lydian preference stays major at low Tension; high Tension and cleanup; hardware muted".postln;
            if(startupErrors.notEmpty){("Separate startup-extension failures: "++startupErrors.size).postln};
            onFail.free;server.quit;0.exit;
        } {|e|e.reportError;~djStop.value;server.quit;1.exit};
    }.play(SystemClock);
};
)
