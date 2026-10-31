// Optional native control panel. Load after infinite-live.scd, then ~showInfiniteControls.value.
(
~showInfiniteControls = {
    var window, status, holdButton, update;
    if(~infiniteWindow.isNil) {
    window=Window("Infinite music", Rect(180, 180, 560, 285));
    ~infiniteWindow=window;
    StaticText(window, Rect(20, 12, 520, 26)).string_("Four tracks / shared harmony / controlled variation");
    [\chaos, \density, \mutation, \tension].do { |key, i|
        var x=20 + (i * 135), label, knob;
        StaticText(window, Rect(x, 46, 120, 20)).string_(key.asString.toUpper);
        label=StaticText(window, Rect(x, 145, 120, 20));
        knob=Knob(window, Rect(x + 20, 70, 70, 70)).mode_(\vert)
            .value_(~infiniteSettings[key]).action_ { |view|
                ~infiniteSettings[key]=view.value;
                ~setInfinite.value;
                label.string_((view.value * 100).round.asInteger.asString ++ "%");
            };
        label.string_((knob.value * 100).round.asInteger.asString ++ "%");
    };
    Button(window, Rect(20, 182, 95, 30)).states_([["Fill next bar"]]).action_ { ~fillInfinite.value };
    Button(window, Rect(125, 182, 95, 30)).states_([["Mutate"]]).action_ { ~mutateInfinite.value };
    holdButton=Button(window, Rect(230, 182, 95, 30)).states_([["Hold motifs"], ["Held"]])
        .action_ { |view| ~holdInfinite.value(view.value == 1) };
    Button(window, Rect(335, 182, 95, 30)).states_([["Restart seed"]]).action_ {
        holdButton.value_(0);
        ~startInfinite.value(~infiniteMode ? \edm, ~infiniteSeed ? 2600, ~infiniteBpm, ~infiniteServer);
    };
    Button(window, Rect(440, 182, 95, 30)).states_([["Stop"]]).action_ { ~stopInfinite.value };
    status=StaticText(window, Rect(20, 225, 520, 42));
    update=Routine {
        loop {
            var engine=~infiniteEngine;
            if(engine.notNil) {
                status.string_("Bar " ++ (engine.state.bar + 1) ++ " / " ++ engine.state.section
                    ++ " / " ++ engine.bpm ++ " BPM\nChanges enter on the next bar. Close window to fade and stop.");
            };
            0.25.wait;
        };
    }.play(AppClock);
    window.onClose_ { update.stop; ~stopInfinite.value; ~infiniteWindow=nil };
    window.front;
    } { ~infiniteWindow.front };
};
)
