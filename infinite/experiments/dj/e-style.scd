// EDM E: preserve the bass/drum foundation; develop a few complementary parts.
(
var foundation=~djStyleBar;
~djELibrary={ |original,mode=\full|
    var lib=original.copy;
    lib.palettes=original.palettes.collect { |palette|
        var p=palette.copy;
        p.voices=palette.voices.copy;p.name="E / " ++ palette.name;
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
    events.asArray.sort { |a,b|a.beat<b.beat };
};
)
