// A and B keep the same acid, sub and tempo. B changes only kick and snare placement.
(
var root=thisProcess.nowExecutingPath.dirname, out=thisProcess.argv[0], index=0, render;
var tempo=140, bars=16, seed=140207, recipes=[
    (id:"A",name:"Acid / half-step",palette:0,comparison:false),
    (id:"B",name:"Acid / four-on-the-floor",palette:0,comparison:true),
    (id:"C",name:"Broken Dub / swung two-step",palette:2,comparison:false)
];
try {
    if(out.isNil or:{File.exists(out).not}){Error("Provide an existing output directory").throw};
    (root+/+"engine.scd").load;(root+/+"instruments.scd").load;(root+/+"feedback.scd").load;
    TempoClock.default.tempo=1;
    {
        var found=false;
        while {found.not}{
            var candidate=~makeDJEngine.value(seed,tempo,(channel:\dubstep,hold:true,tonality:\phrygian,palette:0));
            var plan=candidate[\nextBar].value.decks[0];
            var section=plan.sections.detect {|part|plan.localBar<(part.start+part.bars)};
            found=plan.key==6 and:{section.bars>=bars};
            if(found.not){seed=seed+7919};
        };
    }.value;
    render={
        var spec=recipes[index], engine, score=List.new, at=0.1, beat=60/tempo, node=1200, finish, path, grid=List.new;
        engine=~makeDJEngine.value(seed,tempo,(channel:\dubstep,hold:true,tonality:\phrygian,palette:spec.palette));
        ~djDefs.do {|def|score.add([0,[\d_recv,def.asBytes]])};
        score.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],
            [\s_new,\djDeck,800,1,100,\in,16,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,tempo],
            [\s_new,\djDeck,801,1,100,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,tempo],
            [\s_new,\djMaster,900,1,100,\in,28,\drive,~djMixSpec.value(\dubstep).drive]]);
        bars.do {|bar|
            var frame=engine[\nextBar].value,events=frame.events;
            var mainSnares,kicks;
            if(spec.comparison){
                var retime={|role,steps|
                    var model=events.detect {|event|event.role==role};
                    steps.collect {|step|model.copy.put(\step,step).put(\beat,step*0.25)};
                };
                events=events.reject {|event|[\djKick,\djSnare].includes(event.role)}
                    ++ retime.value(\djKick,[0,4,8,12]) ++ retime.value(\djSnare,[4,12]);
            };
            mainSnares=events.select {|e|e.role==\djSnare and:{e.step!=15}}.collect(_.step);
            kicks=events.select {|e|e.role==\djKick}.collect(_.step);
            if(mainSnares!=(if(spec.palette==2 or:{spec.comparison}){[4,12]}{[8]})
                or:{kicks.first!=0 or:{events.any {|event|event.beat<0 or:{event.beat>=4}}}}){
                Error("Unexpected drum grid in "++spec.id++" bar "++bar).throw;
            };
            grid.add((bar:bar,kicks:kicks,snares:mainSnares,
                acid:events.select {|e|e.voice==\djDubAcid}.collect(_.step)));
            frame.automation.do {|point|score.add([at+(point.beat*beat)]++~djAutomation.value(point,[800,801]))};
            events.do {|event|score.add([at+(event.beat*beat),~djMessage.value(event,node,110,16,tempo)]);node=node+1};
            at=at+(4*beat);
        };
        score.add([at,[\n_set,900,\gate,0]]);finish=at+2.3;score.add([finish,[\c_set,0,0]]);
        path=out+/+spec.id;
        File.use(path++".json","w",{|file|
            file.write(~djJSON.value(spec.copy.putAll((seed:seed,channel:\dubstep,bpm:tempo,
                keyName:"F# Phrygian",paletteName:if(spec.palette==0){"Acid and sub"}{"Swung drums and sub"},
                file:spec.id++".wav",seconds:finish,sections:[[0,"groove"]],grid:grid.asArray)))++"\n");
        });
        ("Rendering "++spec.id++" "++spec.name).postln;
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:path++".osc",outputFilePath:path++".wav",
            sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:finish,
            options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
                .numWireBufs_(128).memSize_(65536).loadDefs_(false),
            action:{|code|
                File.delete(path++".osc");
                if(code!=0){code.exit};
                index=index+1;
                if(index>=recipes.size){0.exit}{try {render.value}{|error|error.reportError;1.exit}};
            });
    };
    render.value;
} {|error|error.reportError;1.exit};
)
