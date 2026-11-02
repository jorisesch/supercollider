// Render the evolving Rock set and a short three-tone comparison, from repo root.
(
var root=thisProcess.nowExecutingPath.dirname,repo=root.dirname.dirname.dirname;
var pending=2,failed=false,render;
try {
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;
    TempoClock.default.tempo=1;
    render={|tones=false|
        var score=List.new,time=0.1,tempo=102,node=1000,name=if(tones){"rock-tones"}{"rock-channel"};
        var bars=if(tones){24}{64},engine,timeline,duration,osc,records=Set.new,palettes=Set.new;
        var master=999,decks=[800,801],sources=[110,111],group=100;
        var makeMix={|at|
            score.add([at,[\g_new,group,0,1],[\g_new,sources[0],0,group],[\g_new,sources[1],0,group],
                [\s_new,~djMixSpec.value(\rock).deck,decks[0],1,group,\in,16,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,tempo],
                [\s_new,~djMixSpec.value(\rock).deck,decks[1],1,group,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,tempo],
                [\s_new,\djMaster,master,1,group,\in,28,\drive,~djMixSpec.value(\rock).drive]]);
        };
        ~djDefs.do {|def|score.add([0,[\d_recv,def.asBytes]])};
        if(tones.not){makeMix.value(0.01)};
        timeline=File(root+/+(name++"-timeline.tsv"),"w");
        timeline.write("bar\tseconds\tbpm\tmixing\trecord_a\trecord_b\tsection_a\tsection_b\tpalette_a\tpalette_b\tstutter_division\tstutter_remaining\tstutter_source\tstutter_deck\tstutter_start_beat\tstutter_bars\tsolo_a\tsolo_b\tsolo_kind_a\tsolo_kind_b\tsolo_age_a\tsolo_age_b\tsolo_bars_a\tsolo_bars_b\tlanding_notes_a\tlanding_notes_b\tlanding_degrees_a\tlanding_degrees_b\tlanding_offsets_a\tlanding_offsets_b\tlanding_beats_a\tlanding_beats_b\n");
        engine=~makeDJEngine.value(2600,tempo,(channel:\rock));
        bars.do {|bar|
            var frame,actions=List.new,previous=0,field,row,landing;
            if(tones and:{bar%8==0}){
                engine=~makeDJEngine.value(2600,102,(channel:\rock,palette:bar div:8,hold:true,tonality:\aeolian));
                8.do {engine[\nextBar].value};engine[\requestHook].value;makeMix.value(time-0.03);
            };
            frame=engine[\nextBar].value;
            field={|id,key,fallback|if(frame.decks[id].isNil){fallback}{frame.decks[id][key]}};
            row=[bar,time.round(0.000000001),tempo,if(engine.state.mixing){1}{0},
                field.value(0,\serial,-1),field.value(1,\serial,-1),field.value(0,\section,\waiting),field.value(1,\section,\waiting),
                if(frame.decks[0].isNil){-1}{frame.decks[0].palette.id},if(frame.decks[1].isNil){-1}{frame.decks[1].palette.id},
                0,0,\none,-1,0,0];
            landing={|deck,key|
                var notes=frame.events.select {|e|e.deck==deck and:{e[\rockLanding] ? false}};
                if(notes.isEmpty){"none"}{notes.collect {|e|e[key]}.join(",")};
            };
            row=row++[if(field.value(0,\rockSoloActive,false)){1}{0},if(field.value(1,\rockSoloActive,false)){1}{0},
                field.value(0,\rockSoloKind,\none),field.value(1,\rockSoloKind,\none),
                field.value(0,\rockSoloAge,0),field.value(1,\rockSoloAge,0),
                field.value(0,\rockSoloBars,0),field.value(1,\rockSoloBars,0),
                landing.value(0,\midinote),landing.value(1,\midinote),
                landing.value(0,\landingChordDegree),landing.value(1,\landingChordDegree),
                landing.value(0,\landingOffset),landing.value(1,\landingOffset),landing.value(0,\beat),landing.value(1,\beat)];
            timeline.write(row.collect(_.asString).join("\t")++"\n");
            frame.decks.do {|plan|if(plan.notNil){records.add(plan.serial);palettes.add(plan.palette.id)}};
            frame.automation.do {|point|actions.add((beat:point.beat,automation:point))};
            frame.events.do {|event|actions.add((beat:event.beat,note:event))};
            actions=actions.sort {|a,b|if(a.beat==b.beat){a[\automation].notNil and:{b[\automation].isNil}}{a.beat<b.beat}};
            actions.do {|action|
                time=time+((action.beat-previous)*60/tempo);previous=action.beat;
                if(action[\automation].notNil){
                    tempo=action.automation.bpm;score.add([time]++~djAutomation.value(action.automation,decks));
                }{
                    score.add([time,~djMessage.value(action.note,node,sources[action.note.deck],16,tempo)]);node=node+1;
                };
            };
            time=time+((4-previous)*60/tempo);
            if(tones and:{bar%8==7}){
                score.add([time,[\n_set,master,\gate,0]]);score.add([time+3.8,[\n_free,group]]);time=time+4;
            };
        };
        timeline.write([bars,time.round(0.000000001),tempo,0,-1,-1,\end,\end,-1,-1,0,0,\none,-1,0,0,0,0,\none,\none,0,0,0,0,"none","none","none","none","none","none","none","none"].collect(_.asString).join("\t")++"\n");timeline.close;
        if(tones.not){
            if(records.size<2 or:{palettes.size<2}){Error("Rock preview must include a record/ensemble handover").throw};
            score.add([time,[\n_set,master,\gate,0]]);
        };
        duration=time+if(tones){0}{4};score.add([duration,[\c_set,0,0]]);
        osc=Platform.defaultTempDir+/+(name++".osc");
        ("Rendering "++name++" / "++duration.round(0.001)++" sec / records "++records.asArray).postln;
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(
            oscFilePath:osc,outputFilePath:repo+/+"audio"+/+(name++".wav"),
            sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:duration,
            options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false),
            action:{|code|File.delete(osc);pending=pending-1;failed=failed or:{code!=0};
                ("Completed "++name++" / exit "++code).postln;
                if(pending==0){if(failed){1.exit}{0.exit}};
            });
    };
    render.value(false);render.value(true);
} {|error|error.reportError;1.exit};
)
