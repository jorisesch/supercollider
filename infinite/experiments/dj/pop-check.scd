// Pure generative contract: reproducibility, chorus memory, handovers and routing.
(
var root=thisProcess.nowExecutingPath.dirname;
var assert={ |condition,message| if(condition.not) {Error(message).throw} };
try {
    var a,b,records=Set.new,sections=Set.new,hooks=Dictionary.new,mixes=0,defs;
    (root+/+"engine.scd").load; (root+/+"instruments.scd").load;
    defs=~djDefs.collect(_.name);
    ["live.scd","controls.scd","launch.scd","../pop.scd","../../infinite-run.scd"].do { |file|
        assert.value(File.readAllString(root+/+file).compile.notNil,"Parse failure: "++file);
    };
    a=~makeDJEngine.value(2600,138,(channel:\pop,autoStutter:false));
    b=~makeDJEngine.value(2600,138,(channel:\pop,autoStutter:false));
    1024.do { |bar|
        var f=a[\nextBar].value,g=b[\nextBar].value;
        assert.value(f.events==g.events,"Pop is not reproducible");
        assert.value(f.automation==g.automation,"Pop automation is not reproducible");
        if(a.state.mixing) {mixes=mixes+1};
        f.decks.do { |plan|
            if(plan.notNil) {
                var key=plan.serial.asString++"/"++(plan.localBar%4),notes;
                records.add(plan.serial); sections.add(plan.section);
                assert.value(plan.style==\pop,"Pop record uses EDM grammar");
                if([\hook,\drop].includes(plan.section)) {
                    notes=f.events.select { |e| e.deck==plan.deck and:{e.role==\djHook} }
                        .collect { |e| [e.beat,e.midinote,e.duration] };
                    assert.value(notes.size==8,"Chorus lost its hook");
                    if(hooks[key].notNil) {assert.value(hooks[key]==notes,"Chorus hook changed on return")};
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
    // Hold retains a record, NEXT releases it, and forced chorus / fill reach the next bar.
    a=~makeDJEngine.value(99,138,(channel:\pop,hold:true));
    200.do {a[\nextBar].value};
    assert.value(a.state.currentSerial==0,"Hold changed the Pop record");
    a[\requestHook].value; a[\requestFill].value;
    assert.value(a[\nextBar].value.events.any { |e| e.role==\djHook },"Forced chorus is missing");
    a[\requestNext].value; 32.do {a[\nextBar].value};
    assert.value(a.state.currentSerial>0,"NEXT did not override Hold");
    "PASS: Pop / 1024 reproducible bars, chorus returns, scales, routing, handovers, Hold/NEXT".postln;
    0.exit;
} { |error| error.reportError; 1.exit };
)
