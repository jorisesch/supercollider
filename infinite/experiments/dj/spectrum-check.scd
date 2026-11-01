// Muted FFT/UI check: stereo routing, test tones, ON/OFF, transport and cleanup.
// Optional screenshot path. Test tones go to a private bus, never headphones.
(
var root=thisProcess.nowExecutingPath.dirname,server,failures=List.new;
var alive=Set.new,initialNodes,onGo,onEnd,onFail;
var imagePath=thisProcess.argv.at(0);
var documentationImage=thisProcess.argv.at(1);
var assert={ |ok,message| if(ok.not) {Error(message).throw} };
var ui={ |fn|
    var done=false,error;
    {try {fn.value} { |caught| error=caught }; done=true}.defer;
    while {done.not} {0.02.wait}; if(error.notNil) {error.throw};
};
var waitFor={ |fn|
    var deadline=Main.elapsedTime+10;
    while {fn.value.not and: {Main.elapsedTime<deadline}} {0.05.wait};
    assert.value(fn.value,"Spectrum runtime timeout");
};
~djRecipeDir=Platform.defaultTempDir +/+ "dj-spectrum-recipes";
(root +/+ "live.scd").load; (root +/+ "controls.scd").load;
server=Server(\djSpectrumCheck,NetAddr("127.0.0.1",57138),ServerOptions.new
    .numInputBusChannels_(0).numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false));
server.volume.mute;
onGo=OSCFunc({ |msg| alive.add(msg[1]) },'/n_go',server.addr);
onEnd=OSCFunc({ |msg| alive.remove(msg[1]) },'/n_end',server.addr);
onFail=OSCFunc({ |msg| failures.add(msg); msg.postln },'/fail',server.addr);
SystemClock.sched(35,{"FAIL: Spectrum watchdog".postln;server.quit;1.exit;nil});
// The CLI opens its window before the audio server finishes booting.
~djServer=server; ~djPlaying=false;
{~djShow.value; assert.value(~djSpectrum.scopes.every { |scope| scope.active.not },"FFT started before playback")}.defer;
server.waitForBoot({
    Routine {
        try {
            var panel,scopes,buffers,probeBus,probe,transport,oldBus,inputs=[nil,nil];
            server.sync; 0.2.wait; initialNodes=alive.copy;
            ~djStart.value(2600,128,server);
            ui.value {~djShow.value; panel=~djSpectrum; scopes=panel.scopes};
            waitFor.value {~djRoutine.notNil and: {scopes.every(_.active)}};
            server.sync;
            assert.value(scopes.every { |scope| scope.server===server },"FFT bound to wrong server");
            assert.value(scopes.collect(_.inBus)==[0,1],"FFT does not read both output channels");
            assert.value(scopes.every { |scope| scope.freqMode==1 and: {scope.dbRange==80} },"FFT axes changed");
            scopes.do { |scope,i| scope.synth.get(\in,{ |bus| inputs[i]=bus }) };
            waitFor.value {inputs.every(_.notNil)};
            assert.value(inputs==[0,1],"FFT synth input differs from the displayed channels");
            buffers=scopes.collect(_.scopebuf);
            probeBus=Bus.audio(server,2);
            SynthDef(\djSpectrumProbe,{ |out=0| Out.ar(out,SinOsc.ar([100,4000],0,0.15)) }).send(server);
            server.sync;
            probe=Synth(\djSpectrumProbe,[\out,probeBus.index],server);
            ui.value {scopes.do { |scope,i| scope.inBus_(probeBus.index+i) }};
            1.wait;
            if(imagePath.notNil) {ui.value {Image.fromWindow(~djWindow).write(imagePath)}};
            ui.value {panel.power.valueAction_(0)};
            waitFor.value {scopes.every { |scope| scope.active.not and: {scope.synth.isNil} }};
            ui.value {panel.power.valueAction_(1)};
            waitFor.value {scopes.every { |scope| scope.active and: {scope.synth.notNil} }};
            probe.free;
            ui.value {scopes.do { |scope,i| scope.inBus_(i) }};
            probeBus.free;
            0.2.wait;
            ui.value {
                transport=~djWindow.view.children.detect { |view|
                    view.isKindOf(Button) and: {view.states[0][0]=="STOP"}
                };
                transport.valueAction_(1);
            };
            waitFor.value {scopes.every { |scope| scope.active.not }};
            if(documentationImage.notNil) {ui.value {Image.fromWindow(~djWindow).write(documentationImage)}};
            oldBus=~djBus;
            ui.value {transport.valueAction_(0)};
            waitFor.value {~djRoutine.notNil and: {scopes.every(_.active)}};
            ui.value {~djWindow.close};
            3.5.wait; server.sync; 0.1.wait;
            assert.value(~djSpectrum.isNil,"Closed window retained its analyzer");
            assert.value(scopes.every { |scope| scope.scopebuf.isNil and: {scope.synth.isNil} },"FFT resource leak");
            assert.value(buffers.every { |buffer| buffer.index.isNil },"Shared scope buffer leak");
            assert.value(oldBus.index.isNil and: {~djBus.index.isNil},"Transport bus leak");
            assert.value(alive==initialNodes,"Spectrum/transport node leak");
            assert.value(failures.isEmpty,"FFT server error");
            "PASS: stereo FFT on the DJ server, queried output routing, log/dB axes, private 100 Hz / 4 kHz probes, ON/OFF, STOP/START and all node/buffer cleanup. Hardware muted.".postln;
            onGo.free; onEnd.free; onFail.free; server.quit; 0.exit;
        } { |error| error.reportError; if(~djWindow.notNil) {{~djWindow.close}.defer}; server.quit; 1.exit };
    }.play(SystemClock);
},onFailure:{"FAIL: Spectrum test server boot".postln;1.exit});
)
