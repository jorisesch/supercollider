// Four actual phrase excerpts per channel: four base bars, two colored, two back home.
(
var root=thisProcess.nowExecutingPath.dirname,repo=root.dirname.dirname.dirname,pending=2,failed=false;
var order=[\dorian,\phrygian,\mixolydian,\lydian];
try {
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;TempoClock.default.tempo=1;
    [\edme,\pop].do {|channel|
        var engine=~makeDJEngine.value(2600,if(channel==\pop){138}{128},(channel:channel,tension:1,autoStutter:false));
        var history=List.new,auditions=Dictionary.new,candidate=nil,bar=0,score=List.new,node=1000,time=0.1;
        var name=if(channel==\pop){"pop-tension"}{"edm-tension"},segments,osc,duration;
        while {bar<8192 and:{auditions.size<4}}{
            var f=engine[\nextBar].value,snapshot=(events:f.events.deepCopy,automation:f.automation.deepCopy,bar:bar);
            if(candidate.notNil){
                candidate.frames.add(snapshot);
                if(candidate.frames.size==8){auditions[candidate.mode]=candidate;candidate=nil};
            };
            if(candidate.isNil and:{history.size==4}){
                f.decks.do {|plan|if(plan.notNil and:{plan.modalAccent} and:{plan.modalBarsRemaining==2}
                    and:{auditions[plan.activeTonality].isNil}){
                    candidate=(mode:plan.activeTonality,key:plan.keyName,frames:history.copy.add(snapshot),sourceBar:bar);
                }};
            };
            history.add(snapshot);if(history.size>4){history.removeAt(0)};bar=bar+1;
        };
        if(auditions.size!=4){Error("Not all four Tension colors appeared in the source set").throw};
        ~djDefs.do {|def|score.add([0,[\d_recv,def.asBytes]])};
        segments=File(root+/+(name++"-segments.tsv"),"w");
        segments.write("mode\tstart_seconds\tcolor_seconds\treturn_seconds\tend_seconds\tsource_bar\tsource_key\n");
        order.do {|mode|
            var excerpt=auditions[mode],start=time,colorAt,returnAt,tempo=excerpt.frames[0].automation[0].bpm;
            score.add([time-0.03,[\g_new,100,0,1],[\g_new,110,0,100],[\g_new,111,0,100],
                [\s_new,\djDeck,800,1,100,\in,16,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,tempo],
                [\s_new,\djDeck,801,1,100,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,tempo],
                [\s_new,\djMaster,999,1,100,\in,28]]);
            excerpt.frames.do {|frame,i|
                var actions=List.new,previous=0;
                if(i==4){colorAt=time};if(i==6){returnAt=time};
                frame.automation.do {|a|actions.add((beat:a.beat,automation:a))};
                frame.events.do {|e|actions.add((beat:e.beat,note:e))};
                actions=actions.sort {|a,b|if(a.beat==b.beat){a[\automation].notNil and:{b[\automation].isNil}}{a.beat<b.beat}};
                actions.do {|a|
                    time=time+((a.beat-previous)*60/tempo);previous=a.beat;
                    if(a[\automation].notNil){tempo=a.automation.bpm;score.add([time]++~djAutomation.value(a.automation,[800,801]))}{
                        score.add([time,~djMessage.value(a.note,node,[110,111][a.note.deck],16,tempo)]);node=node+1;
                    };
                };
                time=time+((4-previous)*60/tempo);
            };
            segments.write([mode,start,colorAt,returnAt,time,excerpt.sourceBar,excerpt.key].collect(_.asString).join("\t")++"\n");
            score.add([time,[\n_set,999,\gate,0]]);score.add([time+3.8,[\n_free,100]]);time=time+4;
        };
        segments.close;duration=time;score.add([duration,[\c_set,0,0]]);
        osc=Platform.defaultTempDir+/+(name++".osc");
        ("Rendering "++name++" / four sparse colors from "++bar++" source bars").postln;
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(
            oscFilePath:osc,outputFilePath:repo+/+"audio"+/+(name++".wav"),sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:duration,
            options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false),
            action:{|code|File.delete(osc);pending=pending-1;failed=failed or:{code!=0};("Completed "++name++" / exit "++code).postln;
                if(pending==0){if(failed){1.exit}{0.exit}};
            });
    };
} {|e|e.reportError;1.exit};
)
