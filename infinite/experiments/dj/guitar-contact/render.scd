// Isolated hand/contact studies and dry diagnostic voices. No live DJ changes.
(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname,repo=dj.dirname.dirname.dirname;
var pending=4,failed=false,finish,options,message,render,node=2000,rows=List.new,study,probe=List.new,probeRows=List.new,rowFor;
try {
    var monitor,directions=[\down,\up,\simultaneous],header;
    (dj+/+"instruments.scd").load;(dj+/+"guitar-prototypes/instruments.scd").load;
    (dj+/+"guitar-prototypes/gestures.scd").load;
    (root+/+"contact.scd").load;(root+/+"performance.scd").load;(root+/+"instruments.scd").load;
    TempoClock.default.tempo=1;study=~gcBuildStudies.value;
    finish={|code|pending=pending-1;failed=failed or:{code!=0};if(pending==0){if(failed){1.exit}{0.exit}}};
    options={|channels|ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(channels)
        .numWireBufs_(256).memSize_(65536).loadDefs_(false)};
    monitor=SynthDef(\contactMonitor,{|in=28,out=0|Out.ar(out,Limiter.ar(In.ar(in,2)*0.35,0.90,0.01))});
    ~djDefs=~djDefs++[monitor];
    message={|e,out=16,trace=48|
        var args=[\s_new,\rockContactGuitar,node,0,110,\out,out,\freq,e[\note].midicps,\sustain,e[\hold],
            \stringIndex,e[\string],\amp,0.55,\seed,731+node,\cTraceBus,trace]++~gcArgs.value(e[\initial]);
        if(e[\gesture].notNil){args=args++~gpArgs.value(e[\gesture])};node=node+1;args;
    };
    header=["study","stroke","direction","order","string","note","touch_seconds","release_seconds","hold",
        "material","pick_stiffness","string_stiffness","deflection_mm","force_n","release_kernel_ms","footprint_mm"];
    rows.add(header.join("\t"));
    probeRows.add(header.join("\t"));
    rowFor={|key,e|
        var c=e[\initial];
        [key,e[\stroke],e[\direction],e[\order],e[\string],e[\note],e[\touchAt],e[\at],e[\hold],c[\material],
            c[\pickStiffness],c[\stringStiffness],c[\displacement]*1000,c[\force],c[\releaseSeconds]*1000,c[\footprint]*1000]
            .collect(_.asString).join("\t");
    };
    render={|key,name,duration,pedal=0|
        var score=List.new;
        ~djDefs.do {|d|score.add([0,[\d_recv,d.asBytes]])};
        score.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],
            [\s_new,\rockPhysicalDeck,800,1,100,\in,16,\out,28,\musicGain,1.4,\guitarPedal,pedal,
                \guitarDrive,0.30,\guitarComp,0,\guitarChorus,0,\fxReverb,0,\fxEcho,0],
            [\s_new,\contactMonitor,900,1,100,\in,28,\out,0]]);
        study[key].do {|e|
            score.add([e[\at],message.value(e)]);rows.add(rowFor.value(key,e));
        };
        score.add([duration-0.4,[\n_free,100]]);score.add([duration,[\c_set,0,0]]);
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:Platform.defaultTempDir+/+(name++".osc"),
            outputFilePath:repo+/+"audio"+/+(name++".wav"),sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:duration,
            options:options.value(2),action:finish);
    };
    render.value(\strums,"rock-strum-raw",40.5,0);
    render.value(\contacts,"rock-contact-raw",30.5,0);
    render.value(\doubles,"rock-double-stops-raw",32.5,2);
    File.use(root+/+"events.tsv","w",{|f|f.write(rows.join("\n")++"\n")});
    ~djDefs.do {|d|probe.add([0,[\d_recv,d.asBytes]])};
    probe.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100]]);
    // Every string gets its own stereo output so onset order can be measured.
    directions.do {|direction,i|
        ~gcStroke.value(~gcVoicings[\em],0.1+(i*2),direction,\hard,1.5,1.2).do {|e|
            probe.add([e[\at],message.value(e,e[\string]*2)]);
            probeRows.add(rowFor.value(\probe_strum,e));
        };
    };
    // Material comparison, one identical G4 on the same physical string.
    [\hard,\angled,\flexible,\flesh,\nail].do {|material,i|
        var e=~gcStroke.value([[4,67]],6.1+(i*2),\down,material,1.5,1.2).first;
        probe.add([e[\at],message.value(e,0,2)]);
        probeRows.add(rowFor.value(\probe_material,e));
    };
    // Independent voices of an oblique bend, before they enter the shared rig.
    study[\doubles].select {|e|e[\stroke]==16}.do {|event|
        var e=event.copy;e[\at]=16.1+(event[\at]-16.1);
        probe.add([e[\at],message.value(e,if(e[\string]==3){0}{4},if(e[\string]==3){2}{6})]);
        probeRows.add(rowFor.value(\probe_oblique,e));
    };
    File.use(root+/+"probes.tsv","w",{|f|f.write(probeRows.join("\n")++"\n")});
    probe.add([18.2,[\c_set,0,0]]);
    Score(probe.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:Platform.defaultTempDir+/+"rock-contact-probes.osc",
        outputFilePath:Platform.defaultTempDir+/+"rock-contact-probes.wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:18.2,
        options:options.value(12),action:finish);
} {|error|error.reportError;1.exit};
)
