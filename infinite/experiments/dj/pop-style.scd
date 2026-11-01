// Pop-only record catalog and grammar. No playback or changes to the EDM catalog.
(
~djPopLibrary={ |original|
    var lib=original.copy;
    lib.minor=[[0,5,2,6],[0,3,5,6],[0,6,5,6],[0,5,3,4]];
    lib.major=[[0,4,5,3],[5,3,0,4],[0,5,3,4],[0,3,4,0]];
    lib.durations=[[2,2,2,2]];
    // Existing mixer names: groove=verse, hook/drop=chorus, space/breakdown=bridge.
    lib.forms=[
        [[\intro,8],[\groove,8],[\buildup,4],[\hook,8],[\breakdown,8],[\buildup,4],[\drop,16],[\outro,8]],
        [[\intro,8],[\groove,16],[\buildup,8],[\hook,16],[\space,8],[\buildup,8],[\drop,16],[\outro,8]]
    ];
    lib.palettes=original.palettes.collect { |palette|
        var p=palette.copy;
        p.voices=palette.voices.copy;
        p.voices[\djBass]=\popBass; p.voices[\djHook]=\popLead; p.voices[\djPad]=\popPad;
        p.name="Pop / "++palette.name;
        p.bassName="Offbeat pulse"; p.leadName="Neon saw";
        p;
    };
    lib;
};
~djPopBar={ |plan,local,section,progress,effective,hook,drumBreak,patternID,fill,seed,random,forced=false|
    var events=List.new,part=plan.sections.detect { |p| local<(p.start+p.bars) };
    var partBar=local-part.start,scale=plan.scale,degree=plan.schedule[local].degree;
    var chorus=[\hook,\drop].includes(section) or:{forced};
    var bridge=[\space,\breakdown].includes(section),intro=section==\intro,outro=section==\outro;
    var root=36+plan.key+scale.wrapAt(degree),add,noteAt;
    // Four-bar hook, stored by record ID and repeated verbatim at each chorus.
    // Degree contours stay in the key; chorus melody does not follow random mutations.
    var motifs=[
        [[0,0,4,7,6,4,2,4],[0,2,4,6,8,10,12,14]],
        [[4,4,2,0,2,4,6,4],[0,3,4,6,8,10,12,14]],
        [[0,2,4,4,6,4,2,0],[0,2,4,7,8,10,12,14]],
        [[2,2,4,6,7,6,4,2],[0,2,5,6,8,10,12,14]]
    ];
    var motif=motifs.wrapAt(plan.hookID),phrase=local%4;
    noteAt={ |d,oct=0| 60+plan.key+scale.wrapAt(d)+(12*(d div:7))+oct };
    add={ |lane,role,step,note,length,amp,pan=0,tone=0.6|
        events.add((deck:plan.deck,track:(plan.deck*4)+lane,lane:lane,role:role,
            voice:plan.palette.voices[role] ? role,beat:step*0.25,step:step,swing:0,ghost:false,
            midinote:note,duration:length,amp:amp,pan:pan,color:plan.palette.color,tone:tone,
            drive:0.25,seed:seed+(plan.serial*100003)+(local*101)+events.size));
    };
    plan.breath=false; plan.lowOut=false; plan.cutFrom=4;
    plan.bassTone=0.5; plan.bassDrive=0.25;
    if(bridge.not or:{partBar>=(part.bars-2)}) {
        [0,4,8,12].do { |step| add.value(3,\djKick,step,49,0.36,0.43) };
        if(intro.not or:{progress>0.3}) {
            [4,12].do { |step| add.value(3,\djClap,step,50,0.16,0.14) };
        };
        [2,6,10,14].do { |step| add.value(3,\djHat,step,8500,0.12,0.065,0.2) };
        if(chorus and:{effective.density>0.35}) {
            [0,4,8,12].do { |step| add.value(3,\djHat,step,9000,0.035,0.025,-0.2) };
        };
        if(intro.not or:{progress>0.4}) {
            [2,6,10,14].do { |step,i|
                add.value(0,\djBass,step,root+if(i==3 and:{phrase==3}) {if(patternID.even){12}{0}} {0},0.38,0.22);
            };
        };
    };
    if(intro.not and:{outro.not}) {
        [0,2,4].do { |offset,i|
            add.value(2,\djPad,0,noteAt.value(degree+offset,-12),3.3,
                if(bridge) {0.055} {0.032},(i-1)*0.3,if(bridge){0.35}{0.6});
        };
    };
    if(chorus) {
        motif[1].do { |step,i|
            var d=motif[0][i]+if(phrase==1){2}{0};
            if(phrase==3 and:{i>=6}) {d=[2,0][i-6]};
            add.value(1,\djHook,step,noteAt.value(d),0.30,0.105,-0.08,
                (0.55+(effective.tension*0.25)).clip(0,1));
        };
    } {
        if(outro.not and:{intro.not} and:{partBar%4==0}) {
            [0,6,12].do { |step,i|
                add.value(1,\djHook,step,noteAt.value([0,4,if(plan.mutations.even){2}{0}][i]),0.55,
                    if(bridge){0.045}{0.055},0.08,0.3);
            };
        };
    };
    if(fill or:{section==\buildup and:{partBar>=(part.bars-2)}}) {
        [8,10,12,14,15].do { |step,i| add.value(3,\djSnare,step,50,0.08,0.045+(i*0.012)) };
    };
    if(chorus and:{partBar==0}) {add.value(3,\djImpact,0,60,1.5,0.08)};
    events.asArray.sort { |a,b| a.beat<b.beat };
};
)
