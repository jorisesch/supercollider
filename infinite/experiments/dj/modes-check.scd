// Optional modes, pentatonic melody and exact recipe recall. No audio/server.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var count=0,seen=Set.new;
    (root+/+"engine.scd").load;(root+/+"recall.scd").load;
    ["controls.scd","live.scd","launch.scd"].do {|file|
        assert.value(File.readAllString(root+/+file).compile.notNil,"Mode control parse failed");
    };
    [\edme,\pop].do {|channel|
        [\aeolian,\ionian,\dorian,\phrygian,\mixolydian,\lydian].do {|mode|
            [\full,\pentatonic].do {|melody|
                var a=~makeDJEngine.value(2600,128,(channel:channel,modalPolicy:\fixed,tonality:mode,melody:melody));
                var b=~makeDJEngine.value(2600,128,(channel:channel,modalPolicy:\fixed,tonality:mode,melody:melody));
                128.do {
                    var f=a[\nextBar].value,g=b[\nextBar].value;
                    assert.value(f.events==g.events and:{f.automation==g.automation},"Mode is not reproducible");
                    f.events.do {|event|
                        var plan=f.decks[event.deck],pc=(event.midinote-plan.key)%12;
                        if(event.lane<3 and:{event.role!=\eTurnaround}){
                            assert.value(plan.scale.includes(pc),"Pitched note outside selected mode");
                            seen.add([mode,pc]);
                        };
                        if(melody==\pentatonic and:{[\djHook,\djArp,\eSignature].includes(event.role)}){
                            assert.value(plan.melodyPalette.includes(pc),"Lead left its five-note palette");
                        };
                    };
                    count=count+1;
                };
            };
        };
    };
    [[\dorian,9],[\phrygian,1],[\mixolydian,10]].do {|pair|
        assert.value(seen.includes(pair),"Characteristic modal note never sounds");
    };
    ~djRecipeDir=Platform.defaultTempDir+/+"dj-modal-test-recipes";
    [\edme,\pop].do {|channel|
        var session=~makeDJSession.value(7429,128,(channel:channel,modalPolicy:\fixed,tonality:\dorian,melody:\pentatonic));
        var first=session[\nextBar].value,name=first.decks[0].trackName,spec=~djReadRecipe.value(name),replay;
        var expected=List.new;
        assert.value(spec.size==15 and:{spec[0]==6},"Modal recipe does not store its choices");
        expected.add([first.events,first.automation]);
        15.do {var f=session[\nextBar].value;expected.add([f.events,f.automation])};
        replay=~djSessionFromRecipe.value(spec);replay.persistRecipes=false;
        expected.do {|old|var f=replay[\nextBar].value;assert.value([f.events,f.automation]==old,"Modal recall changed the music")};
    };
    // Pre-mode recipes have ten fields and retain the original harmony/palette.
    [\legacy,\pop,\edme].do {|channel,index|
        var spec=[2,2112806582,2600,128,index,[0.25,0.55,0.3,0.2,0,1,-1],0,0,[],0];
        var name=~djRecipeName.value(spec),path=~djRecipeDir+/+(name++".json");
        var replay,reference;
        File.use(path,"w",{|file|file.write(spec.asCompileString)});
        spec=~djReadRecipe.value(name);replay=~djSessionFromRecipe.value(spec);replay.persistRecipes=false;
        reference=~makeDJEngine.value(2600,128,(channel:channel,modalPolicy:\fixed));
        16.do {var a=replay[\nextBar].value,b=reference[\nextBar].value;
            assert.value(a.events==b.events and:{a.automation==b.automation},"Legacy recipe changed its music");
        };
    };
    ("PASS: "++count++" modal bars across EDM/Pop, six modes and both melody palettes; modal color notes and exact recall").postln;
    0.exit;
} {|error|error.reportError;1.exit};
)
