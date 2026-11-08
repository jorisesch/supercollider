// Current channel aliases, freshly seeded launch paths and fixed-mode flags.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var captured,seeds=Set.new;
    (root+/+"engine.scd").load;(root+/+"recall.scd").load;
    [\edm,\edme,\classic].do {|alias|
        var a=~makeDJEngine.value(2600,128,(channel:alias)),b=~makeDJEngine.value(2600);
        32.do {var f=a[\nextBar].value,g=b[\nextBar].value;
            assert.value(a.channel==\edme and:{f.events==g.events} and:{f.automation==g.automation},"An EDM alias selected a different grammar");
        };
    };
    ~djRecipeDir=Platform.defaultTempDir+/+"dj-current-channel-recipes";~djRecipeDir.mkdir;
    {
        var spec=[7,1995479297,2600,128,2,[0.25,0.55,0.3,0.2,0,1,-1],0,0,[],0,"original","full","tension",0,0,0];
        var name=~djRecipeName.value(spec),rejected=false;
        File.use(~djRecipeDir+/+(name++".json"),"w",{|file|file.write(spec.asCompileString)});
        try {~djReadRecipe.value(name)} {|error|rejected=true};
        assert.value(rejected,"An older name was replayed with a different generator");
    }.value;
    (root+/+"launch.scd").load;
    ~djStart={|seed,bpm,server|captured=(seed:seed,bpm:bpm,settings:~djSettings.copy)};
    ["edm","edme","classic","pop","rock"].do {|name|
        ~djRun.value([name,"mode=harmonicMinor","melody=pentatonic","nogui"]);
        assert.value(captured.seed>0 and:{captured.seed<=2147483646},"Invalid generated seed");
        seeds.add(captured.seed);
        assert.value(captured.bpm==~djDefaultBpm.value(name.asSymbol),"Wrong channel tempo");
        assert.value(captured.settings.channel==~djResolveChannel.value(name.asSymbol),"Wrong CLI channel");
        assert.value(captured.settings.tonality==\harmonicMinor and:{captured.settings.melody==\pentatonic}
            and:{captured.settings.modalPolicy==\fixed},"CLI lost a pinned mode");
    };
    assert.value(seeds.size==5,"Normal launches reused their seed");
    ~djRun.value(["rock","731","96","0.1","0.6","0.2","0.3","nogui"]);
    assert.value(captured.seed==731 and:{captured.bpm==96} and:{captured.settings.density==0.6},"Explicit rehearsal options broke");
    "PASS: channel aliases, new seed per launch, fixed new modes, numeric options and clean rejection of older names".postln;
    0.exit;
} {|error|error.reportError;1.exit};
)
