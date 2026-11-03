// Same performance, five pickup wirings, two monitoring paths. Offline only.
(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname,tmp=Platform.defaultTempDir;
var pending=4,failed=false,render,score=List.new,events=List.new,defs,node=2000,voice,stroke;
var spatial=List.new,circuit=List.new,hum=List.new,frequencies=[60,110,400,1000,1800,2400,3300,4400,6000,10000];
try {
    var tone,opens=[40,45,50,55,59,64],mismatch;
    (dj+/+"instruments.scd").load;(dj+/+"guitar-contact/contact.scd").load;
    (dj+/+"guitar-contact/performance.scd").load;
    (root+/+"model.scd").load;(root+/+"instruments.scd").load;
    TempoClock.default.tempo=1;
    tone=SynthDef(\hpCircuitTone,{|freq=60|
        var sig=SinOsc.ar(freq,0,0.02)!2;Out.ar(16,sig);Out.ar(0,sig);
    });
    defs=~hpDefs++[tone];
    render={|list,name,channels,duration|
        var osc=tmp+/+(name++".osc");
        list.add([duration,[\c_set,0,0]]);
        Score(list.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:osc,outputFilePath:tmp+/+(name++".wav"),
            sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:duration,
            options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(channels)
                .numWireBufs_(256).memSize_(65536).loadDefs_(false),
            action:{|code|
                File.delete(osc);pending=pending-1;failed=failed or:{code!=0};
                ("Pickup render / "++name++" / exit "++code).postln;
                if(pending==0){if(failed){1.exit}{0.exit}};
            });
    };
    [score,spatial,circuit,hum].do {|list|defs.do {|d|list.add([0,[\d_recv,d.asBytes]])}};
    stroke={|notes,at,hold,dir=\down,material=\hard,speed=1.5,depth=0.00042,vibrato=0|
        var index=events.size;
        ~gcStroke.value(notes,at,dir,material,speed,hold,depth,0,index).do {|e|
            e[\vibrato]=vibrato;e[\pan]=(e[\string]-2.5)*0.045;events.add(e);
        };
    };
    stroke.value([[0,40],[1,47],[2,54],[3,56],[4,59],[5,64]],0.1,0.66);
    stroke.value([[3,56],[4,59],[5,64]],0.95,0.28,\up,\hard,2.1);
    stroke.value([[0,40]],1.60,0.32,\down,\hard,1.5,0.0005);
    stroke.value([[3,55]],2.15,0.28,\up,\hard,1.5,0.00036);
    stroke.value([[3,57]],2.55,0.42);
    stroke.value([[3,59]],3.10,0.55,\up);
    stroke.value([[4,64]],3.85,1.35,\down,\hard,1.5,0.00046,0.13);
    stroke.value([[3,59],[4,62]],5.45,0.68,\pinch,\nail,1.5,0.00054);
    stroke.value([[0,40],[1,47],[2,50],[3,55],[4,59],[5,64]],6.55,1.20,\down,\hard,1.0,0.00048);
    stroke.value([[2,52]],8.20,1.25,\down,\hard,1.5,0.00043);
    voice={|e,p,group,out=16,diagnostic=false|
        var initial=~hpInitial.value(e[\initial],p,if(e[\direction]==\up){-1}{1}),msg;
        if(diagnostic){initial[\horizontalRatio]=0;initial[\energyDelta]=0};
        msg=[\s_new,\hpString,node,0,group,\out,out,\freq,e[\note].midicps,\stringIndex,e[\string],
            \amp,0.55,\sustain,e[\hold],\seed,731+e[\stroke],\pan,e[\pan],\vibrato,e[\vibrato]]++~gcArgs.value(initial);
        node=node+1;msg;
    };
    ~hpPresets.do {|preset,i|
        var group=100+i,at=i*10,p=preset[\config],name=("hpPickup"++i).asSymbol;
        score.add([at+0.01,[\g_new,group,0,1],[\s_new,name,800+i,1,group,\in,16,\out,28],
            [\s_new,\hpClean,850+i,1,group,\in,28,\out,0],[\s_new,\hpDrive,900+i,1,group,\in,28,\out,2]]);
        events.do {|e|score.add([at+e[\at],voice.value(e,p,group)])};
        score.add([at+9.98,[\n_free,group]]);
    };
    spatial.add([0.01,[\g_new,100,0,1]]);
    ~hpPresets.do {|preset,i|
        var e=(initial:~gcInitial.value(67,4,\hard),direction:\down,note:67,string:4,hold:1.5,stroke:0,pan:0,vibrato:0);
        spatial.add([0.1,voice.value(e,preset[\config],100,i*2,true)]);
    };
    circuit.add([0.01,[\g_new,100,0,1],[\s_new,\hpCircuitTone,700,0,100]]);
    ~hpPresets.do {|preset,i|
        circuit.add([0.02,[\s_new,("hpPickup"++i).asSymbol,800+i,1,100,\in,16,\out,(i+1)*2]]);
    };
    frequencies.do {|freq,i|circuit.add([0.1+(i*0.85),[\n_set,700,\freq,freq]])};
    circuit.add([8.6,[\n_free,100]]);
    hum.add([0.01,[\g_new,100,0,1]]);
    mismatch=~hpConfig.value(\vintage,\series,balance:0.97);
    (~hpPresets.collect {|p|p[\config]}++[mismatch]).do {|p,i|
        hum.add([0.1,[\s_new,\hpHumProbe,800+i,0,100,\out,i*2,\weight,p[\hum]]]);
        hum.add([0.85,[\n_set,800+i,\base,50]]);
    };
    hum.add([1.6,[\n_free,100]]);
    File.use(root+/+"events.tsv","w",{|f|
        f.write("stroke\tstring\tnote\tfret\tat\thold\tdirection\tmaterial\tvibrato\n");
        events.do {|e|f.write([e[\stroke],e[\string],e[\note],e[\note]-opens[e[\string]],e[\at],e[\hold],e[\direction],e[\initial][\material],e[\vibrato]]
            .collect(_.asString).join("\t")++"\n")};
    });
    File.use(root+/+"presets.tsv","w",{|f|
        var keys=[\rdc,\leff,\windingC,\cableC,\volumeR,\ampR,\lossR,\toneR,\toneC,\width,\hum];
        f.write((['name']++keys++['centers','weights']).join("\t")++"\n");
        ~hpPresets.do {|preset|
            var p=preset[\config];
            f.write(([preset[\name]]++keys.collect {|key|p[key]}++[p[\centers].join(","),p[\weights].join(",")])
                .collect(_.asString).join("\t")++"\n");
        };
    });
    ("Pickup string audio-rate oscillators: "++~hpString.children.count {|u|u.isKindOf(SinOsc) and:{u.rate==\audio}}).postln;
    render.value(score,"rock-humbucker-raw",4,50.5);
    render.value(spatial,"rock-humbucker-spatial",10,2);
    render.value(circuit,"rock-humbucker-circuit",12,8.8);
    render.value(hum,"rock-humbucker-hum",12,1.8);
} {|error|error.reportError;1.exit};
)
