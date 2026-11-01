// Pure generative contract: reproducibility, chorus memory, handovers and routing.
(
var root=thisProcess.nowExecutingPath.dirname;
var assert={ |condition,message| if(condition.not) {Error(message).throw} };
try {
    var a,b,records=Set.new,sections=Set.new,hooks=Dictionary.new,mixes=0,defs;
    var progressions=(major:Set.new,minor:Set.new),rhythms=Set.new,firstChoices=Set.new;
    var sawOneBar=false,returns=0,lib;
    (root+/+"engine.scd").load; (root+/+"instruments.scd").load;
    defs=~djDefs.collect(_.name);
    lib=~djPopLibrary.value(~djLibrary);
    [\major,\minor].do { |mode|
        assert.value(lib[mode].asSet.size==24,"Pop progressions are duplicated or missing");
    };
    [1,99,2600,7429,12345,65537,104729,999999].do { |seed|
        var engine=~makeDJEngine.value(seed,138,(channel:\pop));
        firstChoices.add(engine[\nextBar].value.decks[0].progression.asCompileString);
    };
    assert.value(firstChoices.size>=4,"First Pop progression ignores the seed");
    ["live.scd","controls.scd","launch.scd","../pop.scd","../../infinite-run.scd"].do { |file|
        assert.value(File.readAllString(root+/+file).compile.notNil,"Parse failure: "++file);
    };
    a=~makeDJEngine.value(2600,138,(channel:\pop,autoStutter:false));
    b=~makeDJEngine.value(2600,138,(channel:\pop,autoStutter:false));
    8192.do { |bar|
        var f=a[\nextBar].value,g=b[\nextBar].value;
        assert.value(f.events==g.events,"Pop is not reproducible");
        assert.value(f.automation==g.automation,"Pop automation is not reproducible");
        if(a.state.mixing) {mixes=mixes+1};
        f.decks.do { |plan|
            if(plan.notNil) {
                var key=plan.serial.asString++"/"++(plan.localBar%4),notes;
                var chord=plan.schedule[plan.localBar];
                if(records.includes(plan.serial).not) {
                    var harmony=plan.harmony;
                    progressions[plan.mode].add(harmony.verse.asCompileString);
                    rhythms.add(plan.durations.asCompileString);
                    [harmony.chorus,harmony.bridge].do { |other|
                        assert.value((0..3).every { |n| other!=harmony.verse.rotate(n) },
                            "Section harmony is just a rotated verse");
                    };
                    assert.value(harmony.chorus!=harmony.bridge,"Bridge repeated chorus harmony");
                    assert.value(harmony.bridge.every { |degree|
                        plan.schedule.any { |chord| chord.harmonyRole==\bridge and:{chord.degree==degree} }
                    },"Planned bridge harmony never reaches the sound");
                    assert.value(plan.schedule.every { |c| c.notNil and:{c.bars>0} and:{(0..6).includes(c.degree)} },
                        "Incomplete or out-of-key harmonic schedule");
                };
                records.add(plan.serial); sections.add(plan.section);
                sawOneBar=sawOneBar or:{chord.bars==1};
                assert.value(plan.currentProgression.includes(chord.degree),"Wrong section progression");
                f.events.select { |e| e.deck==plan.deck and:{e.role==\djBass} }.do { |e|
                    assert.value((e.midinote-plan.key)%12==plan.scale[chord.degree],"Bass disagrees with scheduled chord");
                };
                assert.value(plan.style==\pop,"Pop record uses EDM grammar");
                if([\hook,\drop].includes(plan.section)) {
                    notes=f.events.select { |e| e.deck==plan.deck and:{e.role==\djHook} }
                        .collect { |e| [e.beat,e.midinote,e.duration] };
                    assert.value(notes.size==8,"Chorus lost its hook");
                    if(hooks[key].notNil) {assert.value(hooks[key]==notes,"Chorus hook changed on return");returns=returns+1};
                    hooks[key]=notes;
                };
            };
        };
        f.events.do { |e|
            var plan=f.decks[e.deck];
            assert.value(e.beat>=0 and:{e.beat<4},"Pop event outside bar");
            assert.value(e.duration>0 and:{e.amp>0},"Invalid Pop envelope");
            assert.value(defs.includes(e.voice),"Missing Pop instrument");
            if(e.lane<3) {
                assert.value(plan.scale.includes((e.midinote-plan.key)%12),"Pop note outside key");
            };
        };
    };
    assert.value(records.size>8 and:{mixes>32},"Missing automatic Pop handovers");
    assert.value([\groove,\hook,\breakdown,\drop].every { |s| sections.includes(s) },"Missing Pop song sections");
    assert.value(progressions.major.size==24 and:{progressions.minor.size==24},"Progression bag did not cover the catalog");
    assert.value(rhythms.size==8 and:{sawOneBar},"Pop chord durations still repeat the old two-bar grid");
    assert.value(returns>100,"Returning chorus hooks were not checked");
    // Hold retains a record, NEXT releases it, and forced chorus / fill reach the next bar.
    a=~makeDJEngine.value(99,138,(channel:\pop,hold:true));
    200.do {a[\nextBar].value};
    assert.value(a.state.currentSerial==0,"Hold changed the Pop record");
    a[\requestHook].value; a[\requestFill].value;
    assert.value(a[\nextBar].value.events.any { |e| e.role==\djHook },"Forced chorus is missing");
    a[\requestNext].value; 32.do {a[\nextBar].value};
    assert.value(a.state.currentSerial>0,"NEXT did not override Hold");
    "PASS: Pop / 8192 reproducible bars; all 48 progressions and 8 rhythms; contrasting section harmony; seeded openings; bass/chord alignment; stable chorus returns, routing, handovers, Hold/NEXT".postln;
    0.exit;
} { |error| error.reportError; 1.exit };
)
