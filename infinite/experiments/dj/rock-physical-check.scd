// Pure score/recall contracts for the physical guitar, plus saved-tone regression.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var bars=0,gestures=(slide:0,bend:0,vibrato:0),pedals=Set.new;
    var expression=[\stringIndex,\fromNote,\slideBeats,\bendSemis,\bendMode,\vibrato,\vibratoRate,\pickPosition,\articulation];
    var fxKeys=[\guitarComp,\guitarChorus,\guitarPedal,\guitarDrive,\guitarTone,\guitarFuzz];
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;(root+/+"recall.scd").load;
    [\original,\aeolian,\ionian,\dorian,\phrygian,\mixolydian,\lydian].do {|mode|[\full,\pentatonic].do {|melody|
        var a=~makeDJEngine.value(2600,102,(channel:\rock,tonality:mode,melody:melody,rockPlayerVersion:0,rockToneVersion:3));
        var b=~makeDJEngine.value(2600,102,(channel:\rock,tonality:mode,melody:melody,rockToneVersion:0));
        128.do {
            var f=a[\nextBar].value,g=b[\nextBar].value,plain,automation;
            plain=f.events.collect {|event|var e=event.copy;
                if([\rockPhysicalGuitar,\rockHumbuckerGuitar].includes(e.voice)){
                    var open=[40,45,50,55,59,64][e.stringIndex];
                    assert.value((e.midinote-open).inclusivelyBetween(0,22),"Unplayable fret/string assignment");
                    assert.value(e.slideBeats.inclusivelyBetween(0,0.18),"Unbounded slide");
                    if(e.slideBeats>0){gestures.slide=gestures.slide+1;
                        assert.value((e.fromNote-open).inclusivelyBetween(0,22) and:{e.articulation==1},"Slide changes strings or re-picks")};
                    if(e.bendMode>0){gestures.bend=gestures.bend+1;assert.value(e.role==\djHook,"Chord received a solo bend")};
                    if(e.vibrato>0){gestures.vibrato=gestures.vibrato+1;assert.value(e.duration>=0.75,"Short note received vibrato")};
                    if(e[\rockLanding] ? false){assert.value(e.bendMode!=1,"Landing overshoots its chord tone")};
                    expression.do {|key|e.removeAt(key)};e.voice=\rockGuitar;
                }{assert.value(expression.every {|key|e[key].isNil},"String controls reached another instrument")};e;
            };
            assert.value(plain.asArray==g.events.asArray,"Physical playing changed written notes, drums, bass or timing");
            automation=f.automation.collect {|p|var copy=p.copy;copy.fx=p.fx.collect {|fx|var x=fx.copy;
                if(x[\guitarPedal].notNil){pedals.add(x.guitarPedal)};fxKeys.do {|key|x.removeAt(key)};x};copy};
            assert.value(automation==g.automation,"Rig changed transport automation");bars=bars+1;
        };
    }};
    gestures.values.do {|n|assert.value(n>10,"Missing technique")};assert.value(pedals==Set[0,1,2,3],"Missing rig topology");
    ~djRecipeDir=Platform.defaultTempDir+/+"dj-rock-physical-recipes";
    [1,2,3,4,5,6].do {|tone|
        var session=~makeDJSession.value(2600,102,(channel:\rock,hold:true,rockToneVersion:tone)),spec,expected=List.new,replay;
        40.do {|i|var f=session[\nextBar].value;if(i==0){spec=~djReadRecipe.value(f.decks[0].trackName)};
            expected.add([f.events.deepCopy,f.automation.deepCopy])};
        assert.value(spec[14]==tone,"Saved tone version changed");
        replay=~djSessionFromRecipe.value(spec);replay.persistRecipes=false;
        expected.do {|old|var f=replay[\nextBar].value;assert.value([f.events,f.automation]==old,"Recall differs")};
    };
    {
        var spec=[6,2074328684,2600,102,3,[0.25,0.55,0.3,1.0,0,0,-1],0,0,[],0,"original","full","fixed",1,1];
        var name=~djRecipeName.value(spec),replay,reference;
        File.use(~djRecipeDir+/+(name++".json"),"w",{|file|file.write(spec.asCompileString)});
        replay=~djSessionFromRecipe.value(~djReadRecipe.value(name));replay.persistRecipes=false;
        reference=~makeDJEngine.value(2600,102,(channel:\rock,tension:1,rockToneVersion:1,rockLeadVersion:1));
        64.do {var a=replay[\nextBar].value,b=reference[\nextBar].value;
            assert.value(a.events==b.events and:{a.automation==b.automation},"Previous source recipe changed its sound")};
    }.value;
    assert.value(~djMixSpec.value(\rock,1).deck==\rockGuitarDeck and:{~djMixSpec.value(\rock,2).deck==\rockPhysicalDeck},"Recall routed to wrong guitar rig");
    ~djDefs.do {|d|assert.value(d.asBytes.size<65000,"SynthDef exceeds a portable OSC packet: "++d.name)};
    ("PASS: "++bars++" physical Rock bars; "++gestures.asCompileString++"; playable strings, unchanged score/rhythm section, rig isolation and tone 1–6 recall").postln;
    0.exit;
} {|e|e.reportError;1.exit};
)
