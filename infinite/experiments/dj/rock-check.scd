// Rock grammar, mode membership, variation, effects and exact saved-track recall.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var defs,count=0,records=Set.new,palettes=Set.new,effects=Set.new,kickShapes=Set.new,progressions=Set.new;
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
                    f.decks.do {|plan|if(plan.notNil){records.add(plan.serial);palettes.add(plan.palette.id);progressions.add(plan.currentProgression)}};
                    kickShapes.add(f.events.select {|e|e.role==\djKick and:{e.deck==0}}.collect(_.step));
                    f.events.do {|e|
                        var plan=f.decks[e.deck],pc=(e.midinote-plan.key)%12;
                        assert.value(e.beat>=last and:{e.beat<4},"Rock event timing invalid");last=e.beat;
                        assert.value(defs.includes(e.voice),"Missing Rock definition");
                        assert.value(e.amp>0 and:{e.amp<0.65} and:{e.duration>0} and:{e.duration<5},"Rock event bounds invalid");
                        if(e.lane<3){assert.value(plan.scale.includes(pc),"Rock note left its mode")};
                        if(e.role==\djHook and:{melody==\pentatonic}){
                            assert.value(plan.melodyPalette.includes(pc),"Rock lead left pentatonic palette");
                        };
                        [\fuzz,\wah,\slap].do {|key|
                            if(e[key]>0){effects.add(key);assert.value([\rockGuitar,\rockExpressiveGuitar,\rockPhysicalGuitar].includes(e.voice),"Guitar effect leaked into the kit")};
                        };
                    };
                    count=count+1;
                };
            };
        };
    };
    assert.value(records.size>=3 and:{palettes.size==3} and:{progressions.size>8},"Rock variety is missing");
    assert.value(kickShapes.size>3 and:{effects==Set[\fuzz,\wah,\slap]},"Rock rhythms or selective effects are missing");
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
