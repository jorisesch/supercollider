// Native two-deck view. Load after live.scd, then call ~djShow.value.
(
~djShow={
    if(~djWindow.isNil) {
        var window=Window("Infinite DJ / Evolving grooves",Rect(120,100,860,550));
        var headline, deckText, meters, progress, transport, hold, next, update;
        ~djWindow=window;
        headline=StaticText(window,Rect(20,10,820,28)).font_(Font("Helvetica",18));
        deckText=Array.fill(2,{ |deck|
            var x=20+(deck*425);
            StaticText(window,Rect(x,48,395,130));
        });
        meters=Array.fill(2,{ |deck|
            var x=20+(deck*425);
            Array.fill(3,{ |lane|
                StaticText(window,Rect(x,188+(lane*24),80,20)).string_(["Music","Bass","Drums"][lane]);
                LevelIndicator(window,Rect(x+85,190+(lane*24),300,14)).value_(0);
            });
        });
        progress=Slider(window,Rect(20,277,820,16)).enabled_(false).value_(0);
        StaticText(window,Rect(20,298,820,20)).string_("8/16-bar handovers / shared beat grid / knobs set the centre of the evolving groove");
        [\chaos,\density,\mutation,\tension].do { |key,i|
            var x=45+(i*205), label;
            StaticText(window,Rect(x,330,150,20)).string_(key.asString.toUpper);
            label=StaticText(window,Rect(x+80,370,65,22));
            label.string_((~djSettings[key]*100).round.asInteger.asString ++ "%");
            Knob(window,Rect(x,355,65,65)).mode_(\vert).value_(~djSettings[key]).action_ { |view|
                ~djSettings[key]=view.value; ~djSet.value;
                label.string_((view.value*100).round.asInteger.asString ++ "%");
            };
        };
        StaticText(window,Rect(20,445,820,24)).string_("Music and bass clear the old key before the new melody arrives. Meters show mix gains.");
        transport=Button(window,Rect(20,495,90,32)).states_([["STOP"],["START"]]).action_ {
            if(~djPlaying ? false) { ~djStop.value } { ~djResume.value };
            transport.value_(if(~djPlaying ? false,0,1));
        };
        next=Button(window,Rect(120,495,120,32)).states_([["NEXT record"]]).action_ { ~djNext.value };
        Button(window,Rect(250,495,75,32)).states_([["Hook"]]).action_ { ~djHook.value };
        Button(window,Rect(335,495,75,32)).states_([["Fill"]]).action_ { ~djFill.value };
        hold=Button(window,Rect(420,495,120,32)).states_([["Hold record"],["Record held"]])
            .action_ { |view| ~djHold.value(view.value == 1) };
        Button(window,Rect(550,495,125,32)).states_([["Restart seed"]]).action_ {
            ~djHold.value(false); ~djStart.value(~djSeed ? 2600,~djInitialBpm ? 128,~djServer);
        };
        Button(window,Rect(685,495,155,32)).states_([["Mutate motif"]]).action_ { ~djMutate.value };
        update=Routine {
            loop {
                var playing=~djPlaying ? false, engine=~djEngine;
                transport.value_(if(playing,0,1));
                if(engine.notNil) {
                    var state=engine.state, gains=~djGains ? [[0,0,0],[0,0,0]];
                    headline.string_(if(playing,"Playing","Stopped") ++ " / " ++ (~djBpm ? state.bpm).round(0.01)
                        ++ " BPM / Bar " ++ (state.bar+1) ++ if(state.mixing," / Handover"," / In the mix"));
                    progress.value_(~djProgress ? 0); hold.value_(if(engine.controls.hold,1,0));
                    next.enabled_(state.mixing.not);
                    2.do { |deck|
                        var plan=state.decks[deck], letter=if(deck == 0,"A","B");
                        if(plan.notNil) {
                            deckText[deck].string_("DECK " ++ letter ++ " / Tracks " ++ if(deck==0,"1-4","5-8") ++
                                " / Record " ++ (plan.serial+1) ++ "\n" ++ plan.variation.name ++ " / " ++ plan.keyName ++
                                " / " ++ plan.section ++ if(plan.hook," / HOOK","") ++
                                "\nDegrees " ++ (plan.progression+1).asString ++ "\nChord lengths " ++ plan.durations.asString ++ " / " ++ plan.length ++ " bars" ++
                                "\nIntensity " ++ (plan.intensity*100).round.asInteger ++ "% / Chaos " ++
                                (plan.effective.chaos*100).round.asInteger ++ "% / Density " ++
                                (plan.effective.density*100).round.asInteger ++ "%");
                        } { deckText[deck].string_("DECK " ++ letter ++ " / Waiting for next record") };
                        3.do { |lane| meters[deck][lane].value_(if(playing,gains[deck][lane],0)) };
                    };
                };
                0.1.wait;
            };
        }.play(AppClock);
        window.onClose_ { update.stop; ~djStop.value; ~djWindow=nil };
        window.front;
    } { ~djWindow.front };
};
)
