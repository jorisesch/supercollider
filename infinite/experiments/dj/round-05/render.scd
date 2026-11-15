// Listening round 05. Offline only; the live generator is unchanged.
// sclang render.scd <output-dir> form   EDM builds, hooks and forms on one approved song style
// sclang render.scd <output-dir> rock   Rock guitar tone and playing comparisons
// sclang render.scd <output-dir> legato Hammer-ons and pull-offs in the Rock lead
// sclang render.scd <output-dir> fx     Wah, overdrive boost, tremolo and delay on the Rock guitar
(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname,output=thisProcess.argv.at(0);
var study=(thisProcess.argv.at(1) ? "form").asSymbol,clips,index=0,render,record,options;
var formBars,rockScore;
try {
    if(output.isNil or:{File.exists(output).not}){Error("Provide an existing output directory").throw};
    (dj+/+"engine.scd").load;(dj+/+"instruments.scd").load;(dj+/+"feedback.scd").load;
    TempoClock.default.tempo=1;
    options=ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
        .numWireBufs_(256).memSize_(65536).loadDefs_(false);
    record={|score,path,duration,meta|
        File.use(path++".json","w",{|file|file.write(~djJSON.value(meta)++"\n")});
        ("Rendering "++meta.id++" / "++meta.name++" / "++duration.round(0.1)++" s").postln;
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(
            oscFilePath:path++".osc",outputFilePath:path++".wav",sampleRate:48000,
            headerFormat:"WAV",sampleFormat:"int24",duration:duration,options:options,
            action:{|code|
                File.delete(path++".osc");if(code!=0){code.exit};index=index+1;
                if(index<clips.size){try{render.value}{|error|error.reportError;1.exit}}{0.exit};
            });
    };
    // ---- EDM form study: Violet Afterburn with the approved soft keys.
    // Each part: [section, bars, options]. Harmony starts with the first pitched part.
    formBars={|spec,parts,lead,answer|
        var events=List.new,state=~djSongStyleState.value,bar=0,harmony=0,total=parts.collect {|p|p[1]}.sum;
        parts.do {|part|
            var section=part[0],bars=part[1],flags=part[2] ? ();
            bars.do {|partBar|
                var degree=if(bar==(total-1)){0}{spec.chords.wrapAt(harmony div:2)};
                var ctx=(section:section,local:bar,partBar:partBar,partBars:bars,degree:degree,
                    scale:spec.scale,tonic:spec.tonic,hook:section==\hook,fill:false,patternID:0,
                    lead:lead,final:bar==(total-1),returning:flags[\returning]==true,
                    bare:flags[\bare]==true,bigBuild:flags[\bigBuild]==true,tease:flags[\tease]==true,
                    stabs:flags[\stabs]==true,drop:(flags[\drop]==true) and:{partBar==0},
                    lift:(flags[\lift]==true) and:{partBar>=(flags[\liftFrom] ? 0)},
                    answer:if((flags[\answer]==true) and:{partBar>=(flags[\answerFrom] ? 0)}){answer});
                ~djSongStyleBar.value(spec,ctx,state).events.do {|event|
                    events.add(event.putAll((bar:bar,deck:0,color:0)));
                };
                if(section!=\intro and:{flags[\static]!=true}){harmony=harmony+1};
                bar=bar+1;
            };
        };
        (events:events,bars:total);
    };
    rockScore={|clip|
        var score=List.new,time=0.1,tempo=102,node=2000,saved=~djRockPlayers.deepCopy,engine,mix;
        var decks=[800,801],sources=[110,111],eqNodes;
        ~djRockPlayers=~djRockPlayers.deepCopy;
        clip.player.keysValuesDo {|key,value|~djRockPlayers[clip.palette].put(key,value)};
        // A clip states its own pedals; the per-song pedalboard choice is switched off.
        ~djRockPlayers[clip.palette].put(\boards,[()]);
        engine=~makeDJEngine.value(clip.seed,tempo,(channel:\rock,palette:clip.palette,hold:true,tonality:\aeolian));
        mix=~djMixSpec.value(\rock,engine.controls.rockToneVersion);
        ~djDefs.do {|def|score.add([0,[\d_recv,def.asBytes]])};
        score.add([0.01,[\g_new,100,0,1],[\g_new,sources[0],0,100],[\g_new,sources[1],0,100],
            [\s_new,mix.deck,decks[0],1,100,\in,16,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,tempo],
            [\s_new,mix.deck,decks[1],1,100,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,tempo],
            [\s_new,mix.master,900,1,100,\in,28,\drive,mix.drive]]);
        if(mix.inputEQ==true){
            eqNodes=[810,811];
            eqNodes.do {|id,i|score.add([0.011,[\s_new,\rockBluesEQ,id,2,decks[i],\in,16+(i*6)]])};
        };
        clip.bars.do {|bar|
            var frame,actions=List.new,previous=0;
            if(clip.soloBars.includes(bar)){engine[\requestHook].value};
            frame=engine[\nextBar].value;
            frame.automation.do {|point|actions.add((beat:point.beat,automation:point))};
            frame.events.do {|event|
                if(event.lane==1){
                    clip.leadNotes=(clip[\leadNotes] ? 0)+1;
                    if((event[\articulation] ? 0)==2){clip.hammers=(clip[\hammers] ? 0)+1};
                    if((event[\articulation] ? 0)==3){clip.pulls=(clip[\pulls] ? 0)+1};
                    if((event[\articulation] ? 0)==1){clip.slides=(clip[\slides] ? 0)+1};
                };
                actions.add((beat:event.beat,note:event));
            };
            actions=actions.sort {|a,b|if(a.beat==b.beat){a[\automation].notNil and:{b[\automation].isNil}}{a.beat<b.beat}};
            actions.do {|action|
                time=time+((action.beat-previous)*60/tempo);previous=action.beat;
                if(action[\automation].notNil){
                    tempo=action.automation.bpm;score.add([time]++~djAutomation.value(action.automation,decks,eqNodes));
                }{
                    score.add([time,~djMessage.value(action.note,node,sources[action.note.deck],16,tempo)]);node=node+1;
                };
            };
            time=time+((4-previous)*60/tempo);
            clip.keyName=frame.decks.detect(_.notNil).keyName;
        };
        ~djRockPlayers=saved;
        score.add([time,[\n_set,900,\gate,0]]);score.add([time+4,[\c_set,0,0]]);
        (score:score,duration:time+4);
    };
    if(study==\legato){
        clips=[
            (id:"A",name:"Rook, picked and slid as today",palette:0,player:()),
            (id:"B",name:"Rook, some hammer-ons and pull-offs",palette:0,player:(legatoChance:0.5)),
            (id:"C",name:"Rook, as many hammer-ons and pull-offs as the phrase allows",palette:0,player:(legatoChance:1,slideChance:0)),
            (id:"D",name:"June, some hammer-ons and pull-offs",palette:1,player:(legatoChance:0.5)),
            (id:"E",name:"Flint, some hammer-ons and pull-offs",palette:2,player:(legatoChance:0.5))
        ];
        render={
            var clip=clips[index].putAll((seed:2600,bars:24,soloBars:[4,8,14,18])),built=rockScore.value(clip);
            ("  lead notes "++(clip[\leadNotes] ? 0)++" / hammer-ons "++(clip[\hammers] ? 0)++" / pull-offs "++(clip[\pulls] ? 0)++" / slides "++(clip[\slides] ? 0)).postln;
            record.value(built.score,output+/+clip.id,built.duration,(id:clip.id,file:clip.id++".wav",name:clip.name,
                channel:\rock,bpm:102,keyName:clip.keyName,bars:clip.bars,seconds:built.duration,
                paletteName:["Garage","Jangle","Fuzz room"][clip.palette]++" / "++(clip[\hammers] ? 0)++" hammer-ons, "++(clip[\pulls] ? 0)++" pull-offs",
                sections:[[4,"solo"],[8,"solo"],[14,"solo"],[18,"solo"]],study:"legato"));
        };
    };
    if(study==\fx){
        clips=[
            (id:"A",name:"Rook, no extra pedals (today)",palette:0,player:(),fx:"none"),
            (id:"B",name:"Rook, wah on the solos",palette:0,player:(wah:0.9),fx:"wah"),
            (id:"C",name:"Rook, overdrive boost on the solos",palette:0,player:(boost:0.8),fx:"boost"),
            (id:"D",name:"Rook, wah, boost and echo on the solos",palette:0,player:(wah:0.9,boost:0.6,soloDelay:0.32,delayBeats:0.5),fx:"wah, boost, eighth-note delay"),
            (id:"E",name:"Rook, slapback echo throughout",palette:0,player:(delay:0.30,delayBeats:0.25),fx:"slapback"),
            (id:"F",name:"June, tremolo throughout",palette:1,player:(tremolo:0.65,tremoloRate:3),fx:"tremolo"),
            (id:"G",name:"June, dotted-eighth echo throughout",palette:1,player:(delay:0.30,delayBeats:0.75),fx:"delay"),
            (id:"H",name:"Flint, wah and boost on the solos",palette:2,player:(wah:0.9,boost:0.6),fx:"wah, boost")
        ];
        render={
            var clip=clips[index].putAll((seed:2600,bars:24,soloBars:[4,8,14,18])),built=rockScore.value(clip);
            record.value(built.score,output+/+clip.id,built.duration,(id:clip.id,file:clip.id++".wav",name:clip.name,
                channel:\rock,bpm:102,keyName:clip.keyName,bars:clip.bars,seconds:built.duration,
                paletteName:["Garage","Jangle","Fuzz room"][clip.palette]++" / "++clip.fx,
                sections:[[4,"solo"],[8,"solo"],[14,"solo"],[18,"solo"]],study:"fx"));
        };
    };
    if(study==\form){
        var spec=~djSongStyles.detect {|s|s.id=="B"};
        var keys=~djSongStyleLeadChoices[0],pluck=~djSongStyleLeadChoices[1];
        clips=[
            (id:"A",name:"Reference: the approved arrangement",
                parts:[[\intro,4],[\groove,4,(static:true)],[\hook,8],[\space,4],[\build,4],[\hook,8,(returning:true)]],
                sections:[[0,"drums"],[4,"bass groove"],[8,"hook"],[16,"space"],[20,"build"],[24,"hook returns"]]),
            (id:"B",name:"Bigger build: riser, roll, dropout, impact",
                parts:[[\intro,4],[\groove,4,(static:true)],[\hook,8],[\space,4],[\build,8,(bigBuild:true)],[\hook,8,(returning:true,drop:true)]],
                sections:[[0,"drums"],[4,"bass groove"],[8,"hook"],[16,"space"],[20,"8-bar build"],[28,"drop"]]),
            (id:"C",name:"Hook payoff: teased first, full with answers after",
                parts:[[\intro,4],[\groove,4,(static:true)],[\hook,8,(tease:true)],[\space,4],[\build,4],
                    [\hook,8,(returning:true,answer:true,stabs:true)]],
                sections:[[0,"drums"],[4,"bass groove"],[8,"hook teased"],[16,"space"],[20,"build"],[24,"full hook with answers and stabs"]]),
            (id:"D",name:"New form: breakdown, big build, double drop",
                parts:[[\intro,4],[\groove,8],[\space,8,(bare:true)],[\build,8,(bigBuild:true)],
                    [\hook,16,(returning:true,drop:true,stabs:true,answer:true,answerFrom:8,lift:true,liftFrom:8)]],
                sections:[[0,"drums"],[4,"groove, no melody yet"],[12,"breakdown: melody over chords"],[20,"8-bar build"],[28,"drop"],[36,"second drop adds answers and shaker"]])
        ];
        render={
            var clip=clips[index],built=formBars.value(spec,clip.parts,keys,pluck),score=List.new;
            var beat=60/spec.bpm,node=2000,mix=~djMixSpec.value(spec.channel);
            var duration=0.11+(built.bars*4*beat)+4;
            ~djDefs.do {|def|score.add([0,[\d_recv,def.asBytes]])};
            score.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],
                [\s_new,mix.deck,800,1,100,\in,16,\out,28,\bpm,spec.bpm,
                    \musicGain,1,\bassGain,1,\drumsGain,1,\fxEcho,0.045,\fxDelay,0.75,\fxReverb,0.11],
                [\s_new,mix.master,900,1,100,\in,28,\drive,mix.drive]]);
            built.events.do {|event|
                if(event.lane<3 and:{spec.scale.includes((event.midinote-spec.tonic)%12).not}){
                    Error("A pitched note left the scale").throw;
                };
                if(event.lane==1 and:{event.midinote<57 or:{event.midinote>83}}){Error("Lead left its range").throw};
                score.add([0.11+((event.bar*4+event.beat)*beat),~djMessage.value(event,node,110,16,spec.bpm)]);
                node=node+1;
            };
            score.add([duration-4,[\n_set,900,\gate,0]]);score.add([duration,[\c_set,0,0]]);
            record.value(score,output+/+clip.id,duration,(id:clip.id,file:clip.id++".wav",name:clip.name,
                channel:spec.channel,bpm:spec.bpm,keyName:spec.keyName,bars:built.bars,seconds:duration,
                paletteName:"Violet Afterburn / soft keys",sections:clip.sections,study:"form"));
        };
    };
    if(study==\rock){
        var rook=(drive:0.32*0.45,driveMin:0.28*0.45,driveMax:0.41*0.45,pedal:1,comp:0.35);
        var sparse=(rhythm:[[0,8],[0,6,8]],chorus:[[0,6,8,14],[0,6,8,12]],mute:0.30);
        clips=[
            (id:"A",name:"Rook, as it plays today",palette:0,player:()),
            (id:"B",name:"Rook, cleaner amp (less than half the drive)",palette:0,player:rook),
            (id:"C",name:"Rook, sparser ringing chords",palette:0,player:sparse),
            (id:"D",name:"Rook, cleaner amp and sparser chords",palette:0,player:rook.copy.putAll(sparse)),
            (id:"E",name:"June, as she plays today (jangle)",palette:1,player:()),
            (id:"F",name:"Flint, as he plays today (fuzz)",palette:2,player:())
        ];
        render={
            var clip=clips[index].putAll((seed:2600,bars:24,soloBars:[12])),built=rockScore.value(clip);
            record.value(built.score,output+/+clip.id,built.duration,(id:clip.id,file:clip.id++".wav",name:clip.name,
                channel:\rock,bpm:102,keyName:clip.keyName,bars:clip.bars,seconds:built.duration,
                paletteName:["Garage","Jangle","Fuzz room"][clip.palette],
                sections:[[0,"band"],[12,"guitar solo requested"],[16,"band"]],study:"rock"));
        };
    };
    render.value;
} {|error|error.reportError;1.exit};
)
