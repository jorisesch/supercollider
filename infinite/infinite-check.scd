// Batch composition checks. No server, sound, or WAV exports.
(
var root=thisProcess.nowExecutingPath.dirname;
var check = { |condition, message| if(condition.not) { Error(message).throw } };
try {
    var a, b, stable, bars, bassNotes=0, bassAnchors=0, low, high, f, plain, fillEvents, plainEvents;
    (root +/+ "infinite-live.scd").load;
    (root +/+ "infinite-controls.scd").load;
    ["infinite-run.scd", "infinite-render.scd"].do { |file|
        check.value(File.readAllString(root +/+ file).compile.notNil, file ++ " syntax failed");
    };
    check.value(~makeInfiniteEngine.notNil and: { ~showInfiniteControls.notNil }, "Definition load failed");
    ~infiniteDefs.do { |def| check.value(def.asBytes.size > 0, "Invalid SynthDef") };
    a=~makeInfiniteEngine.value(\edm, 2600); b=~makeInfiniteEngine.value(\edm, 2600);
    128.do { |bar|
        var x=a[\nextBar].value, y=b[\nextBar].value, previous=0;
        check.value(x.asCompileString == y.asCompileString, "Seed reproducibility failed");
        x.do { |event|
            var step=(event.beat * 4).asInteger;
            check.value(event.beat >= previous, "Events out of order"); previous=event.beat;
            check.value((event.beat >= 0) and: { event.beat < 4 } and: { event.duration > 0 }, "Event timing invalid");
            check.value((event.track >= 0) and: { event.track <= 3 }, "Expected exactly four lanes");
            if(event.track < 3) {
                check.value(a.state.scale.includes((event.midinote - a.state.key) % 12), "Default pitch escaped key");
            };
            if(event.track == 0) {
                var relative=(event.midinote - a.state.chord[0]) % 12;
                bassNotes=bassNotes + 1;
                if([0, 7].includes(relative)) { bassAnchors=bassAnchors + 1 };
            };
            if((event.track == 1) and: { step == 0 } and: { (bar % 4) == 0 }) {
                check.value(event.midinote == (a.state.chord[0] + 24), "Lead failed to resolve");
            };
        };
    };
    check.value((bassAnchors / bassNotes) > 0.90, "Bass does not favor root and fifth");
    stable=~makeInfiniteEngine.value(\edm, 2600, (chaos:0, tension:0, mutation:0));
    stable.state.progression=[0];
    bars=Array.fill(4, { stable[\nextBar].value.select { |event| event.track < 2 } });
    check.value(bars[0].asCompileString == bars[2].asCompileString, "Two-bar motif did not repeat");
    low=~makeInfiniteEngine.value(\edm, 2600, (density:0, chaos:0, arpProbability:1));
    high=~makeInfiniteEngine.value(\edm, 2600, (density:1, chaos:0, arpProbability:1));
    low=low[\nextBar].value; high=high[\nextBar].value;
    check.value(low.count { |e| e.track == 2 } == 3, "Low-density Euclidean pulse count failed");
    check.value(high.count { |e| e.track == 2 } == 14, "High-density Euclidean pulse count failed");
    check.value(high.size > low.size, "Density did not increase activity");
    f=~makeInfiniteEngine.value(\edm, 2600); plain=~makeInfiniteEngine.value(\edm, 2600);
    f[\requestFill].value; fillEvents=f[\nextBar].value; plainEvents=plain[\nextBar].value;
    check.value(fillEvents.count { |e| e.voice == \igSnare }
        == (plainEvents.count { |e| e.voice == \igSnare } + 3), "Fill button failed");
    ~setInfinite.value(2, -1, 0.3, 0.2);
    check.value((~infiniteSettings.chaos == 1) and: { ~infiniteSettings.density == 0 }, "Macro clamp failed");
    "PASS: definitions; 128 seeded bars; key membership; bass root/fifth bias; lead resolution; motif repetition; density; Euclidean pulses; fills; macro bounds.".postln;
    0.exit;
} { |error| error.reportError; 1.exit };
)
