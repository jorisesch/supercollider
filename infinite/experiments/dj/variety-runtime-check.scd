// Muted native UI test of per-deck ratings and freshly seeded mode changes.
(
var root=thisProcess.nowExecutingPath.dirname,server,failures=List.new,ui,waitFor,assert,onFail;
assert={|ok,msg|if(ok.not){Error(msg).throw}};
ui={|fn|var done=false,error;{try {fn.value} {|e|error=e};done=true}.defer;
    while {done.not}{0.02.wait};if(error.notNil){error.throw}};
waitFor={|fn,seconds=15|var deadline=Main.elapsedTime+seconds;
    while {fn.value.not and:{Main.elapsedTime<deadline}}{0.05.wait};
    assert.value(fn.value,"Feedback UI timeout")};
~djFeedbackDir=Platform.defaultTempDir+/+"dj-feedback-ui";
~djRecipeDir=Platform.defaultTempDir+/+"dj-feedback-ui-recipes";
(root+/+"live.scd").load;(root+/+"controls.scd").load;
server=Server(\feedbackUI,NetAddr("127.0.0.1",57162),ServerOptions.new.numInputBusChannels_(0)
    .numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false));
server.volume.mute;
onFail=OSCFunc({|msg|if(msg[1].asString!="/d_load"){failures.add(msg)}},'/fail',server.addr);
SystemClock.sched(65,{server.quit;1.exit;nil});
server.waitForBoot {
    Routine {
        try {
            var title,first,second,oldSeed;
            ~djStart.value(314159,128,server);
            ui.value {~djShow.value;~djWindow.minimize};
            waitFor.value {~djHeardTracks.notNil and:{~djLastAutomation.notNil}};
            0.3.wait;
            title=~djHeardTracks[0].track_id;
            ui.value {~djUI.ratings[0][0].valueAction_(1)};
            assert.value(~djRatings[title].rating==1,"Thumbs up did not rate its playing deck");
            ui.value {~djUI.ratings[0][1].valueAction_(1)};
            assert.value(~djRatings[title].rating== -1,"Thumbs down did not replace the latest vote");
            first=~djRatings[title];
            ui.value {~djUI[\next].valueAction_(0)};
            waitFor.value {~djHeardTracks[1].notNil and:{~djLastAutomation.gains[1].maxItem>0.05}};
            0.3.wait;second=~djHeardTracks[1].track_id;
            ui.value {~djUI.ratings[1][0].valueAction_(1)};
            assert.value(~djRatings[second].rating==1 and:{~djRatings[title].id==first.id},"Handover vote changed the wrong track");
            assert.value(~djRatings[second].deck==1,"Feedback lost its deck");
            oldSeed=~djEngine.seed;
            ui.value {
                ~djUI.modeChoice.valueAction_(7);~djUI.modeApply.valueAction_(0);
            };
            waitFor.value {~djEngine.seed!=oldSeed and:{~djEngine.controls.tonality==\harmonicMinor}};
            waitFor.value {~djRoutine.notNil and:{~djHeardTracks.notNil}};
            assert.value(~djEngine.controls.modalPolicy==\fixed,"Manual mode did not pin the scale");
            ui.value {~djWindow.close};
            3.5.wait;server.sync;
            assert.value(failures.isEmpty,"Feedback UI server error");
            onFail.free;server.quit;
            "PASS: native thumbs up/down, revision, explicit incoming-deck vote, new seed on mode apply and cleanup; hardware muted".postln;
            0.exit;
        } {|error|error.reportError;~djStop.value;server.quit;1.exit};
    }.play(SystemClock);
};
)
