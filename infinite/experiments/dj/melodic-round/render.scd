// Listening round 04. Pure offline scores; does not change the live generator.
(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname,output=thisProcess.argv.at(0);
var recipes=(root+/+"recipes.scd").load,index=0,render,velvet,extraDefs=#[];
var neonStudy=thisProcess.argv.at(1)=="neon",instrumental=thisProcess.argv.at(1)=="instrumental";
var referenceBacking,referenceMelody;
try {
    if(output.isNil or:{File.exists(output).not}){Error("Provide an existing output directory").throw};
    if(neonStudy){
        recipes=(root+/+"neon-leads/recipes.scd").load;
        extraDefs=(root+/+"neon-leads/instruments.scd").load;
    };
    // Round 04 verdict: keep every backing, drop the lead until a better one is approved.
    if(instrumental){
        recipes=recipes.collect {|spec|spec.copy.putAll((muteLead:true,
            paletteName:spec.paletteName++" / instrumental, lead dropped"))};
    };
    if(thisProcess.argv.at(1).notNil and:{neonStudy.not and:{instrumental.not}}){
        recipes=recipes.select {|spec|spec.id==thisProcess.argv[1]};
        if(recipes.isEmpty){Error("Unknown audition ID").throw};
    };
    (dj+/+"engine.scd").load;(dj+/+"instruments.scd").load;(dj+/+"song-styles.scd").load;(dj+/+"feedback.scd").load;
    TempoClock.default.tempo=1;
    velvet=SynthDef(\round04VelvetLead,{|out=0,freq=440,amp=0.13,sustain=0.4,tone=0.4,pan=0|
        var env=EnvGen.kr(Env.linen(0.018,sustain.max(0.04),0.14),doneAction:2);
        var sig=VarSaw.ar(freq*[0.998,1.002],[0,0.04],0.43).sum*0.22+SinOsc.ar(freq,0,0.38);
        Out.ar(out,Pan2.ar(HPF.ar(LPF.ar(sig,850+(tone.clip(0,1)*2800)),100),pan)*amp*env);
    });
    render={
        var spec=recipes[index],score=List.new,beat=60/spec.bpm,bars=32,node=2000;
        var events=List.new,melody=List.new,mix=~djMixSpec.value(spec.channel);
        var duration=0.11+(bars*4*beat)+4,path=output+/+spec.id,songState=~djSongStyleState.value;
        // A's theme is also the final return: same pitches and rhythm, not a new riff.
        (~djDefs++[velvet]++extraDefs).do {|def|score.add([0,[\d_recv,def.asBytes]])};
        score.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],
            [\s_new,mix.deck,800,1,100,\in,16,\out,28,\bpm,spec.bpm,
                \musicGain,1,\bassGain,1,\drumsGain,1,\fxEcho,0.045,\fxDelay,0.75,\fxReverb,0.11],
            [\s_new,mix.master,900,1,100,\in,28,\drive,mix.drive]]);
        bars.do {|bar|
            // Backing and lead comes from the song-style grammar the live DJ plays.
            var backing=~djSongStyleSourceBar.value(spec,bar,songState,
                (voice:spec.leadVoice,amp:spec.leadAmp,tone:spec.leadTone));
            backing.events.do {|event|
                events.add(event.putAll((bar:bar,deck:0,color:0)));
            };
            backing.melody.do {|note|melody.add(note.put(\bar,bar))};
        };
        if(events.select {|e|e.bar<4}.any {|e|e.lane!=3}){Error("Drum intro has pitched parts").throw};
        melody.do {|note|
            if(note.landing and:{note.chordTones.includes(note.note%12).not}){Error("Melody missed its chord landing").throw};
            if(note.note<57 or:{note.note>83}){Error("Melody left the comfortable lead range").throw};
        };
        7.do {|offset|
            var first=melody.select {|note|note.bar==(8+offset)}.collect {|note|[note.step,note.note,note.duration]};
            var returning=melody.select {|note|note.bar==(24+offset)}.collect {|note|[note.step,note.note,note.duration]};
            if(first!=returning){Error("Return lost the recognizable hook").throw};
        };
        if(neonStudy){
            var backing=events.select {|event|event.lane!=1}.asArray;
            if(referenceBacking.isNil){referenceBacking=backing.deepCopy;referenceMelody=melody.deepCopy}{
                if(backing!=referenceBacking){Error("Lead audition changed the approved backing events").throw};
                if(melody!=referenceMelody){Error("Lead audition changed melody notes or timing").throw};
            };
        };
        events.do {|event|
            if(spec[\muteLead]!=true or:{event.lane!=1}){
                score.add([0.11+((event.bar*4+event.beat)*beat),~djMessage.value(event,node,110,16,spec.bpm)]);
            };
            node=node+1;
        };
        score.add([duration-4,[\n_set,900,\gate,0]]);
        score.add([duration,[\c_set,0,0]]);
        File.use(path++".json","w",{|file|
            file.write(~djJSON.value(spec.copy.putAll((file:spec.id++".wav",bars:bars,seconds:duration,
                sections:[[0,"drums"],[4,"bass groove"],[8,"hook"],[16,"space"],[20,"build"],[24,"hook returns"]],
                melodyEvents:melody.asArray,master:mix.master,productionChanged:false)))++"\n");
        });
        ("Rendering "++spec.id++" / "++spec.name++" / lead range "++melody.collect(_.note).minItem++".."++melody.collect(_.note).maxItem).postln;
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(
            oscFilePath:path++".osc",outputFilePath:path++".wav",sampleRate:48000,
            headerFormat:"WAV",sampleFormat:"int24",duration:duration,
            options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
                .numWireBufs_(128).memSize_(65536).loadDefs_(false),
            action:{|code|
                File.delete(path++".osc");if(code!=0){code.exit};index=index+1;
                if(index<recipes.size){try{render.value}{|error|error.reportError;1.exit}}{0.exit};
            });
    };
    render.value;
} {|error|error.reportError;1.exit};
)
