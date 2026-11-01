// Pure musical regression, indefinite FX and recipe recall checks. No server/audio.
(
var root=thisProcess.nowExecutingPath.dirname,assert={ |ok,message| if(ok.not) {Error(message).throw} };
try {
    var reference=List.new,engine,session,replayed,name,spec,frame,expected=List.new,recipeDir;
    (root +/+ "revisions/v6c/engine.scd").load;
    engine=~makeDJEngine.value(2600,128);
    256.do {var f=engine[\nextBar].value;reference.add([f.events.asCompileString,f.automation.asCompileString])};
    (root +/+ "engine.scd").load;(root +/+ "recall.scd").load;
    engine=~makeDJEngine.value(2600,128,(channel:\edm));
    reference.do { |old|var f=engine[\nextBar].value;
        assert.value([f.events.asCompileString,f.automation.asCompileString]==old,"EDM Classic groove changed")};
    engine=~makeDJEngine.value(2600,128,(hold:true));
    [\filter,\echo,\wash,\stutter4,\stutter8,\stutter16].do { |kind|
        engine[\startFX].value(kind);
        8.do { |bar|
            var f=engine[\nextBar].value,manual=engine.state.manualFX;
            assert.value(manual.kind==kind and: {manual.age==bar},"Effect ended before Stop FX");
            assert.value(f.stutter.isNil,"Automatic FX interfered with manual effect");
            assert.value(f.automation.every { |point| point.fx[manual.deck][\manualKind]==kind },"Manual effect missing");
            if(kind.asString.beginsWith("stutter")) {
                assert.value(f.automation.count { |point| point.fx[manual.deck].stutterReset }==if(bar==0){1}{0},
                    "Held stutter reset mid-phrase");
            };
        };
        engine[\stopFX].value;
        assert.value(engine[\nextBar].value.automation.every { |point|
            point.fx.every { |fx| fx[\manualKind].isNil }
        },"Stop FX did not release");
    };
    // Recall after earlier macro moves, forced transitions and manual performance.
    recipeDir=Platform.defaultTempDir +/+ "dj-recipe-check";~djRecipeDir=recipeDir;
    [\edm,\pop,\edme].do { |channel|
        session=~makeDJSession.value(7429,128,(channel:channel));
        36.do { |bar|
            if(bar==3) {session.controls.density=0.81};
            if(bar==5) {session[\requestFill].value};
            if(bar==8) {session[\startFX].value(\echo)};
            if(bar==11) {session[\stopFX].value};
            if(bar==15) {session[\requestMutation].value};
            if(bar==20) {session[\requestNext].value};
            frame=session[\nextBar].value;
            if(bar==20) {
                name=frame.decks[1].trackName;spec=~djReadRecipe.value(name);
                expected=List.new;
            };
            if(bar>=20) {expected.add([frame.events.deepCopy,frame.automation.deepCopy])};
        };
        replayed=~djSessionFromRecipe.value(spec);
        expected.do { |old,index|
            var f=replayed[\nextBar].value;
            assert.value([f.events,f.automation]==old,"Recall differs from the original bars");
            if(index==0) {assert.value(f.decks[1].trackName==name,"Recall changed the name")};
        };
    };
    "PASS: favourite EDM events/automation unchanged; all six effects persist eight bars then release; EDM, Pop and EDM E names restore exact entry and following bars after macro/action history. No audio.".postln;
    0.exit;
} { |error|error.reportError;1.exit};
)
