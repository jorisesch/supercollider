// Four modal auditions per channel. Each gets its own mixer and full fade/tail.
(
var root=thisProcess.nowExecutingPath.dirname,repo=root.dirname.dirname.dirname,pending=2,failed=false;
var modes=[\aeolian,\dorian,\phrygian,\mixolydian];
try {
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;
    TempoClock.default.tempo=1;
    [\edme,\pop].do {|channel|
        var bpm=if(channel==\pop){138}{128},score=List.new,node=1000,start=0.1;
        var name=if(channel==\pop){"pop-modes"}{"edm-modes"},duration,osc;
        ~djDefs.do {|def|score.add([0,[\d_recv,def.asBytes]])};
        modes.do {|mode,index|
            var engine=~makeDJEngine.value(2600,bpm,(channel:channel,modalPolicy:\fixed,tonality:mode,
                melody:\pentatonic,hold:true,autoStutter:false));
            var group=100+(index*10),sources=[101,102]+(index*10),decks=[800,801]+(index*10),master=900+index;
            var end=start+(32*60/bpm);
            if(channel==\pop){20.do {engine[\nextBar].value}}{8.do {engine[\nextBar].value}};
            score.add([start-0.03,[\g_new,group,0,1],
                [\g_new,sources[0],0,group],[\g_new,sources[1],0,group],
                [\s_new,\djDeck,decks[0],1,group,\in,16,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,bpm],
                [\s_new,\djDeck,decks[1],1,group,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,bpm],
                [\s_new,\djMaster,master,1,group,\in,28]]);
            8.do {|bar|
                var frame=engine[\nextBar].value;
                frame.automation.do {|point|
                    score.add([start+((bar*4+point.beat)*60/bpm)]++~djAutomation.value(point,decks));
                };
                frame.events.do {|event|
                    var plan=frame.decks[event.deck],pc=(event.midinote-plan.key)%12;
                    if(event.lane<3 and:{event.role!=\eTurnaround} and:{plan.scale.includes(pc).not}){
                        Error("Modal render includes an out-of-mode note").throw;
                    };
                    score.add([start+((bar*4+event.beat)*60/bpm),
                        ~djMessage.value(event,node,sources[event.deck],16,bpm)]);node=node+1;
                };
            };
            score.add([end,[\n_set,master,\gate,0]]);
            score.add([end+3.9,[\n_free,group]]);
            start=end+4;
        };
        duration=start;score.add([duration,[\c_set,0,0]]);
        osc=Platform.defaultTempDir+/+(name++".osc");
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(
            oscFilePath:osc,outputFilePath:repo+/+"audio"+/+(name++".wav"),
            sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:duration,
            options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
                .numWireBufs_(128).memSize_(65536).loadDefs_(false),
            action:{|code|File.delete(osc);failed=failed or:{code!=0};pending=pending-1;
                ("Completed "++name++" / exit "++code).postln;
                if(pending==0){if(failed){1.exit}{0.exit}};
            });
    };
} {|error|error.reportError;1.exit};
)
