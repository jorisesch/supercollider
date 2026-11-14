// Song identity, bounded guitar choices, unchanged rhythm section and recall.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var count=0,notes=0,landings=0,names=Set.new,records=Dictionary.new;
    var report=List.new;
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;(root+/+"recall.scd").load;
    [\original,\ionian,\dorian,\phrygian,\mixolydian,\lydian].do {|mode|3.do {|id|[\full,\pentatonic].do {|melody|
        var settings=(channel:\rock,palette:id,tonality:mode,melody:melody);
        var a=~makeDJEngine.value(731,102,settings),b=~makeDJEngine.value(731,102,settings.copy.put(\rockPlayerVersion,0));
        var signatures=Dictionary.new;
        96.do {|bar|
            var frame,old;
            if(bar%16==0){a[\requestHook].value;b[\requestHook].value};
            if(bar==36){a[\requestMutation].value;b[\requestMutation].value};
            if(bar==64){a[\requestNext].value;b[\requestNext].value};
            a.controls.tension=(bar%3)*0.5;b.controls.tension=a.controls.tension;
            a.controls.density=if(bar%17==0){0.1}{0.55};b.controls.density=a.controls.density;
            frame=a[\nextBar].value;old=b[\nextBar].value;
            assert.value(frame.events.select {|e|[0,3].includes(e.lane)}.sort {|x,y|x.seed<y.seed}
                ==old.events.select {|e|[0,3].includes(e.lane)}.sort {|x,y|x.seed<y.seed},
                "Player changed bass/drum notes, seeds, timing or velocities");
            frame.decks.do {|plan|if(plan.notNil){
                var p=plan.rockPlayer,signature=p.asCompileString;
                assert.value(p.id==id and:{p.name==~djRockPlayers[id].name},"Wrong guitarist for ensemble");
                if(signatures[plan.serial].isNil){signatures[plan.serial]=signature};
                assert.value(signatures[plan.serial]==signature,"Guitarist changed during song");
                names.add(p.name);records[[id,plan.serial]]=true;
            }};
            frame.events.do {|e|
                if([\rockPhysicalGuitar,\rockHumbuckerGuitar,\rockSingleCoilDecay,\rockHumbuckerDecay].includes(e.voice)){
                    var plan=frame.decks[e.deck],p=plan.rockPlayer;
                    assert.value((e.pickPosition-p.pick).abs<=(p.pickSpread+1e-9),"Picking hand left character range");
                    assert.value((e.vibratoRate-p.rate).abs<=(p.rateSpread+1e-9),"Vibrato speed left character range");
                    if(e.bendSemis>0){assert.value(e.bendSemis==if(e[\rockArrivalBend] ? false){1}{p.bendSemis},"Bend size changed character")};
                    assert.value(e.vibrato<=(p.vibrato+p.vibratoSpread+1e-9),"Vibrato depth left character range");
                    assert.value(e.beat.inclusivelyBetween(0,3.95) and:{e.duration>0},"Invalid player event");
                    assert.value((e.midinote-[40,45,50,55,59,64][e.stringIndex]).inclusivelyBetween(0,22),"Unplayable string");
                    if(e[\rockLanding] ? false){
                        var degree=plan.schedule[plan.localBar].degree,pc=(e.midinote-plan.key)%12;
                        assert.value([0,2,4].collect {|offset|plan.scale.wrapAt(degree+offset)}.includes(pc),"Player lost chord ending");
                        assert.value(e.bendMode!=1,"Player bend overshoots landing");landings=landings+1;
                    };notes=notes+1;
                };
            };
            frame.automation.do {|point|point.fx.do {|fx,deck|
                var plan=frame.decks[deck];
                if(plan.notNil){var p=plan.rockPlayer;
                    assert.value(fx.guitarPedal==p.pedal and:{fx.guitarComp==p.comp}
                        and:{fx.guitarChorus==p.chorusFX} and:{fx.guitarFuzz==p.fuzz},"Guitar rig changed identity");
                    assert.value(fx.guitarDrive.inclusivelyBetween(p.driveMin,p.driveMax),"Gain left character range");
                };
            }};count=count+1;
        };
    }}};
    // Repetition/answers: a full groove phrase has seven identical primary
    // rhythms and one permitted answer; Hold suppresses that answer.
    [false,true].do {|held|3.do {|id|
        var engine=~makeDJEngine.value(2600,102,(channel:\rock,palette:id,hold:held,mutation:1)),seen=0;
        8.do {
            var f=engine[\nextBar].value,p=f.decks[0],part=p.sections.detect {|x|p.localBar<(x.start+x.bars)};
            var answer=(p.localBar-part.start)%8==7 and:{held.not};
            var actual=f.events.select {|e|e.deck==0 and:{e.role==\rockChord}}.collect(_.step).asSet;
            var expected=p.rockPlayer.rhythm[if(answer){1}{0}].asSet;
            assert.value(actual==expected,"Groove drifted beyond primary/phrase answer vocabulary");seen=seen+1;
        };
        assert.value(seen==8,"Missing groove phrase");
    }};
    ~djRecipeDir=Platform.defaultTempDir+/+"dj-player-recall-check";
    {
        var session=~makeDJSession.value(2600,102,(channel:\rock)),spec,replay,frames=List.new;
        72.do {|bar|var f;
            if(bar==16){session[\requestHook].value};if(bar==32){session.controls.tension=0.9};
            if(bar==40){session[\requestNext].value};f=session[\nextBar].value;
            if(bar==40){spec=~djReadRecipe.value(f.decks[1].trackName)};
            if(bar>=40){frames.add([f.events.deepCopy,f.automation.deepCopy,f.decks.collect {|p|if(p.isNil){nil}{p.rockPlayer.deepCopy}}])};
        };
        assert.value(spec[0]==8 and:{spec.size==16} and:{spec[15]==1},"Recipe lost player policy");
        replay=~djSessionFromRecipe.value(spec);replay.persistRecipes=false;
        frames.do {|expected|var f=replay[\nextBar].value;
            assert.value([f.events,f.automation,f.decks.collect {|p|if(p.isNil){nil}{p.rockPlayer}}]==expected,"Player/handover recall changed");
        };
    }.value;
    // Recall only accepts the current schema (8) and source fingerprint; older names are rejected (channels-check).
    {
        var p=~makeDJEngine.value(2600,102,(channel:\rock)).controls;
        assert.value(p.rockPlayerVersion==1,"New Rock set lacks players");
        [\edme,\pop].do {|channel|var f=~makeDJEngine.value(2600,128,(channel:channel))[\nextBar].value;
            assert.value(f.decks[0][\rockPlayer].isNil,"Guitarist reached EDM/Pop")};
    }.value;
    ("PASS: "++count++" player bars / "++notes++" guitar notes / "++landings++" chord landings; three stable characters, bounded choices, recurring rhythms, bass/drums unchanged and exact handover recall").postln;
    0.exit;
} {|e|e.reportError;1.exit};
)
