// Rock record catalog and phrasing. Pure events; shared DJ transport and recall.
(
~djRockSoloPlan={|plan,seed|
    var rng=((seed.abs*65537)+((plan.serial+1).squared*104729)+((plan.hookID+1)*13007)+4435761)%2147483646+1;
    var random,parts,bars,part,slots,start,result;
    random={rng=(rng*48271)%2147483647;rng/2147483647};
    if(random.value<0.52){
        bars=if(random.value<0.35){8}{4};
        parts=plan.sections.select {|p|[\hook,\drop].includes(p.name) and:{p.bars>=bars}};
        // Favor the later release, after the backing has established its identity.
        parts=parts++parts.select {|p|p.name==\drop};
        part=parts[(random.value*parts.size).floor.asInteger];
        slots=(0,4..(part.bars-bars));start=part.start+slots[(random.value*slots.size).floor.asInteger];
        result=(start:start,bars:bars);
    };
    result;
};
~djRockCadence={|event,plan,degree,choice=0|
    var tones=[0,2,4].collect {|offset|plan.scale.wrapAt(degree+offset)},pc,candidates;
    pc=tones[choice];candidates=(60..84).select {|note|((note-plan.key)%12)==pc};
    event.midinote=candidates.sort {|a,b|(a-event.midinote).abs<(b-event.midinote).abs}.first;
    event.rockLanding=true;event.chordTones=tones;event.chordRoot=tones[0];
    event.landingChordDegree=degree;event.landingOffset=[0,2,4][choice];event.slap=0;
    event;
};
~djRockLibrary={ |original|
    var lib=original.copy;
    lib.minor=[
        [0,0,2,3],[0,6,3,0],[0,2,5,6],[0,3,6,0],
        [0,5,3,6],[0,2,3,0],[0,6,5,3],[0,3,2,6],
        [5,3,0,6],[2,6,3,0],[0,5,6,0],[3,0,6,0]
    ];
    lib.major=[
        [0,6,3,0],[0,3,4,0],[0,5,3,4],[0,3,0,4],
        [0,4,5,3],[5,3,0,4],[0,1,3,4],[3,0,4,0],
        [0,5,4,3],[0,4,3,0],[5,0,3,4],[3,4,0,0]
    ];
    lib.durations=[[1,1,1,1],[2,2,2,2],[2,1,1,4],[1,1,2,4],[4,2,1,1]];
    lib.forms=[
        [[\intro,4],[\groove,8],[\hook,8],[\space,4],[\buildup,4],[\drop,16],[\outro,8]],
        [[\intro,4],[\groove,16],[\hook,8],[\breakdown,8],[\buildup,4],[\drop,16],[\outro,8]],
        [[\intro,8],[\groove,8],[\hook,16],[\space,8],[\buildup,4],[\drop,16],[\outro,8]]
    ];
    lib.palettes=[
        (id:0,name:"Garage",bassName:"Picked bass",leadName:"Double-tracked crunch",kitName:"Room kit",color:0,drive:0.46,mute:0.62),
        (id:1,name:"Jangle",bassName:"Round bass",leadName:"Clean strings",kitName:"Dry kit",color:1,drive:0.12,mute:0.20),
        (id:2,name:"Fuzz room",bassName:"Grit bass",leadName:"Fuzz and clean pair",kitName:"Heavy kit",color:2,drive:0.58,mute:0.42)
    ];
    lib;
};
~djRockBar={ |plan,local,section,progress,effective,hook,drumBreak,patternID,fill,seed,random,forced=false|
    var events=List.new,part=plan.sections.detect {|p|local<(p.start+p.bars)},partBar=local-part.start;
    var degree=plan.schedule[local].degree,scale=plan.scale,palette=plan.palette;
    var chorus=hook or:{forced},quiet=[\space,\breakdown].includes(section),intro=section==\intro;
    var ending=section==\outro,build=section==\buildup,root,fifth,third,notes,steps,bassSteps,kicks;
    var noteAt,add,strum,detailState=(seed.abs+(plan.serial*104729)+(local*997)+13007)%2147483646+1,detail;
    var mute=(palette.mute+if(chorus){-0.24}{0.08}).clip(0.08,0.86);
    var drive=(palette.drive+if(chorus){0.10}{0}-if(quiet){0.22}{0}).clip(0,0.8);
    var oldReply,solo=plan[\rockSoloPlan],active=false,age=0,bars=0,kind=\none,final=false;
    detail={detailState=(detailState*48271)%2147483647;detailState/2147483647};
    noteAt={|d,base=36|base+plan.key+scale.wrapAt(d)+(12*(d div:7))};
    root=noteAt.value(degree);while {root<40}{root=root+12};while {root>51}{root=root-12};
    fifth=root+(noteAt.value(degree+4)-noteAt.value(degree));
    third=root+(noteAt.value(degree+2)-noteAt.value(degree));
    notes=if(palette.id==1 or:{quiet}){[root,fifth,third+12]}{[root,fifth,root+12]};
    plan.currentProgression=plan.harmony[plan.schedule[local].harmonyRole];
    plan.breath=false;plan.lowOut=false;plan.cutFrom=4;plan.bassTone=0.5;plan.bassDrive=drive*0.4;
    add={|lane,role,voice,beat,note,length,amp,pan=0|
        var human=(detail.value-0.5)*0.012;
        events.add((deck:plan.deck,track:(plan.deck*4)+lane,lane:lane,role:role,voice:voice,
            beat:(beat+human).clip(0,3.95),step:(beat*4).round.asInteger,swing:human,ghost:false,
            midinote:note,duration:length,amp:amp*(0.93+(detail.value*0.14)),pan:pan,
            color:palette.color,tone:(0.42+(effective.tension*0.22)).clip(0,1),drive:drive,
            mute:mute,fuzz:0,wah:0,slap:0,
            seed:seed+(plan.serial*100003)+(local*101)+events.size));
    };
    strum={|beat,length,level|
        [-0.62,0.62].do {|pan,side|
            notes.do {|note,i|
                var event;
                add.value(2,\rockChord,\rockGuitar,beat+(i*0.014)+(side*0.017),note,length,
                    level/notes.size.sqrt,pan);
                event=events.last;
                // Fuzz is an answer on one guitar; its partner keeps the attack clear.
                if(palette.id==2 and:{chorus} and:{partBar%8>=4} and:{side==0}){event.fuzz=0.48};
                if(palette.id==1 and:{chorus} and:{partBar%4==3} and:{beat>=3}){event.slap=0.28};
                if(quiet){event.mute=0.10;event.drive=0.06};
            };
        };
    };
    steps=case {quiet}{[0,8]} {intro and:{progress<0.4}}{[0,8]}
        {chorus}{[[0,3,6,8,11,14],[0,2,6,8,10,14],[0,4,7,8,12,14]].wrapAt(plan.variation.rhythm)}
        {true}{[[0,2,4,6,8,10,12,14],[0,3,6,8,10,14],[0,2,6,8,11,14],[0,4,6,8,12,14]].wrapAt(patternID)};
    if(effective.density<0.3){steps=[0,6,8,14]};
    if(quiet){steps=[0,8]};
    if(drumBreak.not){
        steps.do {|step,i|
            var next=steps.at(i+1) ? 16;
            var length=if(quiet){1.55}{if(chorus){((next-step)*0.25-0.04).clip(0.16,0.85)}{0.17+(if(step%4==0){0.10}{0})}};
            strum.value(step*0.25,length,if(quiet){0.058}{if(chorus){0.105}{0.090}}*if(step%4==0){1}{0.78});
        };
        bassSteps=if(quiet){[0,8]}{steps};
        bassSteps.do {|step,i|
            var note=root-12,next=bassSteps.at(i+1) ? 16;
            if(partBar%4==3 and:{i==(bassSteps.size-1)} and:{quiet.not}){note=fifth-12};
            add.value(0,\djBass,\rockBass,step*0.25,note,
                if(quiet){1.5}{((next-step)*0.25-0.06).clip(0.12,0.72)},if(quiet){0.16}{0.23});
        };
        // Short scale-based replies leave most of the backing open.
        if(chorus and:{partBar%8==7} and:{effective.density>0.4}){
            var contour=if(plan.hookID.even){[0,1,3,4]}{[2,4,5,0]};
            [8,10,12,14].do {|step,i|
                var note=60+plan.key+scale.wrapAt(contour.wrapAt(i+plan.hookID));
                add.value(1,\djHook,\rockGuitar,step*0.25,note,if(i==3){0.7}{0.3},0.075,0.08);
                events.last.mute=0.04;events.last.drive=0.38;
                if(palette.id==1){events.last.wah=0.4};
            };
        };
    };
    kicks=case {quiet}{[0,8]} {build}{if(progress>0.5){[0,4,8,12]}{[0,8]}}
        {true}{[[0,6,8],[0,7,8,10],[0,3,8,11],[0,6,8,14]].wrapAt(plan.variation.rhythm+(partBar%2))};
    kicks.do {|step|add.value(3,\djKick,\rockKick,step*0.25,48,0.3,if(step==0){0.42}{0.34})};
    if(intro.not or:{progress>0.3}){
        [4,12].do {|step|add.value(3,\djSnare,\rockSnare,(step*0.25)+0.018,50,0.2,if(quiet){0.14}{0.26},-0.06)};
    };
    8.do {|i|
        var open=chorus and:{i==7} and:{partBar%4==3},amp=if(i.even){0.055}{0.035};
        if(fill.not or:{i<6}){
            add.value(3,\djHat,\rockHat,i*0.5,100,if(open){0.23}{0.055},amp*if(quiet){0.6}{1},0.25);
        };
    };
    if(effective.density>0.5 and:{partBar.odd} and:{quiet.not} and:{fill.not}){
        add.value(3,\djSnare,\rockSnare,2.77,50,0.08,0.045,-0.06);events.last.ghost=true;
    };
    if(fill or:{build and:{partBar==(part.bars-1)}}){
        [12,13,14,15].do {|step,i|
            add.value(3,\rockFill,if(i<2){\rockSnare}{\rockTom},step*0.25,
                [50,50,50,43][i],0.24,0.14+(i*0.018),(i-1)*0.15);
        };
    };
    if(partBar==0 and:{quiet.not} and:{intro.not} and:{ending.not}){
        add.value(3,\rockCrash,\rockCrash,0,90,1.8,0.075,-0.25);
    };
    if((plan[\rockLeadVersion] ? 0)>0){
        // Generate the old reply before the kit as usual, then replace the lead.
        // This keeps backing seeds, timing and drum velocities independent of solos.
        oldReply=events.select {|e|e.role==\djHook};events=events.reject {|e|e.role==\djHook}.as(List);
        if(forced){
            active=true;bars=4;age=4-plan.forcedHookRemaining;kind=\riff;
            plan.rockAutomaticSkipped=true;
        }{
            if(solo.notNil and:{(plan[\rockAutomaticSkipped] ? false).not}
                and:{local>=solo.start} and:{local<(solo.start+solo.bars)}){
                active=true;bars=solo.bars;age=local-solo.start;kind=\solo;
            };
        };
        if(plan[\rockLeaving] ? false){
            active=false;
            if(((plan[\rockSoloWasActive] ? false) or:{forced}) and:{(plan[\rockExitCadenced] ? false).not}){
                active=true;bars=1;age=0;kind=\cadence;plan.rockExitCadenced=true;
            };
        };
        final=active and:{age==(bars-1)};
        plan.rockSoloActive=active;plan.rockSoloAge=age;plan.rockSoloBars=bars;plan.rockSoloKind=kind;
        plan.rockSoloWasActive=active and:{final.not};
        if(active){
            var rhythm,contour;
            rhythm=if(final){[0,2,4,6,8]}{
                [[0,2,4,7,8,10,12,14],[0,3,6,8,11],[0,2,4,6,8,10,13,14],[0,4,6,9,12,14]]
                    .wrapAt(age+plan.variation.rhythm)
            };
            if(kind==\cadence){rhythm=[0,2,4]};
            if(effective.density<0.3 and:{final.not}){rhythm=[0,4,8,12]};
            contour=[[0,2,4,2,0,1,3,2],[2,4,5,4,2,0],[4,3,2,1,2,0],[2,1,0,2,4,0]]
                .wrapAt(age+plan.hookID);
            events.do {|e|if(e.role==\rockChord){e.amp=e.amp*0.82}};
            rhythm.do {|step,i|
                var offset=contour.wrapAt(i),note,length,next=rhythm.at(i+1) ? 16,event,last=final and:{i==(rhythm.size-1)};
                if(step%4==0){offset=[0,2,4].wrapAt(i+age)};
                note=noteAt.value(degree+offset,60)+if(age>=4){12}{0};
                while {note>84}{note=note-12};while {note<60}{note=note+12};
                length=if(last){1.55}{(((next-step)*0.25)-0.12).clip(0.12,0.72).min(4-(step*0.25)-0.25)};
                add.value(1,\djHook,\rockGuitar,step*0.25,note,length,if(step%4==0){0.088}{0.073},0.08);
                event=events.last;event.mute=0.025;event.drive=(0.36+(effective.tension*0.18)).clip(0,0.65);
                event.rockPhrase=kind;event.rockPhraseAge=age;event.rockPhraseBars=bars;
                if(palette.id==1 and:{age.odd}){event.wah=0.25};
                if(palette.id==2 and:{age%4>=2}){event.fuzz=0.20};
                if(last){~djRockCadence.value(event,plan,degree,
                    if((plan.hookID+plan.serial+local)%5==0){1+(plan.hookID%2)}{0})};
            };
        }{
            if((plan[\rockLeaving] ? false).not){
                oldReply.do {|e,i|
                    e.beat=e.beat-1;e.step=e.step-4;e.rockPhrase=\reply;e.rockPhraseAge=0;e.rockPhraseBars=1;
                    if(i==(oldReply.size-1)){
                        e.duration=1.0;~djRockCadence.value(e,plan,degree,
                            if((plan.hookID+local)%5==0){1+(plan.hookID%2)}{0});
                    };
                    events.add(e);
                };
            };
        };
    };
    events.asArray.sort {|a,b|a.beat<b.beat};
};
)
