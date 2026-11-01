// Shared musical grammar for the rendered track and every Infinite DJ record.
// Pure events, no playback. Bass and drums carry the record; melody is a rare accent.
(
~djStyleBar={ |plan,local,section,progress,effective,hook,drumBreak,patternID,fill,seed,random,forced=false|
    var events=List.new,add,degree=plan.schedule[local].degree,scale=plan.scale;
    var part=plan.sections.detect { |p| local < (p.start+p.bars) },partBar=local-part.start;
    var root=36+((plan.key+scale.wrapAt(degree))%12),fifth,noteAt,leadOn,bassOn;
    var bassSteps,thin=[\space,\breakdown].includes(section),arc=(partBar%8)/7;
    var swing=(0.012+(plan.variation.swing*0.7)).clip(0.018,0.045);
    var breath=[\groove,\hook,\drop].includes(section) and: {local%16==6}
        and: {partBar>=4} and: {drumBreak.not};
    var lowOut=section==\buildup and: {partBar==(part.bars-1)};
    var cut=breath or: {lowOut};
    var detail=thin.not and: {lowOut.not} and: {partBar%8>=2} and: {breath.not};
    var bassTone=(0.20+(effective.tension*0.30)+(plan.intensity*0.16)+(arc*0.20)
        +if(hook) {0.08} {0}-if(thin) {0.14} {0}).clip(0.12,0.92);
    var bassDrive=(0.18+(effective.tension*0.20)+(plan.intensity*0.16)+(arc*0.20)
        +if(hook) {0.10} {0}-if(thin) {0.10} {0}).clip(0.10,0.90);
    var bassBank=[
        [2,5,6,10,14], [0,3,6,10,14],
        [2,6,9,10,14], [0,3,6,8,11,14],
        [2,6,10,13,14], [0,2,6,10,14],
        [2,5,6,10,12,14], [0,3,6,10,13,14]
    ];
    // Steps and scale degrees form little gestures, with room between entrances.
    var leadBank=[
        [[6,9,12,14],[0,0,2,0]],
        [[10,12,14],[4,2,0]],
        [[2,5,8,10,12,14],[0,0,2,4,2,0]],
        [[12,14],[4,0]],
        [[4,7,10,12,14],[0,2,0,4,0]],
        [[8,10,14],[0,4,0]]
    ];
    fifth=36+((plan.key+scale.wrapAt(degree+4))%12);
    if(fifth<root) {fifth=fifth+12};
    noteAt={ |offset,octave=0|
        var note=60+plan.key+scale.wrapAt(degree+offset)+(12*((degree+offset) div:7))+octave;
        while {note > 79} {note=note-12}; note;
    };
    add={ |lane,voice,step,note,duration,amp,pan=0,tone,ghost=false|
        var anchor=lane==0 or: {[\djKick,\djHook].includes(voice)},human,shift;
        var instrument=plan.palette.voices[voice] ? voice;
        human=if(anchor) {0} {random.value*0.006};
        shift=if(step.odd and: {lane==0 or: {[\djHat,\djPerc,\djSnare].includes(voice)}}) {swing} {0};
        if(voice==\djClap) {shift=0.009};
        events.add((deck:plan.deck,track:(plan.deck*4)+lane,lane:lane,role:voice,voice:instrument,
            beat:((step*0.25)+shift+human).clip(0,3.95),step:step,swing:shift,ghost:ghost,
            midinote:note,duration:duration,
            amp:amp*(0.96+(random.value*0.08)),pan:pan,color:plan.palette.color,
            tone:tone ? if(lane==0) {bassTone} {(0.22+(effective.tension*0.35)+(plan.intensity*0.22)).clip(0,1)},
            drive:if(lane==0) {bassDrive} {0},
            seed:seed+(plan.serial*100003)+(local*101)+events.size));
    };
    plan.breath=breath; plan.lowOut=lowOut; plan.cutFrom=if(cut) {3} {4};
    plan.bassTone=bassTone; plan.bassDrive=bassDrive;
    bassOn=drumBreak.not and: {section!=\intro or: {progress>0.3}};
    leadOn=drumBreak.not and: {[\hook,\drop].includes(section)} and: {partBar%16==7};
    // Repeated low roots provide the hook. Space comes from removing parts.
    bassSteps=case {section==\breakdown} {[2,10]}
        {thin or: {effective.density<0.25}} {[2,6,10,14]}
        {true} {bassBank.wrapAt(plan.variation.rhythm)};
    // Keep the cell recognizable; only the last beat answers every fourth bar.
    if(partBar%4==3 and: {thin.not} and: {effective.density>0.3}) {
        switch((plan.hookID+patternID)%3,
            0,{bassSteps=bassSteps.reject { |step| step==14 }.add(15).sort},
            1,{bassSteps=bassSteps.reject { |step| step==14 }.add(12).asSet.asArray.sort},
            2,{}
        );
    };
    if(cut) {bassSteps=bassSteps.select { |step| step<12 }};
    if(bassOn) {
        bassSteps.do { |step,i|
            var answer=partBar%4==3 and: {step==bassSteps.last},nextStep=bassSteps.at(i+1) ? 16;
            var note=if(answer) {fifth} {root},accent=if(step%4==2) {0.23} {if(step.odd) {0.095} {0.13}};
            var length=if(step%4==2) {0.43} {0.15};
            length=length.min(((nextStep-step)*0.25)-0.12).max(0.10);
            if(step==2) {accent=accent*1.08};
            add.value(0,\djBass,step,note,length,
                accent * if(section==\breakdown) {0.68} {if(hook) {1.1} {1}},0);
        };
        if(hook and: {cut.not} and: {partBar%4==3} and: {effective.density>0.55} and: {bassSteps.includes(15).not}) {
            add.value(0,\djBass,15,if(plan.mutations.odd) {fifth} {root+12},0.14,0.10)
        };
    };
    if(leadOn) {
        // Occasional phrases can develop; the long gaps keep the groove in front.
        var shape=leadBank.wrapAt(plan.hookID+plan.mutations+if(section==\drop) {2} {0});
        shape[0].do { |step,i|
            var note=noteAt.value(shape[1][i]);
            var nextStep=shape[0].at(i+1) ? 16,duration=(((nextStep-step)*0.25)-0.12).clip(0.18,0.72);
            if(note>74) {note=note-12};
            add.value(1,\djHook,step,note,duration,0.032,-0.1);
        };
    };
    // One quiet two-voice atmosphere at a breakdown entrance; no automatic arp/comping.
    if(section==\breakdown and: {partBar==0} and: {drumBreak.not}) {
        [0,4].do { |offset,i|
            add.value(2,\djPad,0,noteAt.value(offset,-12),(part.bars*4)-2,0.012,(i-0.5)*0.35)
        };
    };
    {
        [0,4,8,12].do { |step|
            if((cut.not or: {step<12})
                and: {section!=\breakdown or: {step%8==0}}
                and: {section!=\buildup or: {progress>0.5 or: {step%8==0}}}
                and: {section!=\buildup or: {progress<0.95 or: {step<12}}}) {
                add.value(3,\djKick,step,31,0.42,if(step==0) {0.47} {0.43});
            };
        };
        if(section!=\breakdown and: {section!=\intro or: {progress>0.2}}) {
            [4,12].do { |step|
                if(cut.not or: {step<12}) {add.value(3,\djClap,step,50,0.16,0.12,-0.04)}
            };
        };
        [2,6,10,14].do { |step|
            var accent=[1,0.70,0.88,0.76][(step-2) div:4];
            if(cut.not or: {step<12}) {
                add.value(3,\djHat,step,110,if(hook and: {step==14}) {0.21} {0.10},
                    if(thin or: {lowOut}) {0.038} {0.072}*accent,0.22)
            }
        };
        if(detail and: {effective.density>0.3}) {
            [0,4,8,12].do { |step| add.value(3,\djHat,step,110,0.035,0.021,-0.2) };
        };
        if(detail and: {effective.density>0.4}) {
            if(effective.density>0.8) {[3,7,11,15]} {if(partBar%4<2) {[7,15]} {[3,11]}}.do { |step|
                add.value(3,\djHat,step,110,0.028,0.018,-0.12,nil,true)
            };
        };
        // Percussion has its own entrance and exit within the eight-bar phrase.
        if(detail and: {partBar%8>=4} and: {effective.density>0.35}) {
            [7,15].do { |step,i| add.value(3,\djPerc,step,60,0.07,if(i==0) {0.037} {0.024},-0.3) };
        };
        if(detail and: {partBar.odd} and: {effective.density>0.25}) {
            add.value(3,\djSnare,[3,11].wrapAt(partBar div:2),50,0.045,0.024,-0.12,nil,true)
        };
    }.value;
    if(fill) {
        [13,14,15].do { |step,i| add.value(3,\djSnare,step,50,0.07,0.035+(i*0.018),-0.1) };
    };
    if(section==\buildup and: {progress>0.55}) {
        if(lowOut) {[4,8]} {[8,12]}.do { |step|
            add.value(3,\djSnare,step,50,0.065,0.035,0)
        };
    };
    // A one-shot impact marks the arrival; there is no perpetual riser.
    if(section==\drop and: {partBar==0}) {add.value(3,\djImpact,0,60,2,0.12)};
    events.asArray.sort { |a,b| a.beat < b.beat };
};
)
