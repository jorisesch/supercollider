// Render short song arrangements for blind listening and recipe-based feedback.
// sclang song-audition.scd <output directory>
(
var root=thisProcess.nowExecutingPath.dirname, output=thisProcess.argv.at(0), index=0, render;
var recipes=[
    (id:"A", name:"Wired House reference", channel:\edme, seed:321817, bpm:134, energy:0.30,
        key:7, palette:0, mode:\ionian, cue:\groove, bars:16, rhythm:\original),
    (id:"B", name:"Sidewalk Swing", channel:\edme, seed:685133, bpm:124, energy:0.41,
        key:2, palette:0, mode:\dorian, cue:\groove, bars:20, rhythm:\swing),
    (id:"C", name:"Afterimage", channel:\edme, seed:734093, bpm:138, energy:0.61,
        key:4, palette:2, mode:\aeolian, cue:\lift, bars:20, rhythm:\original, anthem:true),
    (id:"D", name:"Half Light", channel:\edme, seed:107563, bpm:132, energy:0.53,
        key:9, palette:3, mode:\aeolian, cue:\drop, bars:20, rhythm:\halfLift),
    (id:"E", name:"Glass Steps", channel:\edme, seed:610207, bpm:120, energy:0.36,
        key:5, palette:2, mode:\mixolydian, cue:\groove, bars:20, rhythm:\broken),
    (id:"F", name:"Daybreak Signal", channel:\pop, seed:818711, bpm:126, energy:0.51,
        key:0, palette:0, mode:\ionian, cue:\lift, bars:20, rhythm:\original),
    (id:"G", name:"Blue Hour", channel:\pop, seed:591683, bpm:118, energy:0.38,
        key:1, palette:2, mode:\aeolian, cue:\verseHook, bars:20, rhythm:\original),
    (id:"H", name:"Back Alley Relay", channel:\rock, seed:531801, bpm:94, energy:0.43,
        key:9, palette:1, mode:\original, cue:\hook, bars:16, rhythm:\original)
];
var shapeRhythm={|events,plan,bar,rhythm|
    var shaped, kicks, clapSteps, cut, cell=bar%8, swing=0;
    var retime={|role,steps|
        var model=events.detect {|event|event.role==role};
        if(model.notNil){
            steps.do {|step,i|
                var note=model.copy;
                note.step=step;
                note.beat=(step*0.25)+if(step.odd){swing}{0};
                note.amp=note.amp*[1.0,0.91,0.96,0.88].wrapAt(i);
                note.seed=note.seed+(i*31);
                if(note.beat<cut){shaped.add(note)};
            };
        };
    };
    if(rhythm==\original or:{plan.drumBreak or:{[\groove,\hook,\drop].includes(plan.section).not}}){
        events
    }{
        cut=plan.cutFrom;
        switch(rhythm,
            \swing,{
                kicks=if(cell==7){[0,4,8,12,15]}{[0,4,8,12]};
                clapSteps=[4,12]; swing=0.075;
            },
            \halfLift,{
                kicks=if(bar<6){[0,6,12]}{if(bar==6){[0,10]}{[0,4,8,12]}};
                clapSteps=if(bar<7){[8]}{[4,12]};
            },
            \broken,{
                kicks=[[0,6,11],[0,7,10,14]].wrapAt(cell);
                clapSteps=[4,12]; swing=0.03;
            }
        );
        shaped=events.reject {|event|[\djKick,\djClap].includes(event.role)}.as(List);
        retime.value(\djKick,kicks);
        retime.value(\djClap,clapSteps);
        if(rhythm==\halfLift and:{bar==6}){retime.value(\djClap,[10,12,14,15])};
        if(rhythm==\swing){
            shaped.do {|event|
                if([\djHat,\eShaker,\djBass].includes(event.role) and:{event.step.odd}){
                    event.beat=(event.beat+0.035).min(3.95);
                };
            };
        };
        if(rhythm==\halfLift and:{bar<7}){
            shaped.do {|event|
                if(event.lane!=3){
                    event.amp=event.amp*if(bar==6){0.65}{0.82};
                };
            };
        };
        shaped;
    };
};
try {
    if(output.isNil or:{File.exists(output).not}){Error("Provide an existing output directory").throw};
    (root+/+"engine.scd").load;
    (root+/+"instruments.scd").load;
    (root+/+"feedback.scd").load;
    TempoClock.default.tempo=1;
    render={
        var spec=recipes[index], seed, engine, frame, plan, candidate, part, previous, cueAt, localBar;
        var score=List.new, time=0.06, node=2000, decks=[800,801], group=100, source=110, master=900;
        var beatSeconds=60/spec.bpm, mix, eqNodes, osc, file, duration, keyName, sections=List.new;
        var harmony=List.new;
        var energy=spec.energy, settings=(channel:spec.channel, tonality:spec.mode, palette:spec.palette,
            chaos:0.08+(energy*0.34),density:0.28+(energy*0.54),mutation:0.12+(energy*0.36),
            tension:0.02+(energy*0.36),hold:true,autoStutter:false,openWithHook:spec.anthem ? false);
        6000.do {|i|
            if(engine.isNil){
                // A stride avoids adjacent seeds sharing the same first musical choices.
                seed=spec.seed+(i*7919);
                candidate=~makeDJEngine.value(seed,spec.bpm,settings);
                frame=candidate[\nextBar].value;
                plan=frame.decks[0];
                if(plan.key==spec.key and:{(plan.edmAnthem==true)==(spec.anthem ? false)}
                    and:{spec.channel!=\rock or:{plan.keyName.endsWith("blues")}}){
                    part=switch(spec.cue,
                        \lift,{plan.sections.detect {|p,j|
                            var next=plan.sections.at(j+1);
                            p.name==\buildup and:{next.notNil and:{[\hook,\drop].includes(next.name)}}
                        }},
                        \verseHook,{plan.sections.detect {|p,j|
                            var before=if(j>0){plan.sections[j-1]};
                            p.name==\hook and:{before.notNil and:{before.name==\groove}}
                        }},
                        {plan.sections.detect {|p|p.name==spec.cue and:{p.start>=plan.localBar}
                            and:{spec.rhythm!=\halfLift or:{p.bars>=16}}}}
                    );
                    if(part.notNil){
                        cueAt=switch(spec.cue,\verseHook,{part.start-8},\lift,{part.start}, {part.start});
                        if(spec.anthem==true){
                            // The normal opener jumps to the hook. Recreate the same song at its build.
                            candidate=~makeDJEngine.value(seed,spec.bpm,settings.copy.put(\openWithHook,false));
                            frame=candidate[\nextBar].value;
                            plan=frame.decks[0];
                            plan.edmAnthem=true;
                        };
                        if(cueAt>=plan.localBar){engine=candidate};
                    };
                };
            };
        };
        if(engine.isNil){Error("No matching song for "++spec.id).throw};
        while {plan.localBar<cueAt}{frame=engine[\nextBar].value;plan=frame.decks[0]};
        keyName=plan.keyName;
        mix=~djMixSpec.value(spec.channel,engine.controls.rockToneVersion);
        ~djDefs.do {|def|score.add([0,[\d_recv,def.asBytes]])};
        score.add([0.01,[\g_new,group,0,1],[\g_new,source,0,group],
            [\s_new,mix.deck,decks[0],1,group,\in,16,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,spec.bpm],
            [\s_new,mix.deck,decks[1],1,group,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,spec.bpm],
            [\s_new,\djMaster,master,1,group,\in,28,\drive,mix.drive]]);
        if(mix.inputEQ ? false){
            eqNodes=decks+4;
            eqNodes.do {|id,deck|score.add([0.02,[\s_new,\rockBluesEQ,id,2,decks[deck],\in,16+(deck*6)]])};
        };
        spec.bars.do {|bar|
            var current=frame.decks[0], events=shapeRhythm.value(frame.events,current,bar,spec.rhythm);
            if(current.section!=previous){sections.add([bar,current.section]);previous=current.section};
            harmony.add(current.schedule[current.localBar].degree);
            frame.automation.do {|point|score.add([time+(point.beat*beatSeconds)]++~djAutomation.value(point,decks,eqNodes))};
            events.do {|event|
                score.add([time+(event.beat*beatSeconds),~djMessage.value(event,node,source,16,spec.bpm)]);
                node=node+1;
            };
            time=time+(4*beatSeconds);
            frame=engine[\nextBar].value;
        };
        file=spec.id++".wav";osc=output+/+(spec.id++".osc");duration=time+2.3;
        File.use(output+/+(spec.id++".json"),"w",{|f|
            f.write(~djJSON.value(spec.copy.putAll((seed:seed,file:file,keyName:keyName,harmony:harmony.asArray,
                paletteName:plan.palette.name,progression:plan.progression,form:plan.sections.collect {|p|[p.name,p.bars]},
                cueBar:cueAt,sections:sections.asArray,seconds:duration)))++"\n");
        });
        score.add([time,[\n_set,master,\gate,0]]);
        score.add([duration,[\c_set,0,0]]);
        ("Rendering "++spec.id++" "++spec.name++" / seed "++seed++" / "++sections).postln;
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:osc,
            outputFilePath:output+/+file,sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",
            duration:duration,options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
                .numWireBufs_(128).memSize_(65536).loadDefs_(false),
            action:{|code|
                File.delete(osc);
                if(code!=0){code.exit};
                index=index+1;
                if(index>=recipes.size){0.exit}{try {render.value}{|error|error.reportError;1.exit}};
            });
    };
    render.value;
} {|error|error.reportError;1.exit};
)
