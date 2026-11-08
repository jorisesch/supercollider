// Local listening feedback, one verified JSON event per click.
(
var root=thisProcess.nowExecutingPath.dirname;
~djFeedbackDir=~djFeedbackDir ? (root+/+"feedback");
if(~djFeedbackRunID.isNil) {
    ~djFeedbackRunID=Date.gmtime.asSortableString++"-"++~djFreshSeed.value;
};
~djFeedbackCounter=~djFeedbackCounter ? 0;
~djRatings=Dictionary.new;
~djJSON={|value|
    case
    {value.isNil}{"null"}
    {value==true}{"true"}
    {value==false}{"false"}
    {value.isNumber}{if(value.isNaN or:{value.abs==inf}){"null"}{value.asString}}
    {value.isString or:{value.isKindOf(Symbol)}}{
        var escaped=String.streamContents {|stream|
            value.asString.do {|char|
                case
                {char==$"}{stream<<"\\\""}
                {char==$\\}{stream<<"\\\\"}
                {char.ascii<32}{stream<<"\\u"<<char.ascii.asHexString(4)}
                {true}{stream<<char};
            };
        };
        "\""++escaped++"\""
    }
    {value.isKindOf(Dictionary)}{
        "{"++value.keys.asArray.sort {|a,b|a.asString<b.asString}.collect {|key|
            ~djJSON.value(key.asString)++":"++~djJSON.value(value[key])
        }.join(",")++"}"
    }
    {value.isSequenceableCollection}{"["++value.collect {|item|~djJSON.value(item)}.join(",")++"]"}
    {true}{Error("Unsupported listening feedback value").throw};
};
~djLoadRatings={
    var latest=Dictionary.new;
    (~djFeedbackDir+/+"*.json").pathMatch.sort.do {|path|
        try {
            var record=~djParseRecipe.value(File.readAllString(path));
            if(record.schema==1){
                var previous=latest[record.track_id];
                if(previous.isNil or:{record.recorded_at>=previous.recorded_at}){latest[record.track_id]=record};
            };
        } {|error|("DJ feedback skipped unreadable file / "++PathName(path).fileName).postln};
    };
    ~djRatings=latest;
};
~djLoadRatings.value;
~djFeedbackTracks={|engine,frame|
    frame.decks.collect {|plan|
        if(plan.notNil){
            var record=(),snapshot;
            [\serial,\key,\keyName,\mode,\baseTonality,\activeTonality,\scale,
                \progression,\durations,\harmony,\schedule,\formID,\sections,\length,
                \variation,\palette,\edmAnthem,\rockPlayer,\rockPickup].do {|key|
                if(plan[key].notNil){record[key]=plan[key].deepCopy};
            };
            snapshot=(track_id:plan.trackName,seed:engine.seed,channel:engine.channel,
                record:record,section:plan.section,local_bar:plan.localBar,engine_bar:frame.bar,
                recipe:engine.recipeSpecs[plan.serial].deepCopy,
                journal:engine.recallJournal.asArray.deepCopy,controls:engine.controls.deepCopy,
                events:frame.events.select {|event|event.deck==plan.deck}.deepCopy);
            snapshot;
        }
    };
};
~djRate={|deck,rating|
    var snapshot,previous,event,id,path,payload,success=false;
    if([1,-1].includes(rating).not){Error("Use thumbs up or thumbs down").throw};
    if((~djPlaying ? false) and:{~djHeardTracks.notNil} and:{~djHeardTracks[deck].notNil}
        and:{~djLastAutomation.notNil} and:{~djLastAutomation.gains[deck].maxItem>0.001}){
        snapshot=~djHeardTracks[deck];
        previous=~djRatings[snapshot.track_id];
        if(previous.isNil or:{previous.rating!=rating}){
            try {
                ~djFeedbackCounter=~djFeedbackCounter+1;
                id=Date.gmtime.asSortableString++"-"++~djFeedbackRunID++"-"++~djFeedbackCounter.asString.padLeft(8,"0");
                event=snapshot.deepCopy;
                event.schema=1;event.id=id;event.session_id=~djFeedbackRunID;event.timestamp=Date.gmtime.format("%Y-%m-%dT%H:%M:%SZ");
                event.recorded_at=Date.gmtime.rawSeconds;event[\source]=~djSourceFingerprint;event.deck=deck;event.rating=rating;
                event.supersedes=if(previous.notNil){previous.id}{nil};
                event.beat=~djLastAutomation.beat;event.bpm=~djLastAutomation.bpm;
                event.mix=~djLastAutomation.gains.deepCopy;event.effects=~djLastAutomation.fx[deck].deepCopy;
                ~djFeedbackDir.mkdir;
                path=~djFeedbackDir+/+(id++".json");payload=~djJSON.value(event)++"\n";
                File.use(path,"w",{|file|
                    if(file.isOpen.not){Error("Cannot open listening feedback file").throw};
                    file.write(payload);file.flush;
                });
                if(File.readAllString(path)!=payload){Error("Listening feedback write was incomplete").throw};
                ~djRatings[event.track_id]=event;
                ("DJ feedback saved / "++if(rating>0){"thumbs up"}{"thumbs down"}++" / "++event.track_id).postln;
                success=true;
            } {|error|
                if(path.notNil and:{File.exists(path)}){File.delete(path)};
                ("DJ feedback was not saved / "++error.errorString).postln;
            };
        }{
            "DJ feedback already saved for this song".postln;success=true;
        };
    }{
        "DJ feedback ignored / choose a playing deck".postln;
    };
    success;
};
)
