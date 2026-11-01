// Muted native UI check of A -> B, a sustained B record, then B -> A.
// Optional screenshot prefix; empty decks animate a status, never a track name.
(
var root=thisProcess.nowExecutingPath.dirname,server,view,failures=List.new;
var alive=Set.new,initialNodes,onGo,onEnd,onFail,prefix=thisProcess.argv.at(0);
var assert={ |ok,message|if(ok.not) {Error(message).throw} };
var ui={ |fn|
    var done=false,error,result;
    {try {result=fn.value} { |caught|error=caught};done=true}.defer;
    while {done.not} {0.02.wait};if(error.notNil) {error.throw};result;
};
var waitFor={ |fn,seconds=12|
    var end=Main.elapsedTime+seconds;
    while {fn.value.not and: {Main.elapsedTime<end}} {0.05.wait};
    assert.value(fn.value,"Deck view timeout");
};
var capture={ |name|if(prefix.notNil) {ui.value {Image.fromWindow(~djWindow).write(prefix++name++".png")}}};
~djRecipeDir=Platform.defaultTempDir +/+ "dj-deck-view-recipes";
(root +/+ "live.scd").load;(root +/+ "controls.scd").load;
server=Server(\djDeckViewCheck,NetAddr("127.0.0.1",57137),ServerOptions.new
    .numInputBusChannels_(0).numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false));
server.volume.mute;
onGo=OSCFunc({ |m|alive.add(m[1])},'/n_go',server.addr);
onEnd=OSCFunc({ |m|alive.remove(m[1])},'/n_end',server.addr);
onFail=OSCFunc({ |m|failures.add(m);m.postln},'/fail',server.addr);
SystemClock.sched(95,{"FAIL: Deck view watchdog".postln;server.quit;1.exit;nil});
server.waitForBoot({
    Routine {
        try {
            var labels=Set.new,outward=List.new,back=List.new,shot=false,value,previous;
            server.sync;0.2.wait;initialNodes=alive.copy;
            ~djSettings.hold=true;~djStart.value(2600,128,server);
            ui.value {~djShow.value;view=~djUI};
            waitFor.value {ui.value {view.deckStatus[0].string=="Playing"}};
            assert.value(ui.value {view.progress.value==0},"A did not start at the left endpoint");
            assert.value(ui.value {view.titles[1].string.isEmpty},"Waiting text is still a song name");
            6.do {labels.add(ui.value {view.deckStatus[1].string});0.25.wait};
            assert.value(labels.size>=2 and: {labels.every { |label|label.beginsWith("waiting")}},"Waiting status did not animate");
            capture.value("-a");
            ui.value {view[\next].valueAction_(0)};
            waitFor.value {~djEngine.state.mixing};
            while {~djEngine.state.currentSerial==0} {
                outward.add(ui.value {view.progress.value});0.1.wait;
            };
            waitFor.value {ui.value {view.progress.value==1 and: {view.deckStatus[1].string=="Playing"}}};
            assert.value(outward.size>20 and: {outward.first<0.15} and: {outward.last>0.85},"A-to-B slider travel missing");
            previous=0;outward.do { |x|assert.value(x>=previous,"A-to-B slider moved backward");previous=x};
            (8*60/~djBpm).wait;
            assert.value(ui.value {view.progress.value==1},"Slider reset while deck B played");
            assert.value(ui.value {view.deckStatus[1].string=="Playing"},"Deck B not identified as playing");
            capture.value("-b");
            ui.value {view[\next].valueAction_(0)};
            waitFor.value {~djEngine.state.mixing};
            while {~djEngine.state.currentSerial==1} {
                value=ui.value {view.progress.value};back.add(value);
                if(shot.not and: {value<0.6} and: {value>0.3}) {
                    assert.value(ui.value {view.deckStatus[0].string.find("fading in").notNil
                        and: {view.deckStatus[1].string.find("fading out").notNil}},"Reverse handover labels are wrong");
                    capture.value("-back");shot=true;
                };
                0.1.wait;
            };
            waitFor.value {ui.value {view.progress.value==0 and: {view.deckStatus[0].string=="Playing"}}};
            assert.value(back.size>20 and: {back.first>0.85} and: {back.last<0.15},"B-to-A slider travel missing");
            previous=1;back.do { |x|assert.value(x<=previous,"B-to-A slider moved forward");previous=x};
            capture.value("-a-again");
            ui.value {view.transport.valueAction_(1)};
            waitFor.value {ui.value {view.deckStatus[0].string=="Stopped"}};
            assert.value(ui.value {view.progress.value==0},"Stop moved the crossfader");
            ui.value {~djWindow.close};3.5.wait;server.sync;0.1.wait;
            assert.value(alive==initialNodes,"Deck view node leak");
            assert.value(failures.isEmpty,"Deck view server failure");
            "PASS: animated empty-deck status outside the name field, visible Playing/fade/Stopped labels, slider left -> right, held right during B, then right -> left through two actual handovers; cleanup. Hardware muted.".postln;
            onGo.free;onEnd.free;onFail.free;server.quit;0.exit;
        } { |error|error.reportError;~djStop.value;server.quit;1.exit};
    }.play(SystemClock);
},onFailure:{"FAIL: Deck view server boot".postln;1.exit});
)
