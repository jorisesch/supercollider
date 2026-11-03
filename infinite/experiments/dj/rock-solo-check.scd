// Phrase length, sparse placement and harmonic resolution, including pentatonic leads.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var bars=0,soloBars=0,landings=0,roots=0,fullLandings=0,thirds=0,fifths=0,lengths=Set.new;
    var checkLanding;
    (root+/+"engine.scd").load;(root+/+"recall.scd").load;
    checkLanding={|frame|
        frame.decks.do {|plan|if(plan.notNil){
            var lead=frame.events.select {|e|e.deck==plan.deck and:{e.role==\djHook}};
            var degree=plan.schedule[plan.localBar].degree,tones;
            tones=[0,2,4].collect {|offset|plan.scale.wrapAt(degree+offset)};
            lead.do {|e|
                var pc=(e.midinote-plan.key)%12;
                if(e[\rockLanding] ? false){
                    assert.value(e==lead.last,"A phrase continues after its landing note");
                    assert.value(tones.includes(pc),"Final note is not in the currently sounding chord");
                    assert.value(e.landingChordDegree==degree,"Landing uses a previous/future chord");
                    assert.value((e.beat+e.duration+(0.09*frame.automation[0].bpm/60))<4,"Landing sustains into the next chord bar");
                    assert.value(e.landingOffset==[0,2,4][tones.indexOf(pc)],"Landing classification is wrong");
                    landings=landings+1;if(e.landingOffset==2){thirds=thirds+1};if(e.landingOffset==4){fifths=fifths+1};
                    if(plan.melodyPalette.size==7){fullLandings=fullLandings+1;if(pc==tones[0]){roots=roots+1}};
                };
                if(plan.melodyPalette.size==5){assert.value(plan.melodyPalette.includes(pc),"Solo left its five-note palette")};
            };
            if(plan.rockSoloActive and:{plan.rockSoloKind==\solo}){
                soloBars=soloBars+1;lengths.add(plan.rockSoloBars);
                assert.value(frame.automation[0].progress==0,"Automatic solo starts during a handover");
                assert.value([\hook,\drop].includes(plan.section),"Automatic solo outside a release section");
                assert.value(lead.size==[3,3,5,2][plan.rockSoloAge%4],"Long riff has no melodic phrase");
                if(plan.rockSoloAge==(plan.rockSoloBars-1)){
                    assert.value(lead.last[\rockLanding] ? false,"Long solo has no resolving note");
                };
            };
        }};
    };
    [731,2600,8173,47429].do {|seed|
        [\original,\aeolian,\ionian,\dorian,\phrygian,\mixolydian,\lydian].do {|mode|
            [\full,\pentatonic].do {|melody|
                var a=~makeDJEngine.value(seed,102,(channel:\rock,tonality:mode,melody:melody));
                var b=~makeDJEngine.value(seed,102,(channel:\rock,tonality:mode,melody:melody));
                var previous=Dictionary.new;
                256.do {
                    var f=a[\nextBar].value,g=b[\nextBar].value;
                    assert.value(f.events==g.events and:{f.automation==g.automation},"Solos are not reproducible");
                    f.decks.do {|p|if(p.notNil and:{p.rockSoloActive}){
                        var old=previous[p.serial];
                        if(old.notNil and:{p.rockSoloAge>0}){assert.value(p.rockSoloAge==(old+1),"Solo skipped or repeated a bar")};
                        previous[p.serial]=p.rockSoloAge;
                    }};
                    checkLanding.value(f);bars=bars+1;
                };
            };
        };
    };
    assert.value(lengths==Set[4,8],"Four- and eight-bar solos are not both represented");
    assert.value(soloBars/bars<0.12 and:{soloBars>100},"Long solos are too common or missing");
    assert.value(roots/fullLandings>0.60 and:{thirds>0} and:{fifths>0},"Root preference or allowed chord tones are missing");
    // A chord root outside the minor pentatonic must resolve to its permitted third.
    {
        var plan=(mode:\minor,key:0,scale:[0,2,3,5,7,9,10]);
        var e=(role:\djHook,midinote:62,rockLanding:true,chordTones:[2,5,9],chordRoot:2);
        var result=~djMelodyPalette.value([e],plan,\pentatonic).first;
        assert.value((result.midinote%12)==5 and:{result.landingOffset==2},"Pentatonic snapping broke a chord-tone landing");
    }.value;
    [\full,\pentatonic].do {|melody|
        var engine=~makeDJEngine.value(2600,102,(channel:\rock,hold:true,melody:melody));
        engine[\requestHook].value;
        4.do {|i|
            var f=engine[\nextBar].value,plan=f.decks[0];
            assert.value(plan.rockSoloActive and:{plan.rockSoloKind==\riff} and:{plan.rockSoloAge==i},"Riff did not request a four-bar answer");
            checkLanding.value(f);
            {
                var lead=f.events.select {|e|e.role==\djHook};
                assert.value(lead.size==[3,3,5,2][i],"Requested riff lost its call, answer, climb or arrival");
                assert.value(lead.every {|e|e.slideBeats==0 and:{e.articulation==0}},"Melodic lead lost its picked attacks");
                if(i==3){
                    assert.value(lead.last.bendSemis==1 and:{lead.last.bendMode==2}
                        and:{lead.last.duration==2.45},"Requested riff lost its held semitone bend");
                };
            }.value;
        };
        assert.value(engine[\nextBar].value.decks[0].rockSoloActive.not,"Requested riff did not finish");
    };
    {
        var engine=~makeDJEngine.value(2600,102,(channel:\rock,hold:true)),f;
        3.do {engine[\nextBar].value};engine[\requestHook].value;engine[\nextBar].value;
        engine[\requestNext].value;f=engine[\nextBar].value;
        assert.value(f.decks[0].rockSoloKind==\cadence,"A handover interrupted the solo without a cadence");checkLanding.value(f);
    }.value;
    ~djRecipeDir=Platform.defaultTempDir+/+"dj-rock-solo-recipes";
    [\full,\pentatonic].do {|melody|
        var session=~makeDJSession.value(2600,102,(channel:\rock,melody:melody)),spec,expected=List.new,replay;
        84.do {|bar|
            var f;
            if(bar==3){session.controls.density=0.74};
            if(bar==4){session[\requestHook].value};
            if(bar==20){session[\requestNext].value};
            f=session[\nextBar].value;
            if(bar==20){spec=~djReadRecipe.value(f.decks[1].trackName)};
            if(bar>=20){expected.add([f.events.deepCopy,f.automation.deepCopy])};
        };
        assert.value(spec[0]==7 and:{spec.size==16} and:{spec[13]==3},"Recipe lost the solo grammar version");
        replay=~djSessionFromRecipe.value(spec);replay.persistRecipes=false;
        expected.do {|old|var f=replay[\nextBar].value;assert.value([f.events,f.automation]==old,"Solos differ after performance-history recall")};
    };
    {
        var spec=[4,96742884,2600,128,3,[0.25,0.55,0.3,1.0,0,0,-1],0,0,[],0,"original","full","fixed"];
        var name=~djRecipeName.value(spec),replay,reference;
        File.use(~djRecipeDir+/+(name++".json"),"w",{|file|file.write(spec.asCompileString)});
        replay=~djSessionFromRecipe.value(~djReadRecipe.value(name));replay.persistRecipes=false;
        reference=~makeDJEngine.value(2600,128,(channel:\rock,tension:1,rockLeadVersion:0,rockToneVersion:0));
        128.do {var a=replay[\nextBar].value,b=reference[\nextBar].value;
            assert.value(a.events==b.events and:{a.automation==b.automation},"Earlier Rock recipe acquired new solos");
        };
    }.value;
    ("PASS: "++bars++" Rock bars / "++soloBars++" solo bars; 4/8-bar phrasing, "++landings++" current-chord landings, root preference, pentatonic intersections, requested riffs and handover cadences").postln;
    0.exit;
} {|e|e.reportError;1.exit};
)
