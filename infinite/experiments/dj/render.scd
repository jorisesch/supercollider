// Standalone 112-bar preview, using exactly the live engine and message adapters.
(
var root=thisProcess.nowExecutingPath.dirname,repo=root.dirname.dirname.dirname;
var engine,score=List.new,time=0.1,tempo=128,node=1000,bars=112,timeline,osc,duration;
var columns=["bar","seconds","bpm","mixing","record_a","record_b","section_a","section_b",
    "intensity_a","intensity_b","chaos_a","chaos_b","density_a","density_b"];
try {
    (root +/+ "engine.scd").load; (root +/+ "instruments.scd").load;
    engine=~makeDJEngine.value(2600,128);
    TempoClock.default.tempo=1;
    score.add([0] ++ ~djDefs.collect { |def| [\d_recv,def.asBytes] });
    score.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],[\g_new,111,0,100],
        [\s_new,\djDeck,800,1,100,\in,16,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,128],
        [\s_new,\djDeck,801,1,100,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,128],
        [\s_new,\djMaster,999,1,100,\in,28]]);
    timeline=File(root +/+ "preview-timeline.tsv","w");
    timeline.write(columns.join("\t") ++ "\n");
    bars.do { |bar|
        var frame=engine[\nextBar].value,actions=List.new,previous=0,plans=frame.decks;
        var field={ |deck,key,fallback|
            if(plans[deck].isNil) {fallback} {plans[deck][key]}
        };
        var macro={ |deck,key| if(plans[deck].isNil) {0} {plans[deck].effective[key]} };
        var row=[bar,time.round(0.000000001),tempo,if(engine.state.mixing) {1} {0},
            field.value(0,\serial,-1),field.value(1,\serial,-1),
            field.value(0,\section,\waiting),field.value(1,\section,\waiting),
            field.value(0,\intensity,0),field.value(1,\intensity,0),
            macro.value(0,\chaos),macro.value(1,\chaos),macro.value(0,\density),macro.value(1,\density)];
        timeline.write(row.collect(_.asString).join("\t") ++ "\n");
        frame.automation.do { |point| actions.add((beat:point.beat,automation:point)) };
        frame.events.do { |event| actions.add((beat:event.beat,note:event)) };
        actions=actions.sort { |a,b|
            if(a.beat==b.beat) { a[\automation].notNil and: { b[\automation].isNil } } { a.beat < b.beat }
        };
        actions.do { |action|
            time=time+((action.beat-previous)*60/tempo); previous=action.beat;
            if(action[\automation].notNil) {
                tempo=action.automation.bpm;
                score.add([time] ++ ~djAutomation.value(action.automation,[800,801]));
            } {
                var event=action.note;
                score.add([time,~djMessage.value(event,node,[110,111][event.deck],16,tempo)]);
                node=node+1;
            };
        };
        time=time+((4-previous)*60/tempo);
    };
    timeline.write([bars,time.round(0.000000001),tempo,0,-1,-1,"end","end",0,0,0,0,0,0]
        .collect(_.asString).join("\t") ++ "\n");
    timeline.close;
    score.add([time,[\n_set,999,\gate,0]]);
    duration=time+4;
    score.add([duration,[\c_set,0,0]]);
    osc=Platform.defaultTempDir +/+ "dj-evolving-v2.osc";
    ("Rendering evolving DJ / " ++ bars ++ " bars / " ++ duration.round(0.001) ++ " seconds").postln;
    Score(score.asArray).recordNRT(oscFilePath:osc,outputFilePath:repo +/+ "audio/dj-evolving-v2.wav",
        sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",
        options:ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false),
        duration:duration,action:{ |code|
            File.delete(osc);
            if(code==0) { "Completed evolving DJ preview".postln; 0.exit } { 1.exit };
        }
    );
} { |error| if(timeline.notNil) { timeline.close }; error.reportError; 1.exit };
)
