// Standalone render: default set, track, palette tour, or focused Digital Drive.
(
var root=thisProcess.nowExecutingPath.dirname,repo=root.dirname.dirname.dirname;
var recipeName=~djRenderRecipe,recipeSpec,reference;
var component=~djRenderComponent;
var classic=thisProcess.argv.includesEqual("classic") or: {
    ["palettes","digital"].any { |flag| thisProcess.argv.includesEqual(flag) }
} or: {~djRenderChannel==\edm};
var e=(~djRenderChannel==\edme) or: {thisProcess.argv.includesEqual("edme")} or: {
    classic.not and: {thisProcess.argv.includesEqual("pop").not} and: {~djRenderRecipe.isNil}
};
var eCompare=e and: {thisProcess.argv.includesEqual("compare")};
var eSet=e and: {thisProcess.argv.includesEqual("set") or: {thisProcess.argv.isEmpty and: {~djRenderChannel.isNil}}};
var eMode=["bass","percussion","chords"].detect { |name|thisProcess.argv.includesEqual(name)} ? "full";
var track=thisProcess.argv.includesEqual("track") or: {e and: {eCompare.not} and: {eSet.not}};
var tour=thisProcess.argv.includesEqual("palettes");
var pop=thisProcess.argv.includesEqual("pop");
var digital=thisProcess.argv.includesEqual("digital");
var name,bars,engine,score=List.new,time=0.1,tempo=128,node=1000,timeline,osc,duration;
var columns=["bar","seconds","bpm","mixing","record_a","record_b","section_a","section_b",
    "intensity_a","intensity_b","chaos_a","chaos_b","density_a","density_b","palette_a","palette_b",
    "stutter_division","stutter_remaining","stutter_source","stutter_deck",
    "breath_a","breath_b","low_gap_a","low_gap_b","bass_tone_a","bass_tone_b","bass_drive_a","bass_drive_b",
    "cut_from_a","cut_from_b","drum_spotlight_a","drum_spotlight_b","stutter_start_beat","stutter_bars","e_mode","e_variant_a","e_variant_b",
    "e_chord_notes","e_shaker_hits","e_tom_hits","e_signature_hits","e_slides"]
    ++ if(pop) {["pop_degree_a","pop_degree_b","pop_harmony_a","pop_harmony_b",
        "pop_progression_a","pop_progression_b","pop_chord_bars_a","pop_chord_bars_b"]} {[]};
try {
    (root +/+ "engine.scd").load; (root +/+ "instruments.scd").load;
    name=case {eCompare} {"edm-e-building-blocks"} {eSet} {"edm-e-set"}
        {e} {if(eMode=="full") {"edm-e-groove"} {"edm-e-" ++ eMode}} {pop} {"dj-pop-preview"} {digital} {"digital-drive-rounded-v6d"} {tour} {"dj-groove-palettes-v6d"}
        {track} {"groove-track-v6d"} {true} {"dj-groove-v6d"};
    bars=case {eCompare} {32} {eSet} {112} {e} {48} {pop} {96} {digital} {4} {tour} {32} {track} {48} {true} {112};
    if(pop) {tempo=138};
    engine=~makeDJEngine.value(2600,tempo,case
        {e} {(channel:\edme,eMode:eMode.asSymbol,hold:eSet.not)} {pop} {(channel:\pop)} {digital} {(channel:\edm,hold:true,palette:2,autoStutter:false)}
        {track} {(channel:\edm,hold:true)} {true} {(channel:\edm)});
    if(recipeName.notNil) {
        (root +/+ "recall.scd").load;
        recipeSpec=~djReadRecipe.value(recipeName);
        if(component.notNil and: {recipeSpec[4].asInteger!=0}) {
            Error("Isolated overlays require a plain EDM source recipe").throw;
        };
        reference=~djSessionFromRecipe.value(recipeSpec);reference.persistRecipes=false;
        if(~djRenderChannel.notNil) {
            if([0,2].includes(recipeSpec[4].asInteger).not or: {[\edm,\edme].includes(~djRenderChannel).not}) {
                Error("Channel comparisons require an EDM or EDM E recipe").throw;
            };
            recipeSpec=recipeSpec.deepCopy;
            recipeSpec[4]=[\edm,\pop,\edme].indexOf(~djRenderChannel);
        };
        engine=~djSessionFromRecipe.value(recipeSpec);engine.persistRecipes=false;
        tempo=engine.state.bpm;
        bars=~djRenderBars ? 40;
        name=~djRenderName;
        if(name.isNil) {Error("Recipe render needs an output name").throw};
        ("Recipe / " ++ recipeName ++ " / " ++ engine.channel ++ " / " ++ engine.controls).postln;
    };
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
        if(eCompare and: {bar%8==0}) {
            eMode=["baseline","percussion","chords","bass"][bar div:8];
            engine=~makeDJEngine.value(2600,128,(hold:true,palette:0,autoStutter:false,
                channel:if(bar==0) {\edm} {\edme},eMode:eMode.asSymbol));
        };
        if(tour and: {bar%8==0}) {
            engine=~makeDJEngine.value(2600,128,(channel:\edm,hold:true,palette:bar div:8,autoStutter:false));
            // All ensembles play the same bass-led eight-bar hook section.
            8.do {engine[\nextBar].value};
        };
        frame=engine[\nextBar].value; plans=frame.decks;
        if(reference.notNil) {
            var original=reference[\nextBar].value,roles=[\djKick,\djClap,\djSnare,\djHat];
            if(component.notNil) {
                var additions=frame.events.select { |event|
                    switch(component,
                        \percussion,{[\eShaker,\eTom].includes(event.role)},
                        \chords,{event.role==\eChord},
                        \bass,{event.role==\djBass},
                        {false});
                };
                // Keep every original part. Only the bass audition replaces its own lane.
                frame.events=(original.events.reject { |event|component==\bass and: {event.role==\djBass} }
                    ++ additions).sort { |a,b|a.beat<b.beat };
            };
            if(original.events.select { |event|roles.includes(event.role)}
                != frame.events.select { |event|roles.includes(event.role)}) {
                Error("Recipe adaptation changed the foundation drums").throw;
            };
            if(original.automation!=frame.automation) {Error("Recipe adaptation changed mix automation").throw};
        };
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
        row=row++[if(e) {component ? eMode} {"none"},
            if(component.notNil and: {component!=\bass}) {\none} {field.value(0,\eVariant,\none)},
            if(component.notNil and: {component!=\bass}) {\none} {field.value(1,\eVariant,\none)},
            frame.events.count { |e|e.role==\eChord},frame.events.count { |e|e.role==\eShaker},
            frame.events.count { |e|e.role==\eTom},frame.events.count { |e|e.role==\eSignature},
            frame.events.count { |e|(e[\glide] ? 0)>0}];
        if(pop) {
            var degree={ |id| if(plans[id].isNil) {-1} {plans[id].schedule[plans[id].localBar].degree} };
            var role={ |id| if(plans[id].isNil) {\waiting} {plans[id].schedule[plans[id].localBar].harmonyRole} };
            var progression={ |id| if(plans[id].isNil) {"none"} {plans[id].currentProgression.join(",")} };
            var length={ |id| if(plans[id].isNil) {0} {plans[id].schedule[plans[id].localBar].bars} };
            row=row++[degree.value(0),degree.value(1),role.value(0),role.value(1),
                progression.value(0),progression.value(1),length.value(0),length.value(1)];
        };
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
    timeline.write(([bars,time.round(0.000000001),tempo,0,-1,-1,"end","end",0,0,0,0,0,0,-1,-1,0,0,"none",-1,0,0,0,0,0,0,0,0,4,4,0,0,0,0,"end","none","none",0,0,0,0,0]
        ++if(pop) {[-1,-1,"end","end","none","none",0,0]} {[]})
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
