// Rock grammar, mode membership, variation, effects and exact saved-track recall.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var defs,count=0,pickups=Set.new,records=Set.new,palettes=Set.new,effects=Set.new,kickShapes=Set.new,progressions=Set.new;
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;(root+/+"recall.scd").load;
    defs=~djDefs.collect(_.name);
    assert.value(~djChannelNames==["EDM","Pop","Rock"],"Channel menu must have one EDM");
    [\original,\aeolian,\ionian,\dorian,\phrygian,\mixolydian].do {|mode|
        3.do {|palette|
            [\full,\pentatonic].do {|melody|
                var settings=(channel:\rock,palette:palette,tonality:mode,melody:melody);
                var a=~makeDJEngine.value(731,102,settings),b=~makeDJEngine.value(731,102,settings);
                128.do {
                    var f=a[\nextBar].value,g=b[\nextBar].value,last=0;
                    assert.value(f.events==g.events and:{f.automation==g.automation},"Rock is not reproducible");
                    assert.value(a.state.bpm.inclusivelyBetween(78,124),"Rock tempo out of range");
                    f.decks.do {|plan|if(plan.notNil){
                        assert.value(f.automation[0].fx[plan.deck].bluesMix==if(plan.schedule[plan.localBar].harmonyRole==\blues){1}{0},"Blues EQ reached the wrong record");
                        assert.value(plan.rockPickup==if(plan.palette.id==1){\singleCoil}{\humbucker},"Rock pickup changed character");
                        assert.value(f.automation[0].fx[plan.deck].humbuckerMix==if(plan.rockPickup==\humbucker){1}{0},"Wrong pickup load for track");
                        pickups.add(plan.rockPickup);
                        records.add(plan.serial);palettes.add(plan.palette.id);progressions.add(plan.currentProgression)}};
                    kickShapes.add(f.events.select {|e|e.role==\djKick and:{e.deck==0}}.collect(_.step));
                    f.events.do {|e|
                        var plan=f.decks[e.deck],pc=(e.midinote-plan.key)%12;
                        assert.value(e.beat>=last and:{e.beat<4},"Rock event timing invalid");last=e.beat;
                        assert.value(defs.includes(e.voice),"Missing Rock definition");
                        assert.value(e.amp>0 and:{e.amp<0.65} and:{e.duration>0} and:{e.duration<5},"Rock event bounds invalid");
                        if(e.lane<3){
                            var chord=plan.schedule[plan.localBar],rootNote=plan.scale[chord.degree];
                            if(e.role==\rockChord and:{chord.harmonyRole==\blues}){
                                assert.value([4,7,10].includes((pc-rootNote)%12),"Blues guitar lost its dominant-seven voicing");

                            }{
                                assert.value(plan.scale.includes(pc),"Rock note left its mode");
                            };
                        };
                        if(e.role==\djHook and:{melody==\pentatonic}){
                            assert.value(plan.melodyPalette.includes(pc),"Rock lead left pentatonic palette");
                        };
                        if([\rockChord,\djHook].includes(e.role)){
                            assert.value(e.voice==if(plan.rockPickup==\humbucker){\rockHumbuckerDecay}{\rockSingleCoilDecay},
                                "Lead and rhythm guitars used different pickups on the same track");
                        };
                        [\fuzz,\wah,\slap].do {|key|
                            if(e[key]>0){effects.add(key);assert.value([\rockGuitar,\rockExpressiveGuitar,\rockSingleCoilDecay,\rockHumbuckerDecay].includes(e.voice),"Guitar effect leaked into the kit")};
                        };
                    };
                    count=count+1;
                };
            };
        };
    };
    assert.value(pickups==Set[\singleCoil,\humbucker],"Both Rock pickups must be represented");
    assert.value(records.size>=3 and:{palettes.size==3} and:{progressions.size>8},"Rock variety is missing");
    assert.value(kickShapes.size>3 and:{effects.includes(\fuzz)},"Rock rhythms or selective effects are missing");
    {
        var engine=~makeDJEngine.value(2601,102,(channel:\rock,hold:true));
        var previous=~makeDJEngine.value(2601,102,(channel:\rock,hold:true,rockToneVersion:3));
        var expected=[0,0,0,0,3,3,0,0,4,3,0,4]++[0,3,0,0,3,3,0,0,4,3,0,4];
        expected.do {|degree|
            var frame=engine[\nextBar].value,plan=frame.decks[0],old=previous[\nextBar].value;
            assert.value(frame.events.size==old.events.size,"New guitar voice changed the blues event count");
            frame.events.do {|e,i|
                var reference=old.events[i],voice=e.voice;
                if(voice==\rockHumbuckerDecay){e=e.copy.put(\voice,\rockHumbuckerGuitar)};
                assert.value(e==reference,"New guitar voice changed the blues performance");
            };
            frame.automation.do {|point,i|
                var before=old.automation[i].gains[0];
                assert.value(point.fx[0].bluesMix==1,"Blues EQ was not routed to the deck");
                assert.value(point.gains[0]==before,"Blues guitar EQ changed the lane levels");
            };
            assert.value(plan.schedule[plan.localBar].harmonyRole==\blues
                and:{plan.schedule[plan.localBar].degree==degree},"Blues chorus lost its turnaround");
        };
    }.value;
    {
        var engine=~makeDJEngine.value(2600,102,(channel:\rock)),differentPickups=false;
        192.do {
            var frame=engine[\nextBar].value;
            if(frame.decks.every(_.notNil) and:{frame.decks[0].rockPickup!=frame.decks[1].rockPickup}){
                var messages=~djAutomation.value(frame.automation[0],[800,801],[810,811]);
                frame.decks.do {|plan,id|
                    assert.value(messages[2+id]==[\n_set,810+id,\bluesMix,
                        frame.automation[0].fx[id].bluesMix,\humbuckerMix,if(plan.rockPickup==\humbucker){1}{0}],
                        "Pickup load did not follow its deck during a handover");
                };
                differentPickups=true;
            };
        };
        assert.value(differentPickups,"Rock did not hand over between pickup types");
    }.value;
    ~djRecipeDir=Platform.defaultTempDir+/+"dj-rock-recall-check";
    {
        var session=~makeDJSession.value(731,102,(channel:\rock,tonality:\dorian,melody:\pentatonic));
        var frame,name,spec,replay,expected=List.new;
        session.controls.density=0.7;session[\requestHook].value;
        frame=session[\nextBar].value;name=frame.decks[0].trackName;spec=~djReadRecipe.value(name);
        assert.value(spec[4]==3 and:{spec[10]=="dorian"},"Rock recipe did not save channel/mode");
        expected.add([frame.events,frame.automation]);
        15.do {var f=session[\nextBar].value;expected.add([f.events,f.automation])};
        replay=~djSessionFromRecipe.value(spec);replay.persistRecipes=false;
        expected.do {|old|var f=replay[\nextBar].value;assert.value([f.events,f.automation]==old,"Rock recall changed the music")};
    }.value;
    ("PASS: "++count++" reproducible Rock bars, six mode choices, three ensembles, full/pentatonic melody, handovers, selective effects and exact recall").postln;
    0.exit;
} {|error|error.reportError;1.exit};
)
