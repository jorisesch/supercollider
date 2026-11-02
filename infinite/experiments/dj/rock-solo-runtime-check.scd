// Muted real Riff button: four-bar lead and a chord tone sent to the actual server.
(
var root=thisProcess.nowExecutingPath.dirname,server,errors=List.new,startupErrors=List.new,landings=List.new,levels=List.new;
var assert={|ok,msg|if(ok.not){Error(msg).throw}},waitFor,ui,onFail,onLevel,oldMessage;
ui={|fn|var done=false,error;{try {fn.value} {|e|error=e};done=true}.defer;
    while {done.not}{0.02.wait};if(error.notNil){error.throw};};
waitFor={|fn,seconds=12|var end=Main.elapsedTime+seconds;
    while {fn.value.not and:{Main.elapsedTime<end}}{0.05.wait};assert.value(fn.value,"Solo runtime timeout");};
~djSettings=(channel:\rock,chaos:0.25,density:0.55,mutation:0.3,tension:0.2,hold:true,tonality:\original,melody:\pentatonic);
~djRecipeDir=Platform.defaultTempDir+/+"dj-rock-solo-ui";
(root+/+"live.scd").load;(root+/+"controls.scd").load;
oldMessage=~djMessage;
~djMessage={|event,node,group,bus,bpm|
    if(event[\rockLanding] ? false){
        var plan=~djEngine.state.decks[event.deck],degree,tones;
        degree=plan.schedule[plan.localBar].degree;
        tones=[0,2,4].collect {|offset|plan.scale.wrapAt(degree+offset)};
        assert.value(tones.includes((event.midinote-plan.key)%12),"Scheduled landing is outside its sounding chord");
        landings.add(event.copy);
    };
    oldMessage.value(event,node,group,bus,bpm);
};
server=Server(\soloCheck,NetAddr("127.0.0.1",57151),ServerOptions.new.numInputBusChannels_(0)
    .numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false));server.volume.mute;
onFail=OSCFunc({|msg|if(msg[1].asString=="/d_load" and:{msg[2].asString.endsWith("superfm.scsyndef")}){
    startupErrors.add(msg)}{errors.add(msg)};msg.postln},'/fail',server.addr);
onLevel=OSCFunc({|msg|levels.add(msg[3])},'/soloLevel',server.addr);
SystemClock.sched(45,{server.quit;1.exit;nil});
server.waitForBoot {
    Routine {
        try {
            var bus,meter;
            ~djStart.value(2600,102,server);waitFor.value {~djRoutine.notNil};bus=~djBus;
            SynthDef(\soloMeter,{|in=0|SendReply.kr(Impulse.kr(10),'/soloLevel',Amplitude.kr(In.ar(in,2)).sum)}).send(server);server.sync;
            meter=Synth.after(~djGroup,\soloMeter,[\in,bus.index+12]);
            ui.value {~djShow.value;~djWindow.minimize;~djUI[\hook].valueAction_(0)};
            waitFor.value {~djEngine.state.decks[0].notNil and:{~djEngine.state.decks[0].rockSoloActive}};
            assert.value(~djEngine.state.decks[0].rockSoloKind==\riff,"Button did not reach the riff generator");
            waitFor.value({landings.notEmpty},15);
            assert.value(landings.last.rockPhraseBars==4 and:{landings.last.rockPhraseAge==3},"Requested riff did not resolve after four bars");
            assert.value(levels.notEmpty and:{levels.maxItem>0.01},"Rock solo playback is silent");
            ui.value {~djWindow.close};3.5.wait;meter.free;server.sync;
            if(errors.notEmpty){errors.postln};
            assert.value(bus.index.isNil and:{errors.isEmpty},"Solo playback cleanup/server error");
            "PASS: actual Riff button, four-bar pentatonic solo, current-chord landing delivered to the server, internal audio and cleanup; hardware muted".postln;
            if(startupErrors.notEmpty){("Separate startup-extension errors: "++startupErrors.size).postln};
            onFail.free;onLevel.free;server.quit;0.exit;
        } {|e|e.reportError;~djStop.value;server.quit;1.exit};
    }.play(SystemClock);
};
)
