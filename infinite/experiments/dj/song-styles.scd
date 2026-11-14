// Song styles from listening round 04. Data and bar events only; no playback.
// Each approved song is a style: its drums, bass, kit and chord bed become a grammar
// the live engines play in any generated key, mode, progression, form and tempo.
// The offline renderer drives the same grammar with the approved arrangement.
(
var root=thisProcess.nowExecutingPath.dirname;
var bassNames=(djReeseBass:"Reese bass",edmAnthemBass:"Rolling sub",djAcidBass:"Acid bass",popBass:"Offbeat pulse");
var kitNames=(djAnalogKick:"Analog punch",djDustKick:"Dust kick",djKick:"Tight house");
~djSongStyles=(root+/+"melodic-round/recipes.scd").load;
// Round 04 dropped every original lead. Rounds 04-neon and 04-leads approved soft keys
// and clean pluck on every style, and the no-lead versions too.
~djSongStyleLeadChoices=[(voice:\neonSoftKeys,amp:0.085,tone:0.3,name:"Soft keys"),
    (voice:\neonCleanPluck,amp:0.095,tone:0.3,name:"Clean pluck")];
// Night Signal with soft keys "can also work without groove": its breakdowns drop
// drums and bass, leaving the melody over the chord bed.
~djSongStyleBareSpace=(C:\neonSoftKeys);
// Ensembles appended to a channel's palettes; the engine rotates them like any other.
~djSongStylePalettes={|channel,firstID=0|
    ~djSongStyles.select {|spec|spec.channel==channel}.collect {|spec,i|
        (id:firstID+i,name:spec.name,bassName:bassNames[spec.bassVoice] ? spec.bassVoice.asString,
            leadName:"Clean lead",kitName:kitNames[spec.drum] ? spec.drum.asString,color:i%4,songStyle:spec,
            voices:(djKick:spec.drum,djClap:\djAnalogClap,djHat:\djAnalogHat,djPerc:\djAnalogPerc,
                djSnare:\djAnalogSnare,djBass:spec.bassVoice,djPad:\popPad));
    };
};
~djSongStyleState={(pads:[55,60,64])};
// ctx: section (\intro \groove \hook \space \build), local, partBar, partBars, degree,
// scale, tonic, hook, fill, patternID; optional lead (voice, amp, tone), returning, final,
// bare (a space section with no drums or bass).
~djSongStyleBar={|spec,ctx,state|
    var events=List.new,add,local=ctx.local,partBar=ctx.partBar,partBars=ctx.partBars.max(1);
    var intro=ctx.section==\intro,space=ctx.section==\space,build=ctx.section==\build;
    var bare=space and:{ctx.bare==true};
    var pitch,rootNote,tones,steps,voicing,melody=List.new,lift=if(build){partBar*4/partBars}{0};
    pitch={|degree|ctx.tonic+ctx.scale.wrapAt(degree)+(12*(degree div:7))};
    rootNote=pitch.value(ctx.degree);
    while {rootNote>47}{rootNote=rootNote-12};
    tones=[0,2,4].collect {|offset|pitch.value(ctx.degree+offset)%12};
    add={|lane,role,voice,step,note,span,gain,tone=0.4,pan=0|
        if(step<0 or:{step>=16} or:{span<=0}){Error("Invalid song-style event").throw};
        events.add((lane:lane,role:role,voice:voice,step:step,beat:step*0.25,midinote:note,
            duration:span,amp:gain,tone:tone,pan:pan,drive:0.24,
            seed:spec.seed+(local*101)+events.size));
    };
    steps=case {bare}{[]} {space}{[0,8]} {true}{spec.kicks.wrapAt(local)};
    steps.do {|step|add.value(3,\djKick,spec.drum,step,36,0.43,if(step==0){0.43}{0.39})};
    if(bare.not){[4,12].do {|step|add.value(3,\djClap,\djAnalogClap,step,50,0.14,0.10,0.4,-0.05)}};
    if(space.not){[2,6,10,14].do {|step,i|
        add.value(3,\djHat,\djAnalogHat,step,104,0.09,0.039*[1,0.70,0.88,0.74][i],0.3,0.22);
    }};
    if(local%8>=4 and:{intro.not and:{space.not}}){
        [7,15].do {|step|add.value(3,\djPerc,\djAnalogPerc,step,60,0.06,0.024,0.3,-0.22)};
    };
    if(bare.not and:{local%8==7 or:{ctx.fill==true}}){
        [13,14,15].do {|step,i|add.value(3,\djSnare,\djAnalogSnare,step,50,0.07,0.024+(i*0.01))};
    };
    if(build and:{partBar>=(partBars-2)}){
        [0,2,4,6,8,10,12,14].do {|step|
            add.value(3,\djSnare,\djAnalogSnare,step,50,0.045,0.018+((partBar-(partBars-2))*0.007));
        };
    };
    if(intro.not){
        var bassSteps=case {bare}{[]} {space}{[0,8]} {true}{spec.bassSteps.wrapAt(local)};
        var rolling=spec.style==\trance and:{bassSteps.size>8};
        // Diatonic fifth, octave or fourth above the chord root, so it stays in the scale.
        var answer=pitch.value(ctx.degree+[4,7,4,3].wrapAt(ctx.patternID ? 0))-pitch.value(ctx.degree);
        bassSteps.do {|step,i|
            var bassNote=rootNote;
            // A single, small answer at a phrase ending, not a new bass tune.
            if(local%4==3 and:{i==(bassSteps.size-1)} and:{space.not}){bassNote=rootNote+answer};
            add.value(0,\djBass,spec.bassVoice,step,bassNote,if(rolling){0.15}{0.33},
                if(rolling){0.15}{0.20},if(space){0.20}{0.34+(lift*0.045)});
        };
        // Close, softly voiced chords; each voice moves to its nearest chord tone.
        voicing=tones.collect {|pc,i|
            (50..72).select {|note|note%12==pc}.minItem {|note|(note-state.pads[i]).abs};
        }.sort;
        state.pads=voicing;
        voicing.do {|note,i|add.value(2,\djPad,\popPad,0,note,3.25,
            if(ctx.hook){0.020}{0.014},0.16,(i-1)*0.38)};
    };
    // The style's four-bar melodic cells over whatever chord is sounding.
    if(ctx.lead.notNil and:{[\hook,\space,\build].includes(ctx.section)}){
        var phrase=partBar%4,cell=spec.motif[phrase],last=cell.size-1,landing,leadLift=ctx.leadLift ? 0;
        landing={|target|
            ((target-4)..(target+4)).select {|note|tones.includes(note%12)}.minItem {|note|(note-target).abs};
        };
        // Without the groove the melody carries the breakdown, so it keeps the whole cell.
        if(space and:{bare.not}){cell=cell.select {|hit,i|i==0 or:{i==last}}};
        cell.do {|hit,i|
            var note=pitch.value(hit[1])+24+leadLift,isLanding=i==(cell.size-1);
            var sustain=hit[2],gain=ctx.lead.amp,step=hit[0];
            if(isLanding or:{i==0}){note=landing.value(note)};
            if(ctx.final==true and:{isLanding}){note=ctx.tonic+24+leadLift};
            if(space){sustain=(sustain*1.45).min((16-step)*0.25-0.08);gain=gain*0.66};
            if(build){gain=gain*(0.73+(lift*0.06))};
            if(ctx.returning==true){gain=gain*1.045};
            if(i>0){gain=gain*0.88};
            add.value(1,\djHook,ctx.lead.voice,step,note,sustain,gain,ctx.lead.tone+(lift*0.035),0);
            melody.add((step:step,note:note,duration:sustain,landing:isLanding,chordTones:tones,phrase:phrase));
        };
    };
    (events:events.asArray,melody:melody.asArray,tones:tones,degree:ctx.degree,rootNote:rootNote);
};
// The approved one-minute arrangement: drums 0-3, groove 4-7, hook 8-15, space 16-19,
// build 20-23, hook return 24-31, resolving to the tonic on the last bar.
~djSongStyleSourceBar={|spec,bar,state,lead|
    var section=case {bar<4}{\intro} {bar<8}{\groove} {bar<16}{\hook} {bar<20}{\space} {bar<24}{\build} {true}{\hook};
    var start=case {bar<4}{0} {bar<8}{4} {bar<16}{8} {bar<20}{16} {bar<24}{20} {true}{24};
    var degree=if(bar==31){0}{spec.chords.wrapAt((bar-8).max(0) div:2)};
    ~djSongStyleBar.value(spec,(section:section,local:bar,partBar:bar-start,
        partBars:if(section==\hook){8}{4},degree:degree,scale:spec.scale,tonic:spec.tonic,
        hook:section==\hook,fill:false,patternID:0,lead:lead,returning:bar>=24,final:bar==31),state);
};
// Live: the engine's generated key, scale, chords and form drive the style.
~djSongStyleLiveBar={|plan,local,section,partBar,partBars,hook,fill,patternID|
    var spec=plan.palette.songStyle,tonic,ctx;
    if(plan[\styleState].isNil){
        var leads=~djSongStyleLeadChoices,choice;
        plan.styleState=~djSongStyleState.value;
        // Each lead is twice as likely as the occasional no-lead version.
        choice=(leads++leads++[nil]).wrapAt((plan.serial*3)+plan.key+(plan.length div:4));
        plan.styleLead=choice;
        plan.styleBare=choice.notNil and:{~djSongStyleBareSpace[spec.id.asSymbol]==choice.voice};
        plan.palette=plan.palette.copy.put(\leadName,if(choice.isNil){"No lead (instrumental)"}{
            choice.name++if(plan.styleBare){", groove-free breakdowns"}{""}});
    };
    // Stay within a fourth or fifth of the approved register.
    tonic=spec.tonic+((plan.key-spec.tonic)%12);
    if(tonic-spec.tonic>6){tonic=tonic-12};
    // Move the whole melody up instead of down when down would leave the lead register.
    if(plan[\styleLeadLift].isNil){
        var lowest=spec.motif.flatten(1).collect {|hit|
            spec.tonic+24+spec.scale.wrapAt(hit[1])+(12*(hit[1] div:7))
        }.minItem;
        plan.styleLeadLift=if(lowest+(tonic-spec.tonic)-5<57){12}{0};
    };
    ctx=(local:local,partBar:partBar,partBars:partBars,degree:plan.schedule[local].degree,
        scale:plan.scale,tonic:tonic,hook:hook,fill:fill,patternID:patternID,
        lead:plan[\styleLead],returning:section==\drop,bare:plan[\styleBare],leadLift:plan.styleLeadLift,
        section:case {[\hook,\drop].includes(section)}{\hook} {[\space,\breakdown].includes(section)}{\space}
            {section==\buildup}{\build} {section==\intro}{\intro} {true}{\groove});
    ~djSongStyleBar.value(spec,ctx,plan.styleState).events.collect {|event|
        event.putAll((deck:plan.deck,track:(plan.deck*4)+event.lane,swing:0,ghost:false,
            color:plan.palette.color,seed:event.seed+(plan.serial*100003)));
    };
};
)
