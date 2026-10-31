// Native experiment panel. Baseline controls are not changed.
(
~showExperimentControls = {
    var window, status, holdButton, transportButton, update, title;
    if(~experimentWindow.isNil) {
    title=if((~experimentEngine.notNil) and: { ~experimentEngine[\profile] == \bite },
        "EDM B / More bite", if((~experimentEngine.notNil) and: { ~experimentEngine[\profile] == \d },
            "EDM D / Syncopated detail", if(~experimentMode == \edm,
                "EDM A / Melodic progressive EDM", "Warm ambient")));
    window=Window(title, Rect(180, 180, 560, 285));
    ~experimentWindow=window;
    StaticText(window, Rect(20, 12, 520, 26)).string_("Experiment / original generator remains available separately");
    [\chaos, \density, \mutation, \tension].do { |key, i|
        var x=20 + (i * 135), label, knob;
        StaticText(window, Rect(x, 46, 120, 20)).string_(key.asString.toUpper);
        label=StaticText(window, Rect(x, 145, 120, 20));
        knob=Knob(window, Rect(x + 20, 70, 70, 70)).mode_(\vert)
            .value_(~experimentSettings[key]).action_ { |view|
                ~experimentSettings[key]=view.value;
                ~setExperiment.value;
                label.string_((view.value * 100).round.asInteger.asString ++ "%");
            };
        label.string_((knob.value * 100).round.asInteger.asString ++ "%");
    };
    Button(window, Rect(20, 182, 95, 30)).states_([[if(~experimentMode == \edm, "Fill next bar", "Bloom")]]).action_ { ~fillExperiment.value };
    Button(window, Rect(125, 182, 95, 30)).states_([["Mutate"]]).action_ { ~mutateExperiment.value };
    holdButton=Button(window, Rect(230, 182, 95, 30)).states_([["Hold"], ["Held"]])
        .action_ { |view| ~holdExperiment.value(view.value == 1) };
    Button(window, Rect(335, 182, 95, 30)).states_([["Restart seed"]]).action_ {
        "Experiment: restart seed requested.".postln;
        holdButton.value_(0);
        ~startExperiment.value(~experimentMode ? \edm, ~experimentSeed ? 2600, ~experimentBpm, ~experimentServer);
    };
    transportButton=Button(window, Rect(440, 182, 95, 30)).states_([["STOP"], ["START"]])
        .value_(if(~experimentPlaying ? false, 0, 1)).action_ { |view|
            if(~experimentPlaying ? false) {
                "Experiment: STOP requested.".postln;
                ~stopExperiment.value;
            } { ~resumeExperiment.value };
            view.value_(if(~experimentPlaying ? false, 0, 1));
        };
    status=StaticText(window, Rect(20, 225, 520, 42));
    update=Routine {
        loop {
            var engine=~experimentEngine, playing=~experimentPlaying ? false;
            transportButton.value_(if(playing, 0, 1));
            if(engine.notNil) {
                status.string_(if(playing, "Playing / Bar ", "Stopped / Bar ") ++ (engine.state.bar + 1) ++ " / " ++ engine.state.section
                    ++ " / " ++ engine.bpm ++ " BPM\n" ++ if(playing,
                        "Changes enter on the next bar. Close window to fade and stop.",
                        "START continues next bar. Restart seed begins again."));
            };
            0.25.wait;
        };
    }.play(AppClock);
    window.onClose_ { update.stop; ~stopExperiment.value; ~experimentWindow=nil };
    window.front;
    } { ~experimentWindow.front };
};
)
