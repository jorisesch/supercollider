// EDM E: preserve the bass/drum foundation; develop a few complementary parts.
(
var foundation=~djStyleBar,anthemBar;
anthemBar={ |source,plan,local,section,part,partBar,seed,forced|
    var events,add,noteAt,leadNote,leadPhrase,bassLine,buildSteps;
    var scale=plan.scale,degree=plan.schedule[local].degree,phraseBar=partBar%4;
    var tonic=67+((plan.key-7)%12),root=34+((plan.key+scale.wrapAt(degree)-34)%12);
    var motif=[[4,4,6,7],[2,2,4,5],[0,0,2,4],[2,2,3,4]].wrapAt(plan.hookID);
    var release=[\hook,\drop].includes(section),full=release or:{forced};
    var partIndex=plan.sections.indexOf(part),nextPart=plan.sections.at(partIndex+1);
    var previousPart=if(partIndex>0){plan.sections[partIndex-1]}{nil};
    var building=section==\buildup and:{nextPart.notNil and:{[\hook,\drop].includes(nextPart.name)}};
    var buildBar=partBar-(part.bars-4),lastBuild=building and:{buildBar==3};
    var launch=release and:{partBar==0 and:{previousPart.notNil and:{previousPart.name==\buildup}}};
    var quiet=[\breakdown,\space].includes(section);
    var limit=if(lastBuild){2.72}{plan.cutFrom};
    var leadAmp=if(full){0.23}{if(building){0.12+(buildBar.max(0)*0.013)}{0.107}};
    var leadTone=if(full){0.83}{if(building){0.42+(buildBar.max(0)*0.085)}{0.37}};

    events=source.reject { |e|
        [\djHook,\djBass,\djPad,\eChord,\eSignature].includes(e.role)
            or:{building and:{buildBar>=0 and:{[\djSnare,\eTurnaround].includes(e.role)}}}
            or:{lastBuild and:{e.beat>=3}}
    }.as(List);
    add={ |lane,role,voice,step,note,duration,amp,tone=0.5,pan=0|
        events.add((deck:plan.deck,track:(plan.deck*4)+lane,lane:lane,role:role,voice:voice,
            beat:step*0.25,step:step,swing:0,ghost:false,midinote:note,duration:duration,
            amp:amp,pan:pan,color:plan.palette.color,tone:tone,drive:0,
            seed:seed+500009+(plan.serial*100003)+(local*101)+events.size));
    };
    noteAt={ |offset| tonic+scale.wrapAt(offset)+(12*(offset div:7)) };
    leadNote={ |offset,landing|
        var target=noteAt.value(offset);
        if(landing){
            var chordTones=[0,2,4].collect {|i|scale.wrapAt(degree+i)};
            var pentatonic=scale.atAll(if(plan.mode==\major){[0,1,2,4,5]}{[0,2,3,4,6]});
            var shared=chordTones.select {|pitch|pentatonic.includes(pitch)};
            if(shared.notEmpty){chordTones=shared};
            target=((target-8)..(target+8)).select {|note|chordTones.includes((note-plan.key)%12)}
                .minItem {|note|(note-target).abs};
        };
        target+if(full){0}{-12};
    };
    // Two calls share the 3+3+2 pickup. The answers fall and leave space for the next call.
    leadPhrase=[
        [[0,motif[0],0.39],[3,motif[1],0.25],[6,motif[2],0.32],[8,motif[3],0.79,true],
            [12,motif[2],0.21],[14,motif[0],0.30]],
        [[0,motif[2],0.62],[4,motif[0],0.30],[6,motif[0]-2,0.34],[10,motif[1],1.11,true]],
        [[0,motif[0],0.39],[3,motif[1],0.25],[6,motif[2],0.32],[8,motif[3]+2,0.73,true],
            [12,motif[3]+1,0.19],[14,motif[3],0.31]],
        [[0,motif[3],0.53],[3,motif[2],0.27],[6,motif[1],0.30],[8,motif[0],0.92,true]]
    ][phraseBar];
    if(full or:{building or:{quiet or:{(section==\groove) and:{partBar%8<2}}}}){
        if(quiet){leadPhrase=leadPhrase.select {|note|[0,6,8,10].includes(note[0])}};
        leadPhrase.do { |note,i|
            var span=limit-(note[0]*0.25);
            if(span>0.08){
                add.value(1,\djHook,\edmAnthemLead,note[0],leadNote.value(note[1],note[3] ? false),
                    note[2].min(span),leadAmp*[1,0.83,0.93,1].wrapAt(i),leadTone);
            };
        };
    };

    if(quiet.not and:{source.any {|e|e.role==\djBass}}){
        bassLine=if((full and:{phraseBar.odd}) or:{forced}) {
            [[2,0,0.35],[6,0,0.29],[10,0,0.35],[13,0,0.19],[15,12,0.12]]
        } {[[2,0,0.35],[6,0,0.31],[10,0,0.35],[14,0,0.32]]};
        bassLine.do { |note|
            var span=limit-(note[0]*0.25),gain=if(full){0.31}{0.24};
            if(span>0.08){
                add.value(0,\djBass,\edmAnthemBass,note[0],root+note[1],note[2].min(span),
                    gain*if(note[0]%4==2){1}{0.64},if(full){0.76}{0.38});
            };
        };
    };

    if(lastBuild.not and:{[\intro,\outro].includes(section).not}){
        [0,4,6,9].do {|offset,i|
            var floor=[51,55,60,64][i],pitch=floor+((plan.key+scale.wrapAt(degree+offset)-floor)%12);
            var pan=[-0.34,0.30,-0.16,0.20][i];
            add.value(2,\djPad,\djPad,0,pitch,(limit-0.25).min(3.4),if(quiet){0.048}{0.030},0.46,pan);
            if(full){
                (if(launch){[0,10]}{[2,10]}).do {|step|
                    if((step*0.25)<limit){
                        add.value(2,\eChord,\edmEStab,step,pitch+12,0.26,
                            if(launch and:{step==0}){0.047}{0.030},0.74,pan);
                    };
                };
            };
        };
    };
    if(building and:{buildBar>=0}){
        buildSteps=[[4,12],[0,4,8,12,14],[0,2,4,6,8,10,12,14],[0,2,4,6,8,9,10,11]][buildBar];
        buildSteps.do { |step,i|
            add.value(3,\djSnare,plan.palette.voices[\djSnare] ? \djSnare,step,50,0.14,
                0.05+(buildBar*0.021)+(i*0.005),0.5,[-0.10,0.10].wrapAt(i));
        };
        if(buildBar==2){add.value(3,\djRise,\djRise,0,60,6.35,0.12)};
    };
    if(launch and:{section==\hook}){add.value(3,\djImpact,\djImpact,0,60,2,0.12)};
    events;
};
~djELibrary={ |original,mode=\full|
    var lib=original.copy;
    lib.palettes=original.palettes.collect { |palette|
        var p=palette.copy;
        p.voices=palette.voices.copy;
        if([\full,\bass].includes(mode)) {
            p.voices[\djBass]=\edmEBass;p.bassName="Articulated " ++ palette.bassName;
        };
        p.voices[\djStab]=\edmEStab;
        p;
    };
    lib;
};
~djEBar={ |plan,local,section,progress,effective,hook,drumBreak,patternID,fill,seed,random,forced=false|
    var events=foundation.value(plan,local,section,progress,effective,hook,drumBreak,
        patternID,fill,seed,random,forced).collect(_.copy).as(List);
    var mode=plan[\eMode] ? \full,full=mode==\full;
    var bassFeature=full or: {mode==\bass},chords=full or: {mode==\chords},percussion=full or: {mode==\percussion};
    var part=plan.sections.detect { |p|local<(p.start+p.bars)},partBar=local-part.start;
    var thin=[\intro,\space,\breakdown,\buildup,\outro].includes(section);
    var cut=plan.cutFrom<4,bass,root,fifth,add,noteAt,variantB;
    var detailState=(seed.abs+(plan.serial*3331)+(local*101)+15485863)%2147483646+1,detail;
    if(plan.edmAnthem.isNil) {
        var phase=((((seed.abs%2147483646)+6151)*48271)%2147483647)%5;
        // Stagger the one-in-five rotation by seed; keep the form's existing sections.
        plan.edmAnthem=full and:{(plan.serial%5)==phase} and:{
            plan.sections.any {|item,i|
                var next=plan.sections.at(i+1);
                item.name==\buildup and:{next.notNil and:{[\hook,\drop].includes(next.name)}};
            };
        };
    };
    // Additional parts have their own deterministic stream, leaving foundation events intact.
    detail={detailState=(detailState*48271)%2147483647;detailState/2147483647};
    noteAt={ |offset,base=48|
        var degree=plan.schedule[local].degree+offset;
        base+plan.key+plan.scale.wrapAt(degree)+(12*(degree div:7));
    };
    add={ |lane,role,voice,step,note,duration,amp,pan=0,tone=0.45|
        var swing=if(step.odd) {(0.012+(plan.variation.swing*0.7)).clip(0.018,0.045)} {0};
        events.add((deck:plan.deck,track:(plan.deck*4)+lane,lane:lane,role:role,voice:voice,
            beat:((step*0.25)+swing).clip(0,3.95),step:step,swing:swing,ghost:false,
            midinote:note,duration:duration,amp:amp*(0.97+(detail.value*0.06)),pan:pan,
            color:plan.palette.color,tone:tone,drive:0.3,
            seed:seed+200003+(plan.serial*100003)+(local*101)+events.size));
    };
    bass=events.select { |e|e.role==\djBass };
    root=36+((plan.key+plan.scale.wrapAt(plan.schedule[local].degree))%12);
    fifth=36+((plan.key+plan.scale.wrapAt(plan.schedule[local].degree+4))%12);
    if(fifth<root) {fifth=fifth+12};
    // A recognizable B section, followed by A's return in the last eight drop bars.
    // The Bass hook button can request this alternate phrase for four bars.
    variantB=bassFeature and: {drumBreak.not} and: {
        forced or: {section==\drop and: {partBar<8}} or: {
            [\groove,\hook].includes(section) and: {(partBar div:8).odd}
        }
    };
    plan.eVariant=if(variantB) {\b} {\a};
    if(variantB and: {bass.notEmpty} and: {thin.not}) {
        var steps=[[2,6,9,10,14],[0,2,6,10,13,14],[2,6,10,11,14],[0,3,6,10,14]]
            .wrapAt(plan.variation.rhythm);
        var template=bass.first;
        events=events.reject { |e|e.role==\djBass }.as(List);
        if(cut) {steps=steps.select { |step|step<12 }};
        steps.do { |step,i|
            var event=template.copy;
            event.step=step;event.beat=(step*0.25)+if(step.odd) {template.swing.max(0.022)} {0};
            event.midinote=if(i==(steps.size-1) and: {partBar%4==3}) {fifth} {root};
            event.duration=if(step==10) {0.68} {if(step.odd) {0.12} {0.42}};
            event.amp=if(step.odd) {0.095} {0.23*if(hook) {1.1} {1}};
            event.seed=seed+300007+(plan.serial*100003)+(local*101)+i;
            events.add(event);
        };
    };
    if(bassFeature) {
        var previous=plan[\eLastBass] ? root;
        bass=events.select { |e|e.role==\djBass }.sort { |a,b|a.beat<b.beat };
        bass.do { |event,i|
            var next=bass.at(i+1),space=if(next.notNil) {next.beat-event.beat} {4-event.beat};
            var slide=i==(bass.size-1) and: {partBar%4==3} and: {previous!=event.midinote} and: {cut.not};
            event.voice=\edmEBass;
            event[\fromNote]=if(slide) {previous} {event.midinote};
            event[\glide]=if(slide) {0.065+(effective.tension*0.025)} {0};
            if(event.step.odd) {event.duration=0.12;event.tone=event.tone*0.82};
            if(cut) {space=space.min(plan.cutFrom-event.beat)};
            event.duration=event.duration.min((space-0.09).max(0.07));
            previous=event.midinote;
        };
        plan.eLastBass=previous;
    };
    if(percussion and: {thin.not} and: {drumBreak.not}) {
        // Replace the small generic percussion line with a two-bar conversation.
        events=events.reject { |e|e.role==\djPerc }.as(List);
        if(partBar%8>=2 and: {partBar%8<=5} and: {effective.density>0.22}) {
            var steps=if(partBar.even) {[1,3,7,9,11,15]} {[1,5,7,9,13,15]};
            steps.do { |step,i|
                if(cut.not or: {step<12}) {
                    add.value(3,\eShaker,\edmEShaker,step,90,0.045,
                        if([3,11].includes(step)) {0.023} {0.013},if(i.even) {0.32} {-0.22});
                };
            };
        };
        if(partBar%8>=4 and: {partBar%8<=6} and: {effective.density>0.28}) {
            var steps=if(partBar.even) {[7,15]} {[3,10,15]};
            steps.do { |step,i|
                var note=if(i.even) {root+12} {fifth+12};
                if(note>63) {note=note-12};
                if(cut.not or: {step<12}) {
                    add.value(3,\eTom,\edmETom,step,note,
                        if(i==0) {0.23} {0.13},if(i==0) {0.047} {0.030},-0.30);
                };
            };
        };
    };
    if(chords and: {thin.not} and: {drumBreak.not} and: {cut.not} and: {partBar.odd}) {
        // Rootless third/seventh/ninth voicings sit above the bass, with short releases.
        var notes=[2,6,8].collect { |offset|
            var note=noteAt.value(offset);
            while {note<55} {note=note+12};while {note>75} {note=note-12};note;
        }.sort;
        var steps=if(variantB and: {partBar%4==1}) {[5,13]} {[13]};
        steps.do { |step|
            notes.do { |note,i|
                add.value(2,\eChord,\edmEStab,step,note,0.24,0.020,(i-1)*0.23,
                    (0.32+(effective.tension*0.25)).clip(0.2,0.7));
            };
        };
    };
    if(full and: {drumBreak.not} and: {[\hook,\drop].includes(section)} and: {partBar%16==3} and: {cut.not}) {
        // A small recurring vowel-like percussion hook, separate from the rare lead tag.
        [3,11].do { |step,i|add.value(1,\eSignature,\edmESignature,step,
            noteAt.value(if(i==0) {0} {4}),if(i==0) {0.26} {0.40},0.030,if(i==0) {-0.12} {0.12})};
    };
    if(full and: {section==\buildup} and: {partBar==(part.bars-1)} and: {drumBreak.not}) {
        // A brief inhalation before the one-beat pickup, never a continuous riser.
        add.value(1,\eTurnaround,\edmEReverse,10,60,0.48,0.035,0.15);
    };
    if(plan.edmAnthem and:{drumBreak.not}) {
        events=anthemBar.value(events,plan,local,section,part,partBar,seed,forced);
    };
    events.asArray.sort { |a,b|a.beat<b.beat };
};
)
