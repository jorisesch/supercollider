// Round 04 song styles in the live EDM/Pop rotation. Pure engine check; no audio.
(
var root=thisProcess.nowExecutingPath.dirname,neonLeads=Set.new,bare=Set.new,assert={|ok,message|if(ok.not){Error(message).throw}};
try {
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;
    assert.value(~djSongStyles.size==5,"Expected five approved song styles");
    [\edme,\pop].do {|channel|
        var expected=~djSongStyles.select {|spec|spec.channel==channel}.collect(_.name).asSet;
        var heard=Set.new,keys=Set.new,bpms=Set.new,lengths=Set.new,modes=Set.new,seen=Set.new;
        [11,2600,4242,90001].do {|seed|
            var engine=~makeDJEngine.value(seed,128,(channel:channel,autoStutter:false));
            500.do {
                var frame=engine[\nextBar].value;
                frame.decks.do {|plan|
                    if(plan.notNil and:{plan.palette[\songStyle].notNil}){
                        var spec=plan.palette.songStyle,mine=frame.events.select {|e|e.deck==plan.deck};
                        var local=(plan.position-1)%plan.length,degree=plan.schedule[local].degree;
                        var tones=[0,2,4].collect {|o|plan.scale.wrapAt(degree+o)};
                        heard.add(spec.name);
                        if(seen.includes([seed,plan.serial]).not){
                            seen.add([seed,plan.serial]);keys.add(plan.key);bpms.add(plan.targetBpm);
                            lengths.add(plan.length);modes.add(plan.baseTonality);
                        };
                        assert.value(spec.channel==channel,"Style played on the wrong channel");
                        neonLeads.add(plan[\styleLead] !? {|lead|lead.voice} ? \none);
                        if(plan[\styleLead].isNil){
                            assert.value(mine.every {|e|e.lane!=1},"No-lead version played a lead");
                        };
                        mine.select {|e|e.lane==1}.do {|e|
                            assert.value(e.voice==plan.styleLead.voice,"Lead changed sound mid-song");
                            assert.value(e.midinote>=57 and:{e.midinote<=83},"Lead left its range");
                        };
                        if(plan.styleBare==true){
                            bare.add(spec.id);
                            assert.value(spec.id=="C" and:{plan.styleLead.voice==\neonSoftKeys},"Wrong style dropped its groove");
                            if([\space,\breakdown].includes(plan.section) and:{local>=plan.openingBars}){
                                assert.value(mine.every {|e|[1,2].includes(e.lane)},"Groove-free breakdown kept drums or bass");
                            };
                        };
                        mine.select {|e|e.lane==2}.do {|e|
                            assert.value(tones.includes((e.midinote-plan.key)%12),"Pad left the generated chord");
                        };
                        if(local<plan.openingBars){assert.value(mine.every {|e|e.lane==3},"Style intro has pitched parts")};
                        mine.do {|e|assert.value(~djDefs.any {|d|d.name==e.voice},"Unknown style voice")};
                    };
                };
            };
        };
        assert.value(heard==expected,"Rotation missed an approved "++channel++" style");
        // Styles are generated like any other record: keys, tempo, form and mode vary.
        assert.value(keys.size>=3 and:{bpms.size>=3} and:{lengths.size>=2} and:{modes.size>=2},
            "Song styles did not vary key, tempo, form and mode");
    };
    assert.value(neonLeads==Set[\neonSoftKeys,\neonCleanPluck,\none],
        "Styles did not rotate soft keys, clean pluck and no lead: "++neonLeads.asString);
    assert.value(bare==Set["C"],"Night Signal never played a groove-free breakdown");
    // The approved arrangement still uses the same grammar.
    ~djSongStyles.do {|spec|
        var state=~djSongStyleState.value;
        32.do {|bar|
            var events=~djSongStyleSourceBar.value(spec,bar,state).events;
            if(bar<4){assert.value(events.every {|e|e.lane==3},"Approved intro has pitched parts")};
        };
    };
    // Original-grammar checks and other EDM variants leave the styles out.
    [(songStyles:false),(eMode:\percussion)].do {|settings|
        var engine=~makeDJEngine.value(11,128,(channel:\edme,autoStutter:false).putAll(settings));
        300.do {
            engine[\nextBar].value.decks.do {|plan|
                assert.value(plan.isNil or:{plan.palette[\songStyle].isNil},"Style ignored "++settings.asString);
            };
        };
    };
    "Song styles OK".postln;
    0.exit;
} {|error|error.reportError;1.exit};
)
