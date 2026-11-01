// Compact native performance view. Detailed record information lives in tooltips.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "spectrum.scd").load;
~djShow={
    if(~djWindow.isNil) {
        var window=Window("Infinite DJ",Rect(0,0,860,560).center_(Window.availableBounds.center));
        var titles,deckLabels,deckStatus,progress,knobs,transport,next,hook,fill,hold,more,channel,auto,fxMenu,fxButton,update,spectrum;
        var fxNames=["Filter","Echo","Wash","Stutter 1/4","Stutter 1/8","Stutter 1/16"];
        var fxKinds=[\filter,\echo,\wash,\stutter4,\stutter8,\stutter16];
        var descriptions=["Adventurous fills and rhythmic variation","Bass pickups and percussion",
            "Small changes to the bass answer","Filter brightness, saturation and musical tension"];
        var recallWindow,tick=0;
        ~djWindow=window;
        deckLabels=Array.newClear(2);deckStatus=Array.newClear(2);
        titles=Array.fill(2,{ |deck|
            var x=20+(deck*425),title;
            deckLabels[deck]=StaticText(window,Rect(x,20,22,28)).font_(Font("Helvetica",16)).string_(["A","B"][deck]);
            deckStatus[deck]=StaticText(window,Rect(x+25,51,370,17)).font_(Font("Helvetica",11))
                .string_("Idle").stringColor_(Color.gray(0.45));
            title=TextField(window,Rect(x+25,18,370,32)).font_(Font("Helvetica",14))
                .string_("").toolTip_("Track details appear here when a record starts. Select a name to copy it.");
            title.setProperty(\readOnly,true);title;
        });
        progress=Slider(window,Rect(20,74,820,6)).enabled_(false).value_(0)
            .toolTip_("Mix position: left is deck A, right is deck B.");
        knobs=Array.fill(4,{ |i|
            var key=[\chaos,\density,\mutation,\tension][i],x=45+(i*205);
            StaticText(window,Rect(x,86,130,18)).string_(["Chaos","Density","Mutation","Tension"][i]);
            Knob(window,Rect(x,110,60,60)).mode_(\vert).value_(~djSettings[key]).action_ { |view|
                ~djSettings[key]=view.value;~djSet.value;
                ("DJ " ++ key ++ ": " ++ (view.value*100).round ++ "% / next bar").postln;
            };
        });
        transport=Button(window,Rect(20,190,90,30)).states_([["STOP"],["START"]])
            .toolTip_("Fade out, or continue the same set at its next bar.").action_ {
                if(~djPlaying ? false) {~djStop.value} {~djResume.value};
            };
        next=Button(window,Rect(120,190,90,30)).states_([["Next"]])
            .toolTip_("Queue the next record at the next four-bar boundary.").action_ {~djNext.value};
        hook=Button(window,Rect(220,190,85,30)).states_([["Bass hook"]])
            .toolTip_("Bring the hook forward for four bars.").action_ {~djHook.value};
        fill=Button(window,Rect(315,190,70,30)).states_([["Fill"]])
            .toolTip_("A drum fill on the next generated bar.").action_ {~djFill.value};
        hold=Button(window,Rect(395,190,100,30)).states_([["Hold"],["Held"]])
            .toolTip_("Keep this record and freeze motif mutations.").action_ { |view| ~djHold.value(view.value==1)};
        more=PopUpMenu(window,Rect(505,190,140,30)).items_(["More...","Mutate motif","Restart seed","Replay track..."])
            .toolTip_("Extra actions and track recall.").action_ { |view|
                switch(view.value,
                    1,{~djMutate.value},
                    2,{~djHold.value(false);~djStart.value(~djSeed ? 2600,~djInitialBpm ? 128,~djServer)},
                    3,{
                        if(recallWindow.isNil) {
                            var input,message,play;
                            recallWindow=Window("Replay a track",Rect(0,0,520,145).center_(Window.availableBounds.center));
                            message=StaticText(recallWindow,Rect(20,12,480,36)).string_("Paste a complete track name from your local recipe library.");
                            input=TextField(recallWindow,Rect(20,53,480,30));
                            play={try {~djRecall.value(input.string);recallWindow.close} { |error| message.string_(error.errorString)}};
                            input.action_(play);
                            Button(recallWindow,Rect(390,98,110,30)).states_([["Play track"]]).action_(play);
                            ~djUI[\recallField]=input;~djUI[\recallPlay]=play;
                            recallWindow.onClose_ {recallWindow=nil};recallWindow.front;input.focus;
                        } {recallWindow.front};
                    }
                );
                view.value_(0);
            };
        channel=PopUpMenu(window,Rect(665,190,175,30)).items_(["EDM","Pop","EDM Classic"])
            .toolTip_("Change channel and restart with a fade.").action_ { |view|~djChannel.value([\edme,\pop,\edm][view.value])};
        fxMenu=PopUpMenu(window,Rect(20,240,245,30)).items_(fxNames)
            .toolTip_("Choose an effect, then press Start FX. Selection alone does not activate it.").action_ { |view|
                ("DJ effect selected / " ++ fxNames[view.value] ++ " / press Start FX").postln;
            };
        fxButton=Button(window,Rect(280,240,120,30)).states_([["Start FX"],["Stop FX"]])
            .toolTip_("Start on the next bar; keep running until Stop FX. Stop releases immediately.").action_ { |view|
                if(view.value==1) {~djFXStart.value(fxKinds[fxMenu.value])} {~djFXStop.value};
            };
        auto=Button(window,Rect(420,240,110,30)).states_([["Auto OFF"],["Auto ON"]])
            .toolTip_("Occasional automatic half-bar stutters. Manual effects take priority.")
            .action_ { |view|~djAutoStutter.value(view.value==1)};
        spectrum=~djAddSpectrum.value(window,~djServer ? s,180,292);
        ~djSpectrum=spectrum;
        ~djUI=(window:window,titles:titles,deckStatus:deckStatus,deckLabels:deckLabels,progress:progress,knobs:knobs,transport:transport,
            next:next,hook:hook,fill:fill,hold:hold,more:more,channel:channel,
            fxMenu:fxMenu,fxButton:fxButton,auto:auto);
        update=Routine {
            loop {
                var playing=~djPlaying ? false,engine=~djEngine,manual=~djManualFX;
                var waiting=["waiting.","waiting..","waiting..."][(tick div:5)%3];
                tick=tick+1;
                spectrum[\refresh].value(playing);
                transport.value_(if(playing) {0} {1});
                fxButton.value_(if(manual.notNil) {1} {0}).enabled_(playing);
                fxMenu.enabled_(manual.isNil);
                if(engine.notNil) {
                    var state=engine.state,gains,blend,currentDeck=(state.currentSerial ? 0)%2;
                    // This is a physical A/B position, not completion of one handover.
                    // A new/resumed performance has no sent automation until its first bar.
                    gains=if(~djLastAutomation.notNil) {~djLastAutomation.gains} {
                        Array.fill(2,{ |deck|if(deck==currentDeck) {[1,1,1]} {[0,0,0]}})
                    };
                    blend=gains[1][2].clip(0,1);
                    channel.value_([\edme,\pop,\edm].indexOf(engine.channel) ? 0);
                    hook.states_([[if(engine.channel==\pop) {"Chorus"} {"Bass hook"}]]);
                    hold.value_(if(engine.controls.hold) {1} {0});
                    auto.value_(if(engine.controls.autoStutter) {1} {0});
                    next.enabled_(state.mixing.not);
                    progress.value_(blend).toolTip_("Mix A " ++ ((1-blend)*100).round.asInteger ++ "% / B "
                        ++ (blend*100).round.asInteger ++ "%\n" ++
                        (~djBpm ? state.bpm).round(0.01).asString ++ " BPM / bar " ++ (state.bar+1)
                        ++ if(state.mixing) {" / handover"} {" / playing"});
                    knobs.do { |knob,i|
                        var key=[\chaos,\density,\mutation,\tension][i],value=~djSettings[key];
                        knob.value_(value).toolTip_(descriptions[i] ++ " / " ++ (value*100).round ++ "% / next bar");
                    };
                    2.do { |deck|
                        var plan=state.decks[deck],audible,dominant,mixing,label,ink,background;
                        audible=playing and: {~djLastAutomation.notNil} and: {gains[deck].maxItem>0.001};
                        dominant=audible and: {gains[deck][2]>=gains[1-deck][2]};
                        mixing=gains[0][2]>0.001 and: {gains[1][2]>0.001};
                        ink=if(audible) {if(dominant) {Color.new255(20,113,78)} {Color.new255(38,92,137)}} {Color.gray(0.45)};
                        background=if(audible) {if(dominant) {Color.new255(224,244,233)} {Color.new255(235,243,250)}} {Color.white};
                        label=case {plan.isNil} {if(playing) {waiting} {"Idle"}}
                            {playing.not} {"Stopped"}
                            {~djLastAutomation.isNil} {"Starting"}
                            {audible and: {mixing}} {if(deck==currentDeck) {"Playing / fading out"} {"Playing / fading in"}}
                            {audible} {"Playing"}
                            {plan.serial>state.currentSerial} {"Cued"}
                            {true} {"Finished"};
                        deckStatus[deck].string_(label).stringColor_(ink);
                        deckLabels[deck].stringColor_(ink);
                        titles[deck].background_(background);
                        if(plan.notNil) {
                            if(titles[deck].string!=(plan.trackName ? plan.variation.name)) {
                                titles[deck].string_(plan.trackName ? plan.variation.name);
                                titles[deck].setProperty(\cursorPosition,0);
                            };
                            titles[deck].toolTip_(
                                plan.keyName ++ " / " ++ plan.section ++ " / " ++ plan.targetBpm ++ " BPM\n"
                                ++ plan.palette.name ++ " / " ++ plan.palette.kitName ++ "\n"
                                ++ plan.palette.bassName ++ " + " ++ plan.palette.leadName ++ "\n"
                                ++ "Chords " ++ ((plan[\currentProgression] ? plan.progression)+1).asString ++ if(plan.style==\pop) {" / current chord " ++ plan.schedule[plan.localBar].bars ++ " bars"} {" / lengths " ++ plan.durations.asString}
                                ++ " / " ++ plan.length ++ " bars\n"
                                ++ "Intensity " ++ (plan.intensity*100).round ++ "% / Chaos "
                                ++ (plan.effective.chaos*100).round ++ "% / Density " ++ (plan.effective.density*100).round ++ "%\n"
                                ++ "Select and copy the complete name. More > Replay track restores its starting recipe.");
                        } {
                            if(titles[deck].string.notEmpty) {titles[deck].string_("")};
                            titles[deck].toolTip_("Next record has not been cued yet.");
                        };
                    };
                } {
                    deckStatus.do { |label|label.string_(if(playing) {waiting} {"Idle"})};
                };
                0.1.wait;
            };
        }.play(AppClock);
        window.onClose_ {
            update.stop;if(recallWindow.notNil) {recallWindow.close};
            spectrum[\kill].value;~djSpectrum=nil;~djUI=nil;
            ~djStop.value;~djWindow=nil;
        };
        window.front;
    } {~djWindow.front};
};
)
