// Record names index portable JSON recipes, not recordings or executable code.
// Only live sessions save recipes. The composition engine stays pure.
(
var root=thisProcess.nowExecutingPath.dirname;
var keys=[\chaos,\density,\mutation,\tension,\hold,\autoStutter,\palette];
var methods=[\requestNext,\requestHook,\requestFill,\requestMutation,\requestFX,\startFX,\stopFX];
var hash={ |text,start=1| var n=start; text.do { |c| n=((n*131)+c.ascii)%2147483647 }; n };
var fingerprint;
~djRecipeDir=~djRecipeDir ? (root +/+ "saved-tracks");
fingerprint=hash.value(["engine.scd","style.scd","pop-style.scd","library.scd",
    "instruments.scd","palette-instruments.scd","pop-instruments.scd","recall.scd",
    "e-style.scd","e-instruments.scd"]
    .collect { |file| File.readAllString(root +/+ file) }.join("\n"));
~djRecallVector={ |controls|
    keys.collect { |key,i|
        case {i<4} {(controls[key] ? [0.25,0.55,0.30,0.20][i]).asFloat}
            {i<6} {if(controls[key] ? (i==5)) {1} {0}}
            {true} {controls[key] ? -1};
    };
};
~djRecallSettings={ |vector,channel=\edme|
    var settings=(channel:channel);
    keys.do { |key,i|
        if(i<6 or: {vector[i]>=0}) {
            settings[key]=if(i<4) {vector[i].asFloat} {if(i<6) {vector[i]==1} {vector[i].asInteger}};
        };
    };
    settings;
};
~djParseRecipe={ |text|
    var convert;
    // SC 3.13's JSON reader returns strings for every scalar. Normalize
    // numeric fields without evaluating any of the file as SuperCollider code.
    convert={ |value|
        if(value.isKindOf(Array)) {value.collect(convert)} {
            if(value.isString and: {"^-?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$".matchRegexp(value)}) {
                value.asFloat
            } {value};
        };
    };
    convert.value(text.parseJSON);
};
~djRecipeName={ |spec|
    var canonical=~djParseRecipe.value(spec.keep(9).asCompileString).asCompileString
        ++ ":" ++ (spec.at(9) ? 0).asInteger;
    var a=hash.value(canonical),b=hash.value(canonical,65537);
    var adjectives=["Amber","Velvet","Cobalt","Silver","Copper","Neon","Hidden","Midnight",
        "Electric","Distant","Crimson","Golden","Quiet","Liquid","Wild","Lunar",
        "Violet","Solar","Crystal","Faded","Scarlet","Northern","Secret","Ocean",
        "Radiant","Slow","Indigo","Satin","Phantom","Scarce","Open","Deep"];
    var nouns=["Orbit","Circuit","Horizon","Current","Mirage","Signal","Avenue","Motion",
        "Satellite","Echo","Skyline","Tide","Arcade","Pulse","Drift","Afterglow",
        "Dawn","Rain","Harbor","Sky","River","Static","Sunset","Road",
        "Garden","Shadow","Memory","Voyage","Air","Summer","Rhythm","Bloom"];
    adjectives[a%32] ++ " " ++ nouns[(a div:32)%32] ++ " at " ++
        adjectives[b%32] ++ " " ++ nouns[(b div:32)%32];
};
~makeDJSession={ |seed=2600,bpm=128,settings,persist=true|
    var base=~makeDJEngine.value(seed,bpm,settings),session=base.copy;
    var journal=List.new,bar=0,names=Dictionary.new,initial=~djRecallVector.value(base.controls);
    var last=initial.copy,next=base[\nextBar];
    session.persistRecipes=persist;
    session.recallJournal=journal;
    session.recallNames=names;
    methods.do { |key,i|
        var original=base[key];
        session[key]={ |a,b|
            journal.add([bar,i+1,if(a.isKindOf(Symbol)) {a.asString} {a ? 0},b ? 0]);
            original.value(a,b);
        };
    };
    session[\nextBar]={
        var vector=~djRecallVector.value(session.controls),frame;
        if(vector!=last) {journal.add([bar,0,vector]);last=vector.copy};
        frame=next.value;
        frame.decks.do { |plan|
            if(plan.notNil) {
                if(names[plan.serial].isNil) {
                    var spec=[2,fingerprint,seed,bpm,[\edm,\pop,\edme].indexOf(base.channel),
                        initial,plan.serial,bar,journal.asArray.deepCopy,0];
                    var name=~djRecipeName.value(spec),path;
                    path=~djRecipeDir +/+ (name ++ ".json");
                    while {File.exists(path) and: {~djParseRecipe.value(File.readAllString(path))!=spec}} {
                        spec[9]=spec[9]+1;
                        if(spec[9]>1024) {Error("Track name library is full").throw};
                        name=~djRecipeName.value(spec);path=~djRecipeDir +/+ (name ++ ".json");
                    };
                    names[plan.serial]=name;
                    if(session.persistRecipes) {
                        ~djRecipeDir.mkdir;
                        if(File.exists(path)) {
                            if(~djParseRecipe.value(File.readAllString(path))!=spec) {Error("Track recipe name collision").throw};
                        } {
                            File.use(path,"w",{ |file| file.write(spec.asCompileString ++ "\n") });
                        };
                    };
                };
                plan.trackName=names[plan.serial];
            };
        };
        bar=bar+1;frame;
    };
    session;
};
~djReadRecipe={ |name|
    var spec;
    name=name.stripWhiteSpace;
    if("^[A-Za-z]+ [A-Za-z]+ at [A-Za-z]+ [A-Za-z]+$".matchRegexp(name).not) {Error("Paste the complete track name").throw};
    if(File.exists(~djRecipeDir +/+ (name ++ ".json")).not) {Error("Track is not in this local recipe library").throw};
    spec=~djParseRecipe.value(File.readAllString(~djRecipeDir +/+ (name ++ ".json")));
    if(spec.size!=10 or: {spec[0]!=2} or: {[fingerprint,1646806499].includes(spec[1].asInteger).not}) {
        Error("This recipe needs the music source version that created it").throw;
    };
    if(~djRecipeName.value(spec)!=name) {Error("Track recipe checksum mismatch").throw};
    spec;
};
~djSessionFromRecipe={ |spec|
    var channel=[\edm,\pop,\edme].at(spec[4].asInteger);
    var session=~makeDJSession.value(spec[2].asInteger,spec[3].asFloat,
        ~djRecallSettings.value(spec[5],channel),false);
    var commands=spec[8],cursor=0;
    session.recallNames[spec[6].asInteger]=~djRecipeName.value(spec);
    (spec[7].asInteger+1).do { |bar|
        while {cursor<commands.size and: {commands[cursor][0]==bar}} {
            var command=commands[cursor],code=command[1].asInteger,argument;
            if(code==0) {
                keys.do { |key| session.controls.removeAt(key) };
                ~djRecallSettings.value(command[2],channel).keysValuesDo { |key,value| session.controls[key]=value };
            } {
                if(code<1 or: {code>methods.size}) {Error("Invalid recipe action").throw};
                argument=if([5,6].includes(code)) {command[2].asSymbol} {command[2]};
                session[methods[code-1]].value(argument,command[3]);
            };
            cursor=cursor+1;
        };
        if(bar<spec[7]) {session[\nextBar].value};
    };
    session.persistRecipes=true;
    session;
};
)
