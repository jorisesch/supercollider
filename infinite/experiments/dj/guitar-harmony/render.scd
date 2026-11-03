// Harmony studies use the existing contact/string/pedal definitions unchanged.
(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname,repo=dj.dirname.dirname.dirname;
var pending=5,failed=false,options,finish,message,render,node=2000,studies,events=List.new,probes=List.new;
try {
    var monitor,probe=List.new,cases=List.new;
    (dj+/+"instruments.scd").load;(dj+/+"guitar-prototypes/instruments.scd").load;
    (dj+/+"guitar-prototypes/gestures.scd").load;(dj+/+"guitar-contact/contact.scd").load;
    (dj+/+"guitar-contact/performance.scd").load;(dj+/+"guitar-contact/instruments.scd").load;
    (root+/+"harmony.scd").load;(root+/+"performance.scd").load;studies=~ghBuildStudies.value;
    TempoClock.default.tempo=1;
    finish={|code|pending=pending-1;failed=failed or:{code!=0};if(pending==0){if(failed){1.exit}{0.exit}}};
    options={|channels|ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(channels)
        .numWireBufs_(256).memSize_(65536).loadDefs_(false)};
    monitor=SynthDef(\harmonyMonitor,{|in=28|Out.ar(0,Limiter.ar(In.ar(in,2)*0.35,0.9,0.01))});
    ~djDefs=~djDefs++[monitor];
    message={|e,out=16|
        var result=[\s_new,\rockContactGuitar,node,0,110,\out,out,\freq,e[\note].midicps,\sustain,e[\hold],
            \stringIndex,e[\string],\amp,0.55,\seed,731+node]++~gcArgs.value(e[\initial]);
        node=node+1;result;
    };
    events.add("study\tchange\tstroke\tdirection\tstring\tnote\tat\thold\tmaterial");
    render={|key,name,duration|
        var score=List.new;
        ~djDefs.do {|d|score.add([0,[\d_recv,d.asBytes]])};
        score.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],
            [\s_new,\rockPhysicalDeck,800,1,100,\in,16,\out,28,\musicGain,1.4,\guitarPedal,0,
                \guitarComp,0,\guitarChorus,0,\fxReverb,0,\fxEcho,0],
            [\s_new,\harmonyMonitor,900,1,100,\in,28]]);
        studies[key].do {|e|
            score.add([e[\at],message.value(e)]);
            events.add([key,e[\change],e[\stroke],e[\direction],e[\string],e[\note],e[\at],e[\hold],e[\initial][\material]]
                .collect(_.asString).join("\t"));
        };
        score.add([duration-0.4,[\n_free,100]]);score.add([duration,[\c_set,0,0]]);
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:Platform.defaultTempDir+/+(name++".osc"),
            outputFilePath:repo+/+"audio"+/+(name++"-raw.wav"),sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:duration,
            options:options.value(2),action:finish);
    };
    render.value(\triads,"rock-triad-voicings",32.5);
    render.value(\extensions,"rock-chord-colors",36.5);
    render.value(\slash,"rock-slash-chords",32.5);
    render.value(\phrasing,"rock-chord-phrasing",40.5);
    File.use(root+/+"events.tsv","w",{|f|f.write(events.join("\n")++"\n")});
    File.use(root+/+"chords.tsv","w",{|f|
        f.write("id\tstudy\tsection\tkey\tlabel\tat\tuntil\tpattern\tbass\tinversion\tstrings\tnotes\tfrets\n");
        ~ghChanges.do {|c|
            var voices=c[\voices],opens=[40,45,50,55,59,64];
            f.write([c[\id],c[\study],c[\section],c[\key],c[\label],c[\at],c[\until],c[\pattern],c[\bass],c[\inversion],
                voices.collect {|p|p[0]}.join(","),voices.collect {|p|p[1]}.join(","),
                voices.collect {|p|p[1]-opens[p[0]]}.join(",")].collect(_.asString).join("\t")++"\n");
        };
    });
    // Each string has its own stereo diagnostic output, so actual chord pitches
    // and the lowest sounding note can be verified without polyphonic guessing.
    cases=~ghChanges.select {|c|(c[\study]==\triads and:{c[\section]==0} and:{c[\at]<4})
        or:{c[\study]==\extensions}
        or:{c[\study]==\slash and:{c[\section]==0} and:{c[\key]==\ae}}
        or:{c[\study]==\slash and:{c[\section]==1} and:{c[\key]==\de}}};
    ~djDefs.do {|d|probe.add([0,[\d_recv,d.asBytes]])};probe.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100]]);
    probes.add("case\tchange\tat\tstring\tnote\thold");
    cases.do {|c,i|
        ~gcStroke.value(c[\voices],0.1+(i*2),\down,\hard,1.6,1.2).do {|e|
            probe.add([e[\at],message.value(e,e[\string]*2)]);
            probes.add([i,c[\id],e[\at],e[\string],e[\note],1.2].collect(_.asString).join("\t"));
        };
    };
    File.use(root+/+"probes.tsv","w",{|f|f.write(probes.join("\n")++"\n")});
    probe.add([(cases.size*2)+0.2,[\c_set,0,0]]);
    Score(probe.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:Platform.defaultTempDir+/+"rock-harmony-probes.osc",
        outputFilePath:Platform.defaultTempDir+/+"rock-harmony-probes.wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:(cases.size*2)+0.2,
        options:options.value(12),action:finish);
} {|error|error.reportError;1.exit};
)
