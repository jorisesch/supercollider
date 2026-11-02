// Muted playback and lifecycle check. No WAV files or hardware playback.
(
var root=thisProcess.nowExecutingPath.dirname,server,levels=List.new,errors=List.new;
var assert={|ok,msg|if(ok.not){Error(msg).throw}},waitFor,onLevel,onFail;
waitFor={|fn,seconds=12|var end=Main.elapsedTime+seconds;
    while {fn.value.not and:{Main.elapsedTime<end}} {0.05.wait};assert.value(fn.value,"Rock runtime timeout");};
(root+/+"live.scd").load;
server=Server(\rockRuntime,NetAddr("127.0.0.1",57147),ServerOptions.new
    .numInputBusChannels_(0).numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false));
server.volume.mute;
onLevel=OSCFunc({|msg|levels.add(msg[3])},'/rockProbe',server.addr);
onFail=OSCFunc({|msg|errors.add(msg);msg.postln},'/fail',server.addr);
SystemClock.sched(40,{server.quit;1.exit;nil});
server.waitForBoot {
    Routine {
        try {
            var output,meter,firstBus,nextBus;
            SynthDef(\rockMeter,{|in=0|SendReply.kr(Impulse.kr(10),'/rockProbe',Amplitude.kr(In.ar(in,2)).sum)}).send(server);server.sync;
            ~rockPlay.value(\ironwood,server);waitFor.value {~rockMaster.notNil};
            output=Bus.audio(server,2);~rockMaster.set(\out,output.index);
            meter=Synth.after(~rockGroup,\rockMeter,[\in,output.index]);firstBus=~rockBus;
            2.wait;~rockMaster.set(\amp,0.6);~rockStop.value;~rockStop.value;
            ~rockPlay.value(\greenroom,server);waitFor.value {~rockMaster.notNil};nextBus=~rockBus;
            ~rockMaster.set(\out,output.index);1.8.wait;
            assert.value(firstBus.index.isNil,"First study bus was not freed");
            ~rockStop.value;1.8.wait;assert.value(nextBus.index.isNil,"Second study bus was not freed");
            // Accelerate only the test clock to exercise natural completion.
            ~rockSpecs[2].bpm=1120;
            ~rockPlay.value(\openroad,server);waitFor.value {~rockMaster.notNil};nextBus=~rockBus;
            ~rockMaster.set(\out,output.index);waitFor.value({~rockMaster.isNil},14);1.8.wait;
            assert.value(nextBus.index.isNil,"Natural ending leaked its bus");
            assert.value(levels.notEmpty and:{levels.maxItem>0.01},"Rock playback is silent");
            assert.value(errors.isEmpty,"Rock server errors");meter.free;output.free;server.sync;
            "PASS: three studies, internal audio, level edit, repeated stop, switching, natural completion and bus cleanup; hardware muted".postln;
            onLevel.free;onFail.free;server.quit;0.exit;
        } {|e|e.reportError;~rockStop.value;server.quit;1.exit};
    }.play(SystemClock);
};
)
