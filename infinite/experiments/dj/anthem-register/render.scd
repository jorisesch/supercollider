// Matched Anthem audition: only the lead's MIDI notes change, by exactly -12.
(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname,output=thisProcess.argv.at(0);
var versions=[(id:"original",transpose:0),(id:"octave-down",transpose: -12)];
var frames=List.new,render,index=0,bpm=134,seed=24000,bars=16;
try {
    var engine,frame,cue,mix;
    if(output.isNil or:{File.exists(output).not}){Error("Provide an existing output directory").throw};
    (dj+/+"engine.scd").load;(dj+/+"instruments.scd").load;(dj+/+"feedback.scd").load;
    engine=~makeDJEngine.value(seed,bpm,(channel:\edme,tonality:\ionian,hold:true,autoStutter:false));
    frame=engine[\nextBar].value;
    if(frame.decks[0].key!=6){Error("Anthem audition must be in Gb Ionian").throw};
    frame.decks[0].edmAnthem=true;
    cue=(frame.decks[0].sections.detect {|part|[\hook,\drop].includes(part.name)}.start-4)
        .max(frame.decks[0].localBar+1);
    while {frame.decks[0].localBar<cue}{frame=engine[\nextBar].value};
    bars.do {
        var events=frame.events.deepCopy;
        // Production now uses the approved lower octave. Reconstruct the old
        // register here so this historical A/B comparison stays reproducible.
        events.do {|event|if(event.voice==\edmAnthemLead){event.midinote=event.midinote+12}};
        frames.add((events:events,automation:frame.automation.deepCopy,
            section:frame.decks[0].section));
        frame=engine[\nextBar].value;
    };
    if(frames.sum {|item|item.events.count {|event|event.voice==\edmAnthemLead}}<8){
        Error("Audition does not contain enough Anthem melody").throw;
    };
    mix=~djMixSpec.value(\edme);TempoClock.default.tempo=1;
    render={
        var version=versions[index],score=List.new,time=0.1,node=2000,changed=0;
        var name=output+/+version.id,duration;
        ~djDefs.do {|def|score.add([0,[\d_recv,def.asBytes]])};
        score.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],
            [\s_new,mix.deck,800,1,100,\in,16,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,bpm],
            [\s_new,mix.deck,801,1,100,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,bpm],
            [\s_new,mix.master,999,1,100,\in,28,\drive,mix.drive]]);
        frames.do {|item|
            item.automation.do {|point|score.add([time+(point.beat*60/bpm)]++~djAutomation.value(point,[800,801]))};
            item.events.do {|source|
                var event=source.copy;
                if(event.voice==\edmAnthemLead){
                    event.midinote=event.midinote+version.transpose;changed=changed+1;
                    if(event.midinote-source.midinote!=version.transpose){Error("Wrong lead interval").throw};
                };
                if(event.copy.put(\midinote,source.midinote)!=source){Error("Backing or expression changed").throw};
                score.add([time+(event.beat*60/bpm),~djMessage.value(event,node,110,16,bpm)]);node=node+1;
            };
            time=time+(4*60/bpm);
        };
        score.add([time,[\n_set,999,\gate,0]]);
        duration=time+4;score.add([duration,[\c_set,0,0]]);
        File.use(name++".json","w",{|file|file.write(~djJSON.value((
            key:"Gb Ionian",style:"Anthem",seed:seed,bpm:bpm,bars:bars,cueBar:cue,
            transpose:version.transpose,leadNotes:changed,seconds:duration,
            sections:frames.collect(_.section),master:mix.master))++"\n")});
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(
            oscFilePath:name++".osc",outputFilePath:name++".wav",sampleRate:48000,
            headerFormat:"WAV",sampleFormat:"int24",duration:duration,
            options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
                .numWireBufs_(128).memSize_(65536).loadDefs_(false),
            action:{|code|
                File.delete(name++".osc");if(code!=0){code.exit};index=index+1;
                if(index<versions.size){try{render.value}{|error|error.reportError;1.exit}}{0.exit};
            });
    };
    render.value;
} {|error|error.reportError;1.exit};
)
