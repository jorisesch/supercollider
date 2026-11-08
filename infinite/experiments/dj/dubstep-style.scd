// London dubstep. Stable two-bar cells, with space reserved for bass and dub returns.
(
~djDubstepLibrary={|original|
    var library=original.copy;
    library.palettes=[
        (id:0,name:"Acid Pressure",bassName:"Sliding acid and mono sub",leadName:"Dub echoes",kitName:"Dry half-step",color:0,
            kick:\djDustKick,snare:\djDustSnare),
        (id:1,name:"Low Signal",bassName:"Sustained sine sub",leadName:"Dub echoes",kitName:"Sparse half-step and rim",color:1,
            kick:\djAnalogKick,snare:\djDubRim),
        (id:2,name:"Broken Dub",bassName:"Syncopated sine sub",leadName:"Dub echoes",kitName:"Swung two-step",color:2,
            kick:\djElectroKick,snare:\djElectroSnare,auditionOnly:true),
        (id:3,name:"Acid Relay",bassName:"Sliding acid and mono sub",leadName:"Dub echoes",kitName:"Straight into half-step",color:0,
            kick:\djDustKick,snare:\djDustSnare,relay:true)
    ];
    library;
};
~djDubstepBar={|plan,local,section,progress,effective,hook,drumBreak,patternID,fill,seed,random,forced=false|
    var events=List.new, palette=plan.palette, part=plan.sections.detect {|p|local<(p.start+p.bars)};
    var phrase=local-part.start, cell=phrase%2, quiet=[\space,\breakdown].includes(section);
    var rhythm=if(palette.relay==true){0}{palette.id};
    var straight=palette.relay==true and:{quiet.not and:{((local-plan.sections[0].bars).max(0)%16)<8}};
    var degree=if(rhythm<2 and:{phrase<8}){0}{plan.schedule[local].degree};
    var scale=plan.scale, pitch, add, kicks, snares, hats, bass, previous;
    var root=34+((plan.key+scale.wrapAt(degree)-34)%12);
    pitch={|offset|
        root+scale.wrapAt(degree+offset)-scale.wrapAt(degree)+(12*((degree+offset) div:7));
    };
    add={|lane,role,voice,step,note,duration,amp,tone=0.4,pan=0|
        var swing=if(step.odd and:{rhythm==2}){0.083}{0};
        var event=(deck:plan.deck,track:(plan.deck*4)+lane,lane:lane,role:role,voice:voice,
            beat:step*0.25+swing,step:step,swing:swing,ghost:false,midinote:note,duration:duration,
            amp:amp,pan:pan,color:palette.color,tone:tone,
            seed:seed+(plan.serial*100003)+(local*101)+events.size);
        events.add(event);
        event;
    };
    kicks=switch(rhythm,
        0,{[[0,10],[0,6,13]][cell]},
        1,{[[0,11],[0,6]][cell]},
        2,{[[0,7,10],[0,6,11]][cell]}
    );
    if(straight){kicks=[0,4,8,12]};
    if(quiet){kicks=[0]};
    kicks.do {|step|add.value(3,\djKick,palette.kick,step,34,0.42,if(step==0){0.34}{0.26})};
    snares=if(straight or:{rhythm==2}){[4,12]}{[8]};
    if(quiet and:{cell==1}){snares=[]};
    snares.do {|step|add.value(3,\djSnare,palette.snare,step,50,0.21,
        if(rhythm==1){0.20}{0.14},0.4,-0.04)};
    hats=switch(rhythm,0,{[[2,6,13],[2,7,14]][cell]},1,{[[6],[3,14]][cell]},2,{[[2,5,9,14],[2,6,11,15]][cell]});
    if(quiet){hats=[]};
    hats.do {|step,i|add.value(3,\djHat,\djHat,step,102,0.08,0.022*[1,0.57,0.78].wrapAt(i),0.4,0.19)};
    if(quiet.not and:{effective.density>0.6 and:{phrase%4==3}}){
        add.value(3,\djHat,\djHat,15,102,0.045,0.012,0.4,-0.16);
    };
    if(fill and:{quiet.not}){add.value(3,\djSnare,palette.snare,15,50,0.08,0.035,0.4,0.11)};
    if(drumBreak.not){
        bass=if(quiet){[[2,0,1.48]]}{
            switch(rhythm,
                0,{[[[1,0,1.08],[11,0,0.78]],[[1,0,0.86],[9,0,1.18]]][cell]},
                1,{[[[1,0,1.65],[11,0,0.69]],[[1,0,1.35],[9,0,1.34]]][cell]},
                2,{[[[1,0,0.65],[7,4,0.32],[10,0,0.50]],[[1,0,0.62],[6,0,0.30],[11,2,0.46],[14,0,0.27]]][cell]}
            )
        };
        bass.do {|hit,i|
            add.value(0,\djBass,\djDubSub,hit[0],pitch.value(hit[1]),hit[2],
                if(i==0){0.31}{0.24},if(quiet){0.16}{0.32});
        };
        if(rhythm==0 and:{quiet.not}){
            // Keep Voltage Leak's original two-bar acid phrase above the sub.
            var acid=[[[1,0],[3,0],[6,7],[7,5],[9,0],[13,2],[15,1]],
                [[1,0],[4,0],[6,4],[9,0],[11,0],[14,1]]][cell];
            var tone=(0.47+(effective.tension*0.34)+if(hook){0.07}{0}).clip(0,0.8);
            previous=root;
            acid.do {|hit|
                var slide=[3,7,15].includes(hit[0]),note=pitch.value(hit[1]);
                var event=add.value(1,\djHook,\djDubAcid,hit[0],note,if(slide){0.17}{0.27},
                    if([1,6,13,14].includes(hit[0])){0.155}{0.096},tone);
                if(slide){event.fromNote=previous;event.glide=0.061};
                previous=note;
            };
        };
        if(phrase%8==3 or:{forced and:{phrase.even}}){
            add.value(2,\eChord,\djDubEcho,if(rhythm==2){14}{10},pitch.value(4)+24,0.14,
                if(rhythm==1){0.072}{0.043},0.43,-0.22);
        };
    };
    events.asArray;
};
)
