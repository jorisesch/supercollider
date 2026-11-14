// Approved fixed songs (listening round 04). Data and bar events only; no playback.
// The offline render and the live engines share this backing, so they cannot drift apart.
(
var root=thisProcess.nowExecutingPath.dirname;
// Round 04 approved every backing and dropped every lead, so the live songs are instrumental.
~djFixedSongs=(root+/+"melodic-round/recipes.scd").load.collect {|spec|
    spec.copy.putAll((instrumental:true))
};
~djFixedSongPitch={|spec,degree,base|base+spec.scale.wrapAt(degree)+(12*(degree div:7))};
// Source bars follow the approved one-minute form: drums 0-3, groove 4-7, hook 8-15,
// space 16-19, build 20-23, hook return 24-31 (the last bar resolves to the tonic).
~djFixedSongBar={|spec,bar,state|
    var events=List.new,add,pitch=~djFixedSongPitch;
    var intro=bar<4,space=bar>=16 and:{bar<20},build=bar>=20 and:{bar<24};
    var hook=(bar>=8 and:{bar<16}) or:{bar>=24};
    var degree=spec.chords.wrapAt((bar-8).max(0) div:2),rootNote,tones,steps,voicing;
    if(bar==31){degree=0};
    rootNote=pitch.value(spec,degree,spec.tonic);
    while {rootNote>47}{rootNote=rootNote-12};
    tones=[0,2,4].collect {|offset|pitch.value(spec,degree+offset,spec.tonic)%12};
    add={|lane,role,voice,step,note,span,gain,tone=0.4,pan=0|
        if(step<0 or:{step>=16} or:{span<=0}){Error("Invalid fixed-song event").throw};
        events.add((lane:lane,role:role,voice:voice,step:step,beat:step*0.25,midinote:note,
            duration:span,amp:gain,tone:tone,pan:pan,drive:0.24,
            seed:spec.seed+(bar*101)+events.size));
    };
    steps=if(space){[0,8]}{spec.kicks.wrapAt(bar)};
    steps.do {|step|add.value(3,\djKick,spec.drum,step,36,0.43,if(step==0){0.43}{0.39})};
    [4,12].do {|step|add.value(3,\djClap,\djAnalogClap,step,50,0.14,0.10,0.4,-0.05)};
    if(space.not){[2,6,10,14].do {|step,i|
        add.value(3,\djHat,\djAnalogHat,step,104,0.09,0.039*[1,0.70,0.88,0.74][i],0.3,0.22);
    }};
    if(bar%8>=4 and:{intro.not and:{space.not}}){
        [7,15].do {|step|add.value(3,\djPerc,\djAnalogPerc,step,60,0.06,0.024,0.3,-0.22)};
    };
    if([7,15,23,31].includes(bar)){
        [13,14,15].do {|step,i|add.value(3,\djSnare,\djAnalogSnare,step,50,0.07,0.024+(i*0.01))};
    };
    if(build and:{bar>=22}){
        [0,2,4,6,8,10,12,14].do {|step|
            add.value(3,\djSnare,\djAnalogSnare,step,50,0.045,0.018+((bar-22)*0.007));
        };
    };
    if(intro.not){
        var bassSteps=if(space){[0,8]}{spec.bassSteps.wrapAt(bar)};
        var rolling=spec.style==\trance and:{bassSteps.size>8};
        bassSteps.do {|step,i|
            var bassNote=rootNote;
            // A single, small answer at a phrase ending, not a new bass tune.
            if(bar%4==3 and:{i==(bassSteps.size-1)} and:{space.not}){bassNote=rootNote+7};
            add.value(0,\djBass,spec.bassVoice,step,bassNote,if(rolling){0.15}{0.33},
                if(rolling){0.15}{0.20},if(space){0.20}{0.34+(if(build){(bar-20)*0.045}{0})});
        };
        // Close, softly voiced chords; each voice moves to its nearest chord tone.
        voicing=tones.collect {|pc,i|
            (50..72).select {|note|note%12==pc}.minItem {|note|(note-state.pads[i]).abs};
        }.sort;
        state.pads=voicing;
        voicing.do {|note,i|add.value(2,\djPad,\popPad,0,note,3.25,
            if(hook){0.020}{0.014},0.16,(i-1)*0.38)};
    };
    (events:events.asArray,tones:tones,degree:degree,rootNote:rootNote);
};
~djFixedSongState={(pads:[55,60,64])};
// Live extended mix: the approved material twice, then an eight-bar groove outro to mix out on.
~djFixedSongLiveForm={|introBars=4|
    var sections=[[\intro,introBars,(0..3)],[\groove,4,(4..7)],[\hook,8,(8..15)],
        [\space,4,(16..19)],[\buildup,4,(20..23)],[\drop,8,(8..15)],
        [\space,4,(16..19)],[\buildup,4,(20..23)],[\drop,8,(24..31)],[\outro,8,(4..7)]];
    var start=0,map=List.new;
    sections=sections.collect {|part|
        part[1].do {|i|map.add(part[2].wrapAt(i))};
        start=start+part[1];
        (name:part[0],start:start-part[1],bars:part[1]);
    };
    (sections:sections,sourceBars:map.asArray,length:start);
};
~djFixedSongLiveBar={|plan,local|
    var spec=plan.fixedSong,bar=plan.fixedSourceBars[local];
    var result=~djFixedSongBar.value(spec,bar,plan.fixedState);
    plan.fixedSourceBar=bar;
    result.events.collect {|event|
        event.putAll((deck:plan.deck,track:(plan.deck*4)+event.lane,swing:0,ghost:false,color:plan.palette.color,
            seed:event.seed+(plan.serial*100003)));
    };
};
)
