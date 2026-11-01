// Shared musical grammar for the rendered track and every Infinite DJ record.
// Pure events, no playback. Repetition belongs to the riff; variation to phrases.
(
~djStyleBar={ |plan,local,section,progress,effective,hook,drumBreak,patternID,fill,seed,random,forced=false|
    var events=List.new,add,degree=plan.schedule[local].degree,scale=plan.scale;
    var phrase=local%4,partBar=local-plan.sections.detect { |p| local < (p.start+p.bars) }.start;
    var root=36+((plan.key+scale.wrapAt(degree))%12),noteAt,leadOn,bassOn,drumsOn;
    var riff,tones,bassSteps,leadSteps,opening=plan.serial==0 and: {local < (plan.sections.first.bars+4)};
    var riffBank=[
        [[2,6,10],[0,2,4]],
        [[2,8,10],[0,4,2]],
        [[2,6,12],[0,4,2]],
        [[2,6,10,14],[0,2,0,4]]
    ];
    noteAt={ |offset,octave=0|
        var note=60+plan.key+scale.wrapAt(degree+offset)+(12*((degree+offset) div:7))+octave;
        while {note > 79} {note=note-12}; note;
    };
    add={ |lane,voice,step,note,duration,amp,pan=0,tone|
        var anchor=lane==0 or: {[\djKick,\djHook].includes(voice)},human;
        var instrument=plan.palette.voices[voice] ? voice;
        human=if(anchor) {0} {random.value*0.006};
        events.add((deck:plan.deck,track:(plan.deck*4)+lane,lane:lane,role:voice,voice:instrument,
            beat:((step*0.25)+human).clip(0,3.95),midinote:note,duration:duration,
            amp:amp*(0.96+(random.value*0.08)),pan:pan,color:plan.palette.color,
            tone:tone ? (0.22+(effective.tension*0.35)+(plan.intensity*0.22)).clip(0,1),
            seed:seed+(plan.serial*100003)+(local*101)+events.size));
    };
    drumsOn=section!=\breakdown;
    bassOn=drumBreak.not and: {section!=\breakdown} and: {section!=\intro or: {progress>0.3}};
    leadOn=drumBreak.not and: {hook or: {section==\groove and: {partBar%8>=4}}};
    if(opening and: {forced.not}) {leadOn=false};
    if(section==\outro or: {section==\intro}) {leadOn=false};
    riff=riffBank.wrapAt(plan.variation.rhythm);
    tones=if(plan.hookID==0) {riff[1]} {
        ~djLibrary.hooks[plan.hookID].collect { |index| [0,2,4,7].wrapAt(index) }
    };
    leadSteps=if(phrase.odd) {[2,10]} {riff[0]};
    // A short root/fifth bass ostinato. Main accents lock to the lead's offbeats.
    bassSteps=if(effective.density<0.25) {[2,6,10,14]} {[0,2,6,8,10,14]};
    if(bassOn) {
        bassSteps.do { |step,i|
            var note=root+if(phrase==3 and: {step==14}) {7} {0};
            add.value(0,\djBass,step,note,if(step%4==2) {0.33} {0.18},
                if(step%4==2) {0.205} {0.125},0);
        };
        if(effective.density>0.7 and: {phrase==3}) {add.value(0,\djBass,15,root+12,0.14,0.075)};
    };
    if(leadOn) {
        leadSteps.do { |step,i|
            var offset=tones.wrapAt(i),nextStep=leadSteps.at(i+1) ? 16;
            var duration=(((nextStep-step)*0.25)-0.12).clip(0.45,1.65),note;
            // Same call twice, a quieter response, then a short resolving answer.
            var accent=if(step%4==2) {1} {0.85},gain=if(hook) {0.075} {0.05};
            if(phrase==2) {gain=gain*0.83};
            if(phrase==3) {offset=[4,0].wrapAt(i)};
            if(plan.mutations.odd and: {phrase==3 and: {i==1}}) {
                offset=[7,4,2].wrapAt(patternID);
            };
            note=noteAt.value(offset);
            if(note>74) {note=note-12};
            add.value(1,\djHook,step,note,duration,gain*accent,-0.06);
        };
    };
    // Supporting voices take turns with the riff; they do not run a second song.
    if(drumBreak.not) {
        if([\breakdown,\space].includes(section) and: {local%2==0}) {
            [0,2,4].do { |offset,i| add.value(2,\djPad,0,noteAt.value(offset,-12),7.0,0.023,(i-1)*0.28) };
        };
        if(leadOn.not and: {[\groove,\intro,\outro].includes(section)} and: {local.even}
            and: {effective.density>0.3} and: {opening.not}) {
            [6,14].do { |step|
                [0,2].do { |offset,i| add.value(2,\djStab,step,noteAt.value(offset,-12),0.18,0.021,(i-0.5)*0.3) };
            };
        };
        if(phrase==3 and: {[\drop,\buildup].includes(section)} and: {effective.density>0.55}) {
            [12,14,15].do { |step,i| add.value(2,\djArp,step,noteAt.value([0,2,4][i]),0.12,0.027,0.22) };
        };
    };
    if(drumsOn) {
        [0,4,8,12].do { |step|
            if((section!=\buildup or: {progress>0.5 or: {step%8==0}})
                and: {(section!=\buildup or: {progress<0.95 or: {step<12}})}) {
                add.value(3,\djKick,step,31,0.42,if(step==0) {0.47} {0.43});
            };
        };
        if(section!=\intro or: {progress>0.2}) {
            [4,12].do { |step| add.value(3,\djClap,step,50,0.16,0.12,-0.04) };
        };
        [2,6,10,14].do { |step| add.value(3,\djHat,step,110,if(hook) {0.20} {0.12},0.072,0.22) };
        if(effective.density>0.3) {
            [0,4,8,12].do { |step| add.value(3,\djHat,step,110,0.035,0.021,-0.2) };
        };
        if(effective.density>0.7) {
            [3,7,11,15].do { |step| add.value(3,\djHat,step,110,0.03,0.018,-0.12) };
        };
        // A recurring percussion answer, rather than unrelated random hits.
        if(phrase.odd and: {effective.density>0.4}) {
            [7,15].do { |step| add.value(3,\djPerc,step,60,0.08,0.032,-0.3) };
        };
    };
    if(fill) {
        [13,14,15].do { |step,i| add.value(3,\djSnare,step,50,0.07,0.035+(i*0.018),-0.1) };
    };
    if(section==\buildup and: {progress>0.55}) {
        [8,10,12,14].do { |step| add.value(3,\djSnare,step,50,0.08,0.025+(progress*0.018),0) };
        if(progress>0.85) {add.value(3,\djRise,0,60,3.8,0.03)};
    };
    // A one-shot impact marks the arrival; there is no perpetual riser.
    if(section==\drop and: {partBar==0}) {add.value(3,\djImpact,0,60,2,0.12)};
    events.asArray.sort { |a,b| a.beat < b.beat };
};
)
