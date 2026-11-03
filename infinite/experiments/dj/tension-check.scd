// Sparse harmony policy: musical boundaries, rarity, familiar choruses and recall.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var totals=Dictionary.new,charNotes=(dorian:9,phrygian:1,mixolydian:10,lydian:6),heard=Set.new;
    (root+/+"engine.scd").load;(root+/+"recall.scd").load;
    [\edme,\pop].do {|channel|
        [0.2,0.6,0.75,1.0].do {|tension|
            var settings=(channel:channel,tension:tension),active=0,counts=Dictionary.new;
            var engine=~makeDJEngine.value(2600,128,settings),reference;
            var lastTone=nil,lastEnd= -100,run=0;
            reference=~makeDJEngine.value(2600,128,settings.copy.put(\modalPolicy,\fixed));
            4096.do {|bar|
                var f=engine[\nextBar].value,g=reference[\nextBar].value,colored=false;
                var drums=[\djKick,\djClap,\djSnare,\djHat];
                assert.value(f.automation==g.automation,"Modal policy changed the existing FX/tempo behavior");
                assert.value(f.events.select {|e|drums.includes(e.role)}==g.events.select {|e|drums.includes(e.role)},"Modal choices disturbed the drum foundation");
                f.decks.do {|p|if(p.notNil){
                    if(p.modalAccent){
                        var allowed=if(p.mode==\minor){[\dorian,\phrygian]}{[\mixolydian,\lydian]};
                        colored=true;active=active+1;counts[p.activeTonality]=(counts[p.activeTonality] ? 0)+1;
                        assert.value(tension>0.6 and:{allowed.includes(p.activeTonality)},"Wrong mode family/threshold");
                        if([\phrygian,\lydian].includes(p.activeTonality)){assert.value(tension>0.85,"Rare color below its Tension threshold")};
                        assert.value([6,7].includes(p.localBar%8) and:{engine.state.mixing.not},"Mode changed outside a phrase ending or during handover");
                        assert.value([\hook,\drop,\intro,\outro].includes(p.section).not,"A chorus or intro was recolored");
                        if(run==0){assert.value(bar>=(lastEnd+16),"Modal accents crowded together")};
                        lastTone=p.activeTonality;
                    }{
                        assert.value(p.scale==p.baseScale,"Scale did not return to its base");
                    };
                }};
                f.events.do {|e|
                    var p=f.decks[e.deck],pc=(e.midinote-p.key)%12;
                    if(e.lane<3 and:{e.role!=\eTurnaround}){
                        assert.value(p.scale.includes(pc),"A voice left the active scale");
                        if(p.modalAccent and:{pc==charNotes[p.activeTonality]}){heard.add(p.activeTonality)};
                    };
                };
                if(colored){run=run+1;assert.value(run<=2,"Modal color lasted over two bars")}{
                    if(run>0){lastEnd=bar;run=0};lastTone=nil;
                };
                if(tension<=0.6){assert.value(f.events==g.events,"Low Tension changed the ordinary notes")};
            };
            assert.value(active/4096<0.09,"Too much modal harmony");
            if(tension<=0.6){assert.value(active==0,"Low Tension should have no modal accents")};
            if(tension==1){
                var mild=(counts[\dorian] ? 0)+(counts[\mixolydian] ? 0),rare=(counts[\phrygian] ? 0)+(counts[\lydian] ? 0);
                [\dorian,\phrygian,\mixolydian,\lydian].do {|mode|assert.value((counts[mode] ? 0)>0,"A mode never occurs in "++channel)};
                assert.value(mild>rare and:{rare>0},"Rare modes are not rarer or never occur");
                assert.value(rare/4096<0.02,"Esoteric modes are too common");
            };
            totals[channel.asString++" / "++tension]=(coloredBars:active,totalBars:4096,modes:counts);
        };
    };
    assert.value(heard==Set[\dorian,\phrygian,\mixolydian,\lydian],"A color's characteristic note never sounds");
    ~djRecipeDir=Platform.defaultTempDir+/+"dj-tension-recall";
    [\edme,\pop].do {|channel|
        var session=~makeDJSession.value(2600,128,(channel:channel)),spec,replay,expected=List.new;
        36.do {|bar|
            var frame;
            if(bar==1){session.controls.tension=1};
            if(bar==3){session.controls.density=0.74};
            if(bar==20){session[\requestNext].value};
            frame=session[\nextBar].value;
            if(bar==20){spec=~djReadRecipe.value(frame.decks[1].trackName)};
            if(bar>=20){expected.add([frame.events.deepCopy,frame.automation.deepCopy])};
        };
        assert.value(spec.size==16 and:{spec[0]==7} and:{spec[12]=="tension"},"Recipe does not retain its harmony policy");
        replay=~djSessionFromRecipe.value(spec);replay.persistRecipes=false;
        expected.do {|old|var f=replay[\nextBar].value;assert.value([f.events,f.automation]==old,"Tension history/phase differs on recall")};
    };
    totals.keysValuesDo {|key,value|(key++" / "++value.asCompileString).postln};
    "PASS: 32768 bars; two minor/two major extensions; sparse two-bar accents, cooldown, safe families, untouched choruses/drums/FX, characteristic notes and exact Tension recall".postln;
    0.exit;
} {|error|error.reportError;1.exit};
)
