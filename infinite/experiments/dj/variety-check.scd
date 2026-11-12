// Current generator, feedback persistence and deterministic replay.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var total=0,signatures=Set.new,feedbackPath=Platform.defaultTempDir+/+"dj-feedback-check";
    (root+/+"live.scd").load;
    [\edme,\pop,\rock].do {|channel|
        var modes=Set.new,orders=Set.new,lengths=Set.new,keys=Set.new,palettes=Set.new;
        [73,731,2600,98713].do {|seed|
            var a=~makeDJEngine.value(seed,128,(channel:channel,tension:0.96));
            var b=~makeDJEngine.value(seed,128,(channel:channel,tension:0.96));
            var seen=Set.new;
            384.do {
                var f=a[\nextBar].value,g=b[\nextBar].value;
                assert.value(f.events==g.events and:{f.automation==g.automation},"Explicit seed lost reproducibility");
                f.decks.do {|plan|if(plan.notNil and:{plan.localBar<plan.openingBars}){
                    var notes=f.events.select {|event|event.deck==plan.deck};
                    assert.value(notes.notEmpty and:{notes.every {|event|event.lane==3}},"Song intro is not rhythm only");
                }};
                f.decks.do {|plan|if(plan.notNil and:{seen.includes(plan.serial).not}){
                    var cursor=0;
                    assert.value(plan.localBar==0,"Song skipped its rhythm intro when cued");
                    seen.add(plan.serial);modes.add(plan.baseTonality);keys.add(plan.key);palettes.add(plan.palette.id);
                    orders.add(plan.sections.collect(_.name).asCompileString);lengths.add(plan.length);
                    plan.sections.do {|part|
                        assert.value(part.start==cursor and:{part.bars>=4} and:{part.bars%4==0},"Song form has a gap or invalid phrase");
                        cursor=cursor+part.bars;
                    };
                    assert.value(cursor==plan.length and:{plan.schedule.size==plan.length},"Harmony does not fill the form");
                    assert.value(plan.sections.any {|part|[\hook,\drop].includes(part.name)},"Song lacks a release section");
                    if(plan.serial==0){signatures.add([channel,plan.key,plan.baseTonality,plan.palette.id,plan.variation.id,plan.formID].asCompileString)};
                }};
                f.events.do {|e|
                    assert.value(e.beat.inclusivelyBetween(0,3.99) and:{e.duration>0},"Invalid event");
                    if(e.role==\djHook and:{e[\rockLanding] ? false}){
                        assert.value(e.chordTones.includes((e.midinote-f.decks[e.deck].key)%12),"Rock solo missed its chord");
                    };
                };total=total+1;
            };
        };
        [channel,modes.asArray,orders.size,lengths.size,keys.size,palettes.size].postln;
        assert.value(modes.size>=5 and:{orders.size>=4} and:{lengths.size>=5} and:{keys.size>=6},"Songs still repeat too few musical choices");
    };
    assert.value(signatures.size>=10,"Different seeds repeat the opening record");
    {
        var engine=~makeDJEngine.value(731,140,(channel:\dubstep)),seen=Set.new;
        192.do {
            var frame=engine[\nextBar].value;
            frame.decks.do {|plan|if(plan.notNil){
                if(seen.includes(plan.serial).not){
                    assert.value(plan.localBar==0 and:{plan.openingBars==4},"Dubstep skipped its rhythm intro");
                    seen.add(plan.serial);
                };
                if(plan.localBar<plan.openingBars){
                    var notes=frame.events.select {|event|event.deck==plan.deck};
                    assert.value(notes.notEmpty and:{notes.every {|event|event.lane==3}},"Dubstep intro has pitched parts");
                };
            }};
        };
        assert.value(seen.size>=2,"Dubstep did not rotate songs");
    }.value;
    [\edme,\pop].do {|channel|
        var openingPalettes=Set.new,openingKeys=Set.new,openingModes=Set.new;
        (1..24).collect {|i|i*7919}.do {|seed|
            var session=~makeDJEngine.value(seed,134,(channel:channel,openWithHook:true));
            var frame;
            8.do {
                frame=session[\nextBar].value;
                openingPalettes.add(frame.decks[0].palette.id);
                openingKeys.add(frame.decks[0].key);openingModes.add(frame.decks[0].baseTonality);
                assert.value(frame.events.every {|e|e.lane==3},"Pitched parts entered during the drum opening");
                assert.value(frame.events.select {|e|e.role==\djKick}.collect(_.step)==[0,4,8,12],"Opening lost its kick pulse");
            };
            frame=session[\nextBar].value;
            assert.value(frame.events.any {|e|e.role==\djBass},"Bass did not enter after eight drum bars");
            assert.value(frame.decks[0].section!=\intro,"Opening did not enter the full song");
        };
        assert.value(openingPalettes.size>=3 and:{openingKeys.size>=4 and:{openingModes.size>=2}},"First song choices are still fixed");
    };
    [\edme,\pop,\rock].do {|channel|~djTonalities.keys.do {|tone|[\full,\pentatonic].do {|melody|
        var engine=~makeDJEngine.value(439,128,(channel:channel,tonality:tone,modalPolicy:\fixed,melody:melody));
        engine[\requestHook].value;
        24.do {
            var f=engine[\nextBar].value;
            f.decks.do {|p|if(p.notNil){assert.value(p.baseTonality==tone and:{p.scale==~djTonalities[tone].scale},"Pinned mode changed")}};
            f.events.do {|e|if(e.role==\djHook){
                var p=f.decks[e.deck];
                assert.value(p.melodyPalette.includes((e.midinote-p.key)%12),"Melody left the selected palette");
            }};
        };
    }}};
    ~djRecipeDir=Platform.defaultTempDir+/+"dj-variety-recipes";
    [\edme,\pop,\rock].do {|channel|
        var session=~makeDJSession.value(731,128,(channel:channel)),spec,replay,frames=List.new;
        48.do {|bar|
            var f;
            if(bar==4){session[\requestHook].value};
            if(bar==8){session.controls.tension=0.9;session[\requestNext].value};
            f=session[\nextBar].value;
            if(bar==8){spec=session.recipeSpecs[f.decks[1].serial].deepCopy};
            if(bar>=8){frames.add([f.events.deepCopy,f.automation.deepCopy])};
        };
        replay=~djSessionFromRecipe.value(spec);replay.persistRecipes=false;
        frames.do {|expected,i|
            var f=replay[\nextBar].value;
            assert.value([f.events,f.automation]==expected,"New recipe replay differs from heard music");
            if(i==0){
                var heard=~djFeedbackTracks.value(replay,f).detect {|track|
                    track.notNil and:{track.record.serial==spec[6]}
                };
                assert.value(heard.notNil and:{heard.recipe==spec},"Recalled song feedback lost its original recipe");
            };
        };
    };
    // Snapshot and vote without changing either the score or future selections.
    {
        var session=~makeDJSession.value(814,128,(channel:\pop),false),reference=~makeDJSession.value(814,128,(channel:\pop),false);
        var frame=session[\nextBar].value,files,first,expected,loaded;
        reference[\nextBar].value;
        ~djFeedbackDir=feedbackPath;~djRatings=Dictionary.new;~djPlaying=true;
        ~djHeardTracks=~djFeedbackTracks.value(session,frame);~djLastAutomation=frame.automation[0];~djEngine=session;
        ~djFeedbackRunID="variety-check-"++~djFreshSeed.value;~djFeedbackCounter=0;
        assert.value(~djRate.value(0,1),"Thumbs up failed");
        first=~djRatings[frame.decks[0].trackName];
        assert.value(~djRate.value(0,1),"Repeated thumbs up failed");
        assert.value(~djFeedbackCounter==1,"Repeated rating produced duplicate training data");
        assert.value(~djRate.value(0,-1),"Thumbs down failed");
        loaded=~djRatings[frame.decks[0].trackName];
        assert.value(loaded.rating== -1 and:{loaded.supersedes==first.id},"Changed rating lost revision link");
        assert.value(~djRate.value(1,1).not,"An empty deck accepted a vote");
        ~djLoadRatings.value;
        assert.value(~djRatings[frame.decks[0].trackName].rating== -1,"Rating did not survive reload");
        64.do {
            var a=session[\nextBar].value,b=reference[\nextBar].value;
            assert.value(a.events==b.events and:{a.automation==b.automation},"Votes changed the generator");
        };
        assert.value(first.record.keyName==frame.decks[0].keyName,"Feedback snapshot mutated after playback");
        files=(feedbackPath+/+"*.json").pathMatch;
        assert.value(files.size>=2,"Training feedback files are missing");
    }.value;
    ("PASS: "++total++" varied reproducible bars; new modes, forms, recall, durable revised ratings and unchanged playback after votes").postln;
    0.exit;
} {|error|error.reportError;1.exit};
)
