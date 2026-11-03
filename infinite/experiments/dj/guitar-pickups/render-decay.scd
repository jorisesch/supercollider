// Matched single-coil decay A/B. Clean guitar, followed by the same live blues riff.
(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname,repo=dj.dirname.dirname.dirname;
var score=List.new,probe=List.new,frames,engine,tempo=102,beatSeconds=60/102,node=2000,pending=2,failed=false;
var voice,render,monitor;
try {
    (dj+/+"engine.scd").load;(dj+/+"instruments.scd").load;
    TempoClock.default.tempo=1;
    engine=~makeDJEngine.value(2601,tempo,(channel:\rock,palette:1,hold:true,rockLeadVersion:3,rockToneVersion:2));
    12.do {engine[\nextBar].value};engine[\requestHook].value;
    frames=Array.fill(4,{engine[\nextBar].value});
    ~djDefs.do {|def|score.add([0,[\d_recv,def.asBytes]])};
    probe.add([0,[\d_recv,~djDefs.detect {|def|def.name==\rockSingleCoilDecay}.asBytes]]);
    monitor=SynthDef(\rockDecayMonitor,{Out.ar(0,In.ar(40,2)*0.32)});
    [score,probe].do {|list|
        list.add([0,[\d_recv,monitor.asBytes]]);
        list.add([0.01,[\s_new,\rockDecayMonitor,990,1,1]]);
    };
    voice={|list,at,out,group,take,note,string,hold,amp,pan=0|
        list.add([at,[\s_new,\rockSingleCoilDecay,node,0,group,\out,out,\freq,note.midicps,\stringIndex,string,
            \sustain,hold,\amp,amp,\pan,pan,\seed,731+string,\mute,0,\modalLoss,take]]);
        node=node+1;
    };
    2.do {|take|
        var offset=take*18,group=100+take,source=110+take,deck=800+take,master=900+take;
        var entry=offset+6, end=entry+(16*beatSeconds);
        [[0,40],[1,47],[2,50],[3,56],[4,59],[5,64]].do {|pair,i|
            voice.value(score,offset+0.15+(i*0.019),40,1,take,pair[1],pair[0],2.1,0.045,(i-2.5)*0.1);
        };
        voice.value(score,offset+2.75,40,1,take,69,5,2.65,0.12);
        score.add([entry-0.05,[\g_new,group,0,1],[\g_new,source,0,group],
            [\s_new,\rockPhysicalDeck,deck,1,group,\in,16,\out,28,\bpm,tempo],
            [\s_new,\djMaster,master,1,group,\in,28,\drive,1.8]]);
        frames.do {|frame,bar|
            var at=entry+(bar*4*beatSeconds);
            frame.automation.do {|point|score.add([at+(point.beat*beatSeconds)]++~djAutomation.value(point,[deck,deck+20]).keep(1))};
            frame.events.do {|event|
                var message=~djMessage.value(event,node,source,16,tempo);
                if(event.voice==\rockPhysicalGuitar){message[1]=\rockSingleCoilDecay;message=message++[\modalLoss,take]};
                score.add([at+(event.beat*beatSeconds),message]);node=node+1;
            };
        };
        score.add([end,[\n_set,master,\gate,0]]);
        score.add([offset+17.8,[\n_free,group]]);
        voice.value(probe,0.10+(take*4.5),40,1,take,57,3,4,0.055);
    };
    render={|list,name,path,duration|
        var osc=Platform.defaultTempDir+/+(name++".osc");
        list.add([duration,[\c_set,0,0]]);
        Score(list.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:osc,outputFilePath:path,
            sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:duration,
            options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false),
            action:{|code|File.delete(osc);pending=pending-1;failed=failed or:{code!=0};
                ("Decay render "++name++" / exit "++code).postln;
                if(pending==0){if(failed){1.exit}{0.exit}};
            });
    };
    render.value(score,"rock-single-coil-decay",repo+/+"audio/rock-single-coil-decay.wav",36);
    render.value(probe,"rock-single-coil-decay-probe",Platform.defaultTempDir+/+"rock-single-coil-decay-probe.wav",9);
} {|error|error.reportError;1.exit};
)
