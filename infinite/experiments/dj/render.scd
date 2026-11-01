// Standalone render: default set, track, palette tour, or focused Digital Drive.
(
var root=thisProcess.nowExecutingPath.dirname,repo=root.dirname.dirname.dirname;
var track=thisProcess.argv.includesEqual("track"),tour=thisProcess.argv.includesEqual("palettes");
var digital=thisProcess.argv.includesEqual("digital");
var name,bars,engine,score=List.new,time=0.1,tempo=128,node=1000,timeline,osc,duration;
var columns=["bar","seconds","bpm","mixing","record_a","record_b","section_a","section_b",
    "intensity_a","intensity_b","chaos_a","chaos_b","density_a","density_b","palette_a","palette_b",
    "stutter_division","stutter_remaining","stutter_source","stutter_deck",
    "breath_a","breath_b","low_gap_a","low_gap_b","bass_tone_a","bass_tone_b","bass_drive_a","bass_drive_b",
    "cut_from_a","cut_from_b","drum_spotlight_a","drum_spotlight_b","stutter_start_beat","stutter_bars"];
try {
    (root +/+ "engine.scd").load; (root +/+ "instruments.scd").load;
    name=case {digital} {"digital-drive-rounded-v6d"} {tour} {"dj-groove-palettes-v6d"}
        {track} {"groove-track-v6d"} {true} {"dj-groove-v6d"};
    bars=case {digital} {4} {tour} {32} {track} {48} {true} {112};
    engine=~makeDJEngine.value(2600,128,case {digital} {(hold:true,palette:2,autoStutter:false)}
        {track} {(hold:true)} {true} {nil});
    if(digital) {12.do {engine[\nextBar].value}};
    TempoClock.default.tempo=1;
    score.add([0] ++ ~djDefs.collect { |def| [\d_recv,def.asBytes] });
    score.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],[\g_new,111,0,100],
        [\s_new,\djDeck,800,1,100,\in,16,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,128,
            \fxFilter,0,\fxCutoff,12000,\fxResonance,0.35,\fxEcho,0,\fxDelay,0.33,\fxReverb,0.14,\fxStutter,0],
        [\s_new,\djDeck,801,1,100,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,128,
            \fxFilter,0,\fxCutoff,12000,\fxResonance,0.35,\fxEcho,0,\fxDelay,0.33,\fxReverb,0.14,\fxStutter,0],
        [\s_new,\djMaster,999,1,100,\in,28]]);
    timeline=File(root +/+ (name ++ "-timeline.tsv"),"w");
    timeline.write(columns.join("\t") ++ "\n");
    bars.do { |bar|
        var frame,actions=List.new,previous=0,plans;
        var field,macro,row,paletteID;
        if(tour and: {bar%8==0}) {
            engine=~makeDJEngine.value(2600,128,(hold:true,palette:bar div:8,autoStutter:false));
            // All ensembles play the same bass-led eight-bar hook section.
            8.do {engine[\nextBar].value};
        };
        frame=engine[\nextBar].value; plans=frame.decks;
        field={ |deck,key,fallback|
            if(plans[deck].isNil) {fallback} {plans[deck][key]}
        };
        macro={ |deck,key| if(plans[deck].isNil) {0} {plans[deck].effective[key]} };
        paletteID={ |deck| if(plans[deck].isNil) {-1} {plans[deck].palette.id} };
        row=[bar,time.round(0.000000001),tempo,if(engine.state.mixing) {1} {0},
            field.value(0,\serial,-1),field.value(1,\serial,-1),
            field.value(0,\section,\waiting),field.value(1,\section,\waiting),
            field.value(0,\intensity,0),field.value(1,\intensity,0),
            macro.value(0,\chaos),macro.value(1,\chaos),macro.value(0,\density),macro.value(1,\density),
            paletteID.value(0),paletteID.value(1)]
            ++ if(frame.stutter.notNil) {[frame.stutter.division,frame.stutter.remaining,frame.stutter[\source],frame.stutter.deck]}
                {[0,0,\none,-1]};
        row=row++[if(field.value(0,\breath,false)) {1} {0},if(field.value(1,\breath,false)) {1} {0},
            if(field.value(0,\lowOut,false)) {1} {0},if(field.value(1,\lowOut,false)) {1} {0},
            field.value(0,\bassTone,0),field.value(1,\bassTone,0),
            field.value(0,\bassDrive,0),field.value(1,\bassDrive,0),
            field.value(0,\cutFrom,4),field.value(1,\cutFrom,4),
            if(field.value(0,\drumBreak,false)) {1} {0},if(field.value(1,\drumBreak,false)) {1} {0}];
        row=row++if(frame.stutter.notNil) {[frame.stutter.startBeat,frame.stutter.bars]} {[0,0]};
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
    timeline.write([bars,time.round(0.000000001),tempo,0,-1,-1,"end","end",0,0,0,0,0,0,-1,-1,0,0,"none",-1,0,0,0,0,0,0,0,0,4,4,0,0,0,0]
        .collect(_.asString).join("\t") ++ "\n");
    timeline.close;
    score.add([time,[\n_set,999,\gate,0]]);
    duration=time+4;
    score.add([duration,[\c_set,0,0]]);
    osc=Platform.defaultTempDir +/+ (name ++ ".osc");
    ("Rendering " ++ name ++ " / " ++ bars ++ " bars / " ++ duration.round(0.001) ++ " seconds").postln;
    Score(score.asArray).recordNRT(oscFilePath:osc,outputFilePath:repo +/+ ("audio/" ++ name ++ ".wav"),
        sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",
        options:ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false),
        duration:duration,action:{ |code|
            File.delete(osc);
            if(code==0) { ("Completed " ++ name).postln; 0.exit } { 1.exit };
        }
    );
} { |error| if(timeline.notNil) { timeline.close }; error.reportError; 1.exit };
)
