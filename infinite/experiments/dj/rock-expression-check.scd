// Written pitches/cadences and rhythm section remain intact underneath gestures.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var count=0,gestures=(slide:0,bend:0,vibrato:0),pedals=Set.new;
    var expressionKeys=[\fromNote,\slideBeats,\bendSemis,\bendMode,\vibrato,\vibratoRate,\pick,\pedal,\pedalGain];
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;(root+/+"recall.scd").load;
    [\original,\aeolian,\ionian,\dorian,\phrygian,\mixolydian,\lydian].do {|mode|
        [\full,\pentatonic].do {|melody|
            var a=~makeDJEngine.value(2600,102,(channel:\rock,tonality:mode,melody:melody,rockToneVersion:1));
            var b=~makeDJEngine.value(2600,102,(channel:\rock,tonality:mode,melody:melody,rockToneVersion:0));
            256.do {
                var f=a[\nextBar].value,g=b[\nextBar].value,plain,automation;
                plain=f.events.collect {|event|
                    var e=event.copy;
                    if(e.voice==\rockExpressiveGuitar){
                        var plan=f.decks[e.deck],pc=(e.midinote-plan.key)%12;
                        pedals.add(e.pedal);
                        assert.value(e.pedalGain.inclusivelyBetween(0,0.8),"Guitar gain out of bounds");
                        assert.value(e.slideBeats.inclusivelyBetween(0,0.18),"Slide out of bounds");
                        assert.value(e.bendSemis.inclusivelyBetween(0,2),"Bend out of bounds");
                        assert.value(e.vibrato.inclusivelyBetween(0,0.25),"Vibrato out of bounds");
                        if(e.slideBeats>0){
                            gestures.slide=gestures.slide+1;
                            assert.value((e.fromNote-e.midinote).abs<=5,"Slide crosses too large an interval");
                            assert.value(e.role==\djHook,"Rhythm chord was given a lead slide");
                        };
                        if(e.bendMode>0){gestures.bend=gestures.bend+1;assert.value(e.role==\djHook,"Rhythm chord was bent")};
                        if(e.vibrato>0){gestures.vibrato=gestures.vibrato+1;assert.value(e.role==\djHook,"Rhythm chord has solo vibrato")};
                        if(e[\rockLanding] ? false){
                            var degree=plan.schedule[plan.localBar].degree,tones=[0,2,4].collect {|n|plan.scale.wrapAt(degree+n)};
                            assert.value(tones.includes(pc),"Expression changed the landing target");
                            assert.value(e.bendMode!=1,"A landing bend overshoots its chord tone");
                            if(melody==\pentatonic){assert.value(plan.melodyPalette.includes(pc),"Pentatonic landing was lost")};
                        };
                        expressionKeys.do {|key|e.removeAt(key)};e.voice=\rockGuitar;
                    }{
                        assert.value(expressionKeys.every {|key|e[key].isNil},"Guitar controls leaked onto bass/drums");
                    };
                    e;
                };
                assert.value(plain.asArray==g.events.asArray,"Expression changed written notes, accompaniment, timing or velocities");
                automation=f.automation.collect {|point|
                    var p=point.copy;p.fx=point.fx.collect {|fx|var x=fx.copy;x.removeAt(\guitarComp);x.removeAt(\guitarChorus);x};p;
                };
                assert.value(automation==g.automation,"Guitar strip changed existing deck automation");count=count+1;
            };
        };
    };
    assert.value(pedals==Set[0,1,2,3],"A pedal color is missing");
    gestures.keysValuesDo {|key,value|assert.value(value>10,"Missing guitar gesture: "++key)};
    ~djRecipeDir=Platform.defaultTempDir+/+"dj-expression-recall";
    {
        var session=~makeDJSession.value(2600,102,(channel:\rock,hold:true,rockToneVersion:1)),spec,replay,expected=List.new;
        48.do {|bar|var f=session[\nextBar].value;
            if(bar==0){spec=~djReadRecipe.value(f.decks[0].trackName)};
            expected.add([f.events.deepCopy,f.automation.deepCopy]);
        };
        assert.value(spec.size==16 and:{spec[0]==7} and:{spec[14]==1},"Recipe lost the guitar tone version");
        replay=~djSessionFromRecipe.value(spec);replay.persistRecipes=false;
        expected.do {|old|var f=replay[\nextBar].value;assert.value([f.events,f.automation]==old,"Guitar gestures/strip differ on recall")};
    }.value;
    {
        var spec=[5,2133735198,2600,128,3,[0.25,0.55,0.3,1.0,0,0,-1],0,0,[],0,"original","full","fixed",1];
        var name=~djRecipeName.value(spec),replay,reference;
        File.use(~djRecipeDir+/+(name++".json"),"w",{|file|file.write(spec.asCompileString)});
        replay=~djSessionFromRecipe.value(~djReadRecipe.value(name));replay.persistRecipes=false;
        reference=~makeDJEngine.value(2600,128,(channel:\rock,tension:1,rockToneVersion:0,rockLeadVersion:1));
        assert.value(replay.controls.rockToneVersion==0,"Older solo recipe acquired new guitar processing");
        128.do {var a=replay[\nextBar].value,b=reference[\nextBar].value;
            assert.value(a.events==b.events and:{a.automation==b.automation},"Previous Rock solo/tone changed on replay");
        };
        assert.value(~djMixSpec.value(\rock,0).deck==\rockDeck,"Older recipe lost its original guitar strip");
    }.value;
    ("PASS: "++count++" expressive Rock bars; "++gestures.asCompileString++"; all pedal colors; unchanged written notes/bass/drums, chord-tone landings, bounded controls and exact recall").postln;
    0.exit;
} {|e|e.reportError;1.exit};
)
