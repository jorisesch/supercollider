// EDM E musical contracts. No playback or audio files.
(
var root=thisProcess.nowExecutingPath.dirname,assert={ |ok,message|if(ok.not) {Error(message).throw} };
try {
    var a,b,defs,counts=Dictionary.new,variants=Set.new,signatureBars=0,chordBars=0,deckBars=0;
    (root +/+ "engine.scd").load;(root +/+ "instruments.scd").load;
    defs=~djDefs.collect(_.name);
    ["e-style.scd","e-instruments.scd","../e-edm.scd","../e-render.scd"].do { |file|
        assert.value(File.readAllString(root +/+ file).compile.notNil,"EDM E parse failed: " ++ file)
    };
    a=~makeDJEngine.value(2600,128);
    assert.value(a.channel==\edme,"Standard EDM did not select the E grammar");
    b=~makeDJEngine.value(2600,128,(channel:\edme));
    1024.do {
        var f=a[\nextBar].value,g=b[\nextBar].value,last=0;
        assert.value(f.events.asCompileString==g.events.asCompileString,"E notes are not reproducible");
        assert.value(f.automation==g.automation,"E automation is not reproducible");
        f.decks.do { |plan|
            if(plan.notNil) {
                var own=f.events.select { |e|e.deck==plan.deck };
                deckBars=deckBars+1;variants.add(plan.eVariant);
                if(own.any { |e|e.role==\eSignature}) {signatureBars=signatureBars+1};
                if(own.any { |e|e.role==\eChord}) {chordBars=chordBars+1};
                if(plan.drumBreak) {assert.value(own.every { |e|e.lane==3},"E filled a drum spotlight with pitched parts")};
                if(plan.cutFrom<4) {
                    assert.value(own.select { |e|e.role==\djBass}.every { |e|e.beat<3},"E bass leaked into a pullback");
                };
            };
        };
        f.events.do { |e|
            var plan=f.decks[e.deck];
            assert.value(e.beat>=last and: {e.beat<4},"E event timing invalid");last=e.beat;
            assert.value(defs.includes(e.voice),"Missing E voice: " ++ e.voice);
            assert.value(e.duration>0 and: {e.duration<40} and: {e.amp>0} and: {e.amp<0.65},"Invalid E event bounds");
            if(e.lane<3 and: {e.role!=\eTurnaround}) {
                assert.value(plan.scale.includes((e.midinote-plan.key)%12),"E note left the key")
            };
            if((e[\glide] ? 0)>0) {
                counts[\slides]=(counts[\slides] ? 0)+1;
                assert.value(e.glide<=0.1,"E glide is too long");
                assert.value(~djMessage.value(e,1000,110,16,128).includes(\fromFreq),"Glide did not reach the note adapter");
            };
            counts[e.role]=(counts[e.role] ? 0)+1;
        };
    };
    [\eChord,\eTom,\eShaker,\eSignature,\eTurnaround,\slides].do { |role|
        assert.value((counts[role] ? 0)>10,"Missing E building block: " ++ role)
    };
    assert.value(variants==Set[\a,\b],"E has no A/B development");
    assert.value(signatureBars/deckBars<0.1 and: {chordBars/deckBars<0.4},"E supporting parts became continuous");
    a=~makeDJEngine.value(2600,128,(channel:\edme,hold:true));a[\requestHook].value;
    4.do {assert.value(a[\nextBar].value.decks[0].eVariant==\b,"E Bass hook did not request B")};
    assert.value(a[\nextBar].value.decks[0].eVariant==\a,"E Bass hook did not release after four bars");
    // Separate component comparisons retain the underlying drum/bass notes.
    [\percussion,\chords].do { |mode|
        var original=~makeDJEngine.value(2600,128,(channel:\edm,hold:true,autoStutter:false));
        var variant=~makeDJEngine.value(2600,128,(channel:\edme,eMode:mode,hold:true,autoStutter:false));
        16.do {
            var f=original[\nextBar].value,g=variant[\nextBar].value;
            var roles=[\djBass,\djKick,\djClap,\djSnare,\djHat];
            assert.value(f.events.select { |e|roles.includes(e.role)}==g.events.select { |e|roles.includes(e.role)},
                "A component comparison changed its foundation");
        };
    };
    ("PASS: EDM E / 1024 reproducible bars; voiced stabs, shaker/tom phrases, sparse signature, short turnaround, "
        ++ counts[\slides] ++ " glides; A/B return, four-bar Bass hook and unchanged comparison foundations. "
        ++ signatureBars ++ " signature / " ++ chordBars ++ " chord bars out of " ++ deckBars).postln;
    0.exit;
} { |error|error.reportError;1.exit};
)
