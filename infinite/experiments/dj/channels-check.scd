// Public channel aliases, CLI options and recipes from before channel consolidation.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var captured;
    (root+/+"engine.scd").load;(root+/+"recall.scd").load;
    [\edm,\edme,\classic].do {|alias|
        var a=~makeDJEngine.value(2600,128,(channel:alias)),b=~makeDJEngine.value;
        64.do {var f=a[\nextBar].value,g=b[\nextBar].value;
            assert.value(a.channel==\edme and:{f.events==g.events} and:{f.automation==g.automation},"An EDM alias selected the losing grammar");
        };
    };
    ~djRecipeDir=Platform.defaultTempDir+/+"dj-consolidation-recipes";~djRecipeDir.mkdir;
    [\legacy,\pop,\edme].do {|channel,index|
        [2,3].do {|schema|
            var spec=[schema,if(schema==2){2112806582}{588589464},2600,128,index,[0.25,0.55,0.3,0.2,0,1,-1],0,0,[],0];
            var name,path,replay,reference;
            if(schema==3){spec=spec++["dorian","pentatonic"]};
            name=~djRecipeName.value(spec);path=~djRecipeDir+/+(name++".json");File.use(path,"w",{|file|file.write(spec.asCompileString)});
            spec=~djReadRecipe.value(name);replay=~djSessionFromRecipe.value(spec);replay.persistRecipes=false;
            reference=~makeDJEngine.value(2600,128,(channel:channel,modalPolicy:\fixed,tonality:if(schema==3){\dorian}{\original},melody:if(schema==3){\pentatonic}{\full}));
            16.do {var a=replay[\nextBar].value,b=reference[\nextBar].value;
                assert.value(a.events==b.events and:{a.automation==b.automation},"Existing recipe changed its music");
            };
        };
    };
    (root+/+"launch.scd").load;
    ~djStart={|seed,bpm,server|captured=(seed:seed,bpm:bpm,settings:~djSettings.copy)};
    ["edm","edme","classic","pop","rock"].do {|name|
        ~djRun.value([name,"mode=dorian","melody=pentatonic","nogui"]);
        assert.value(captured.seed==2600,"Flag was parsed as a numeric seed");
        assert.value(captured.bpm==~djDefaultBpm.value(name.asSymbol),"Wrong channel tempo");
        assert.value(captured.settings.channel==~djResolveChannel.value(name.asSymbol),"Wrong CLI channel");
        assert.value(captured.settings.tonality==\dorian and:{captured.settings.melody==\pentatonic},"CLI lost musical overlay");
    };
    ~djRun.value(["rock","731","96","0.1","0.6","0.2","0.3","nogui"]);
    assert.value(captured.seed==731 and:{captured.bpm==96} and:{captured.settings.density==0.6},"Numeric Rock options broke");
    "PASS: EDM aliases select the winner; prior default/modal recipes preserved; all launch channels, mode flags and numeric options".postln;
    0.exit;
} {|error|error.reportError;1.exit};
)
