// Six short generated songs across EDM, Pop and Rock.
(
var root=thisProcess.nowExecutingPath.dirname,repo=root.dirname.dirname.dirname;
var score=List.new,segments=List.new,node=2000,offset=0,osc;
try {
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;
    (root+/+"recall.scd").load;(root+/+"feedback.scd").load;
    TempoClock.default.tempo=1;
    ~djDefs.do {|def|score.add([0,[\d_recv,def.asBytes]])};
    [\edme,\pop,\rock].do {|channel,i|2.do {|take|
        var seed=[682451,917263,348571,761329,527981,893647][(i*2)+take];
        var tempo=~djDefaultBpm.value(channel),engine,first,mix,group=100+(i*2)+take,source=110+(i*2)+take;
        var decks=[800,801]+((i*2+take)*10),master=900+(i*2)+take,eqNodes,entry=offset+0.10,beatSeconds=60/tempo;
        engine=~makeDJEngine.value(seed,tempo,(channel:channel,hold:true,tension:0.92,autoStutter:false));
        first=engine[\nextBar].value;
        while {[\groove,\hook,\drop].includes(first.decks[0].section).not}{first=engine[\nextBar].value};
        engine[\requestHook].value;
        mix=~djMixSpec.value(channel,engine.controls.rockToneVersion);
        score.add([offset+0.01,[\g_new,group,0,1],[\g_new,source,0,group],
            [\s_new,mix.deck,decks[0],1,group,\in,16,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,tempo],
            [\s_new,mix.deck,decks[1],1,group,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,tempo],
            [\s_new,mix.master,master,1,group,\in,28,\drive,mix.drive]]);
        if(mix.inputEQ ? false){
            eqNodes=decks+4;
            eqNodes.do {|id,deck|score.add([offset+0.02,[\s_new,\rockBluesEQ,id,2,decks[deck],\in,16+(deck*6)]])};
        };
        4.do {|bar|
            var frame=engine[\nextBar].value,at=entry+(bar*4*beatSeconds);
            if(bar==0){
                var plan=frame.decks[0];
                segments.add((channel:channel,seed:seed,start_seconds:offset,bpm:tempo,key:plan.keyName,
                    palette:plan.palette.name,sections:plan.sections.collect {|p|[p.name,p.bars]}));
            };
            frame.automation.do {|point|score.add([at+(point.beat*beatSeconds)]++~djAutomation.value(point,decks,eqNodes))};
            frame.events.do {|event|
                score.add([at+(event.beat*beatSeconds),~djMessage.value(event,node,source,16,tempo)]);node=node+1;
            };
        };
        score.add([entry+(16*beatSeconds),[\n_set,master,\gate,0]]);
        offset=entry+(16*beatSeconds)+4;
        score.add([offset-0.01,[\n_free,group]]);
    }};
    File.use(root+/+"variety-preview.json","w",{|file|
        file.write(~djJSON.value((file:"dj-variety-preview.wav",preview:"dj-variety-preview.m4a",
            seconds:offset,segments:segments.asArray,human_listening_review:"pending"))++"\n");
    });
    osc=Platform.defaultTempDir+/+"dj-variety-preview.osc";
    score.add([offset,[\c_set,0,0]]);
    Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:osc,
        outputFilePath:repo+/+"audio/dj-variety-preview.wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",
        duration:offset,options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false),
        action:{|code|File.delete(osc);code.exit});
} {|error|error.reportError;1.exit};
)
