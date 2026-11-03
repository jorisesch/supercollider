// Four versions of one phrase, plus pitch probes. Run from the repository root.
(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname,repo=dj.dirname.dirname.dirname;
var pending=6,failed=false,finish,render,noteMessage,rows=List.new,probes=List.new;
try {
    var options,header,traceCases=List.new,probeIDs=[2,3,6,8,9,10,18],node=2000,timbre=List.new,probeEnd;
    (dj+/+"instruments.scd").load;(root+/+"gestures.scd").load;(root+/+"instruments.scd").load;
    TempoClock.default.tempo=1;
    options={|channels|ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(channels)
        .numWireBufs_(256).memSize_(65536).loadDefs_(false)};
    finish={|code|failed=failed or:{code!=0};pending=pending-1;
        if(pending==0){if(failed){1.exit}{0.exit}}};
    header=["profile","index","beat","note","hold","kind","offset","bend_levels","bend_times",
        "vibrato_depth","vibrato_delay","vibrato_rise","rate_start","rate_end","wander","phase","skew","vibrato_mode","notch",
        "reference_bend","reference_mode","reference_vibrato"];
    rows.add(header.join("\t"));
    noteMessage={|profile,note,i,out=16,probe=false|
        var hold=note[2]*60/96,p=~gpGesture.value(profile,note,i,hold),voice,extra,message;
        voice=if(profile==\reference){\rockPhysicalGuitar}{\rockGesturePrototype};
        extra=if(profile==\reference){[\bendSemis,p[\refBend],\bendMode,p[\refMode],\vibrato,p[\refVib],\vibratoRate,5.3]}{~gpArgs.value(p)};
        message=[\s_new,voice,node,0,110,\out,out,\freq,note[1].midicps,\amp,0.075,\sustain,hold,
            \stringIndex,if(note[1]<67){4}{5},\mute,0.04,\color,0,\pickPosition,0.115,\seed,731+i]++extra;
        if(probe){message=message++[\pTraceBus,2]};node=node+1;
        (message:message,gesture:p);
    };
    render={|profile|
        var score=List.new,name="rock-phrasing-"++profile;
        ~djDefs.do {|d|score.add([0,[\d_recv,d.asBytes]])};
        score.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],
            [\s_new,\rockPhysicalDeck,800,1,100,\in,16,\out,0,\musicGain,2.5,\guitarPedal,1,\guitarDrive,0.18,
                \guitarComp,0.20,\guitarChorus,0,\fxEcho,0,\fxReverb,0]]);
        ~gpPhrase.do {|note,i|
            var result=noteMessage.value(profile,note,i),p=result.gesture;
            score.add([0.1+(note[0]*60/96),result.message]);
            rows.add([profile,i,note[0],note[1],p[\hold],p[\kind],p[\offset],p[\levels].join(","),p[\times].join(","),
                p[\depth],p[\delay],p[\rise],p[\rateStart],p[\rateEnd],p[\wander],p[\phase],p[\skew],p[\vibMode],p[\notch],
                p[\refBend],p[\refMode],p[\refVib]].collect(_.asString).join("\t"));
            if(profile!=\reference and:{probeIDs.includes(i)}){traceCases.add([profile,i,note])};
        };
        score.add([20.5,[\n_free,100]]);score.add([22.1,[\c_set,0,0]]);
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:Platform.defaultTempDir+/+(name++".osc"),
            outputFilePath:repo+/+"audio"+/+(name++".wav"),sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:22.1,
            options:options.value(2),action:finish);
    };
    ~gpProfiles.do(render);
    File.use(root+/+"events.tsv","w",{|f|f.write(rows.join("\n")++"\n")});
    ~djDefs.do {|d|probes.add([0,[\d_recv,d.asBytes]])};
    probes.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100]]);
    File.use(root+/+"probes.tsv","w",{|f|
        f.write("profile\tindex\tstart_seconds\thold\tnote\tkind\n");
        traceCases.do {|entry,i|
            var result=noteMessage.value(entry[0],entry[2],entry[1],0,true),at=0.1+(i*3.0),p=result.gesture;
            probes.add([at,result.message]);
            f.write([entry[0],entry[1],at,p[\hold],p[\note],p[\kind]].collect(_.asString).join("\t")++"\n");
        };
    });
    probeEnd=(traceCases.size*3)+0.2;
    probes.add([probeEnd,[\c_set,0,0]]);
    Score(probes.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:Platform.defaultTempDir+/+"rock-phrasing-probes.osc",
        outputFilePath:Platform.defaultTempDir+/+"rock-phrasing-probes.wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:probeEnd,
        options:options.value(8),action:finish);
    // Check the common-term optimization against the accepted modal instrument.
    ~djDefs.do {|d|timbre.add([0,[\d_recv,d.asBytes]])};
    timbre.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100]]);
    [\rockPhysicalGuitar,\rockGestureReference,\rockGesturePrototype].do {|voice,i|
        timbre.add([0.1,[\s_new,voice,4000+i,0,110,\out,i*2,\freq,440,\amp,0.075,\sustain,1.5,
            \stringIndex,5,\mute,0.04,\color,0,\pickPosition,0.115,\seed,731,\pVDepth,0]]);
    };
    timbre.add([2,[\c_set,0,0]]);
    Score(timbre.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:Platform.defaultTempDir+/+"rock-phrasing-timbre.osc",
        outputFilePath:Platform.defaultTempDir+/+"rock-phrasing-timbre.wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:2,
        options:options.value(6),action:finish);
} {|error|error.reportError;1.exit};
)
