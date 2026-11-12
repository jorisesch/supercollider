// Render two EDM excerpts, then process each identical waveform three ways.
// sclang render.scd <existing output directory>
(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname,output=thisProcess.argv.at(0);
var tracks=[
    (id:"brass",name:"E Aeolian / Brass Circuit",seed:14829,bpm:128,mode:\aeolian,key:4,palette:1,energy:0.55),
    (id:"wired",name:"G Ionian / Wired House",seed:25951,bpm:128,mode:\ionian,key:7,palette:0,energy:0.30)
];
var versions=[
    (id:"dry",name:"No mix-bus compression",ratio:1,threshold:0.055,attack:0.02,release:0.16),
    (id:"current",name:"Previous EDM compression",ratio:1.8181818,threshold:0.48,attack:0.006,release:0.12),
    (id:"gentle",name:"Gentle compression",ratio:2.5,threshold:0.035,attack:0.02,release:0.16),
    (id:"strong",name:"Stronger compression",ratio:4,threshold:0.027,attack:0.004,release:0.18)
];
var trackIndex=0,versionIndex=0,renderMix,renderVersion,duration;
try {
    if(output.isNil or:{File.exists(output).not}){Error("Provide an existing output directory").throw};
    (dj+/+"engine.scd").load;(dj+/+"instruments.scd").load;(dj+/+"feedback.scd").load;
    (root+/+"instruments.scd").load;
    TempoClock.default.tempo=1;
    renderMix={
        var spec=tracks[trackIndex],energy=spec.energy;
        var settings=(channel:\edme,palette:spec.palette,tonality:spec.mode,
            chaos:0.08+(energy*0.34),density:0.28+(energy*0.54),mutation:0.12+(energy*0.36),
            tension:0.02+(energy*0.36),hold:true,autoStutter:false);
        var engine=~makeDJEngine.value(spec.seed,spec.bpm,settings);
        var score=List.new,frame,at=0.1,beat=60/spec.bpm,node=2000,path=output+/+spec.id;
        var bars=16,sections=List.new,previous;
        frame=engine[\nextBar].value;
        if(frame.decks[0].key!=spec.key){Error("Excerpt seed no longer gives the intended key").throw};
        spec.cueBar=(frame.decks[0].sections.detect {|part|[\hook,\drop].includes(part.name)}.start-4).max(frame.decks[0].localBar);
        while {frame.decks[0].localBar<spec.cueBar}{frame=engine[\nextBar].value};
        (~djDefs++~edmComparisonDefs).do {|def|score.add([0,[\d_recv,def.asBytes]])};
        score.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],
            [\s_new,\djDeck,800,1,100,\in,16,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,spec.bpm],
            [\s_new,\djDeck,801,1,100,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,spec.bpm],
            [\s_new,\edmComparisonMix,900,1,100,\in,28]]);
        bars.do {|bar|
            if(frame.decks[0].section!=previous){
                sections.add([bar,frame.decks[0].section]);previous=frame.decks[0].section;
            };
            frame.automation.do {|point|score.add([at+(point.beat*beat)]++~djAutomation.value(point,[800,801]))};
            frame.events.do {|event|
                score.add([at+(event.beat*beat),~djMessage.value(event,node,110,16,spec.bpm)]);node=node+1;
            };
            at=at+(4*beat);
            frame=engine[\nextBar].value;
        };
        score.add([at,[\n_set,900,\gate,0]]);
        duration=at+3;score.add([duration,[\c_set,0,0]]);
        File.use(path++".json","w",{|file|
            file.write(~djJSON.value(spec.copy.putAll((bars:bars,seconds:duration,sections:sections.asArray,
                versions:versions,baseline:"Mix-bus compression bypassed; existing deck kick ducking retained")))++"\n");
        });
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(
            oscFilePath:path++"-mix.osc",outputFilePath:path++"-mix.wav",sampleRate:48000,
            headerFormat:"WAV",sampleFormat:"int24",duration:duration,
            options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
                .numWireBufs_(128).memSize_(65536).loadDefs_(false),
            action:{|code|
                File.delete(path++"-mix.osc");
                if(code!=0){code.exit};
                versionIndex=0;
                try {renderVersion.value}{|error|error.reportError;1.exit};
            });
    };
    renderVersion={
        var spec=tracks[trackIndex],version=versions[versionIndex],score=List.new;
        var path=output+/+(spec.id++"-"++version.id),input=output+/+(spec.id++"-mix.wav");
        var processor=~edmComparisonDefs[1];
        score.add([0,[\d_recv,processor.asBytes],
            [\b_allocRead,0,input,0,-1]]);
        score.add([0.05,[\s_new,\edmComparisonCompression,1000,0,1,\buffer,0,
            \legacy,if(version.id=="current"){1}{0},\ratio,version.ratio,\threshold,version.threshold,\attack,version.attack,\release,version.release]]);
        score.add([duration+0.05,[\c_set,0,0]]);
        ("Rendering "++spec.name++" / "++version.name).postln;
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(
            oscFilePath:path++".osc",outputFilePath:path++"-analysis.wav",sampleRate:48000,
            headerFormat:"WAV",sampleFormat:"int24",duration:duration+0.05,
            options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(3).memSize_(65536).loadDefs_(false),
            action:{|code|
                File.delete(path++".osc");
                if(code!=0){code.exit};
                versionIndex=versionIndex+1;
                if(versionIndex<versions.size){
                    try {renderVersion.value}{|error|error.reportError;1.exit};
                }{
                    trackIndex=trackIndex+1;
                    if(trackIndex<tracks.size){
                        try {renderMix.value}{|error|error.reportError;1.exit};
                    }{0.exit};
                };
            });
    };
    File.use(output+/+"comparison.json","w",{|file|
        file.write(~djJSON.value((title:"EDM compression",tracks:tracks.collect(_.id),
            storageKey:"infinite-dj-edm-compression-01",
            intro:"A bypasses mix-bus compression. B uses the previous EDM compressor. C uses gentle stereo-linked compression. D uses the stronger Pop setting. Existing deck kick ducking stays in every version; the master limiter is bypassed for this test."))++"\n");
    });
    renderMix.value;
} {|error|error.reportError;1.exit};
)
