// Seeded record planning with one shared bass-and-drums dance-music grammar.
// No playback, clocks, file writes, or global random-stream edits.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "library.scd").load;
(root +/+ "style.scd").load;
(root +/+ "pop-style.scd").load;
(root +/+ "e-style.scd").load;
~makeDJEngine={ |seed=2600,bpm=128,settings|
    var channel=(settings ? () )[\channel] ? \edme;
    var eMode=(settings ? ())[\eMode] ? \full;
    var lib=case {channel==\pop} {~djPopLibrary.value(~djLibrary)}
        {channel==\edme} {~djELibrary.value(~djLibrary,eMode)} {true} {~djLibrary};
    var styleBar=case {channel==\pop} {~djPopBar} {channel==\edme} {~djEBar} {true} {~djStyleBar};
    var rng=(seed.abs%2147483646)+1,random,choose,take,makeRecord,nextBar,engine;
    var bags=(variation:List.new,key:List.new,duration:List.new,hook:List.new,form:List.new,
        major:List.new,minor:List.new);
    var current,incoming,mixPosition=0,mixLength=8,bar=0,serial=0;
    var nextRequested=false,hookRequested=false,fillRequested=false,fxRequested=nil;
    var heldFX=nil,heldRequest=nil,releaseFX=false;
    var controls=(chaos:0.25,density:0.55,mutation:0.30,tension:0.20,hold:false,autoStutter:true);
    var paletteBag=List.new,paletteRng=((seed.abs+104729)%2147483646)+1,lastPalette,choosePalette;
    var fxRng=((seed.abs+65537)%2147483646)+1,fxRandom,stutter=nil,nextAutoBar=8;
    var state=(bar:0,bpm:bpm,mixing:false,progress:0,decks:[nil,nil],phase:0,lastFX:\none);
    if(settings.notNil) { settings.keysValuesDo { |key,value| controls[key]=value } };
    bpm=bpm.clip(118,140); state.bpm=bpm;
    random={ rng=(rng*48271)%2147483647; rng/2147483647 };
    choose={ |items| items[(random.value*items.size).floor.asInteger] };
    fxRandom={fxRng=(fxRng*48271)%2147483647; fxRng/2147483647};
    take={ |bag,size,excluded,preferred|
        var choices,picked;
        if(bag.isEmpty) { size.do { |i| bag.add(i) } };
        choices=bag.asArray.reject { |item| item==excluded };
        if(choices.isEmpty) { choices=bag.asArray };
        picked=if(preferred.notNil and: { choices.includes(preferred) }) { preferred } { choose.value(choices) };
        bag.removeAt(bag.indexOf(picked)); picked;
    };
    // A separate random stream preserves the composition when palettes change.
    choosePalette={ |index|
        var choices,id;
        if(controls[\palette].notNil) {
            id=controls[\palette].asInteger.clip(0,lib.palettes.size-1);
        } {
            if(paletteBag.isEmpty) {lib.palettes.size.do { |i| paletteBag.add(i)}};
            choices=paletteBag.asArray.reject { |i| i==lastPalette };
            paletteRng=(paletteRng*48271)%2147483647;
            id=if(index==0) {0} {choices[(paletteRng/2147483647*choices.size).floor.asInteger]};
            paletteBag.removeAt(paletteBag.indexOf(id));
        };
        lastPalette=id;
        lib.palettes[id];
    };
    makeRecord={ |deck,index,previousKey,previousBpm,entryBars=0|
        var first=index==0,preferred=if(first) {0} {nil},plan,next,key,mode,scale,progression,durations;
        var variation,progressionID,durationID,hookID,formID,form,sections=List.new,total=0,schedule;
        var cursor=0,chordIndex=0,localBar,forcedHook=0,change=false,forcedFill=false;
        var phraseLift=0,patternID,mutations=0,energyBias,wildness,densityBias;
        key=take.value(bags.key,12,previousKey,preferred);
        mode=if(index.even) {\minor} {\major};
        scale=if(mode==\minor) {[0,2,3,5,7,8,10]} {[0,2,4,5,7,9,11]};
        progressionID=take.value(bags[mode],lib[mode].size,nil,if(channel==\pop){nil}{preferred});
        durationID=take.value(bags.duration,lib.durations.size,nil,if(channel==\pop){nil}{preferred});
        hookID=take.value(bags.hook,lib.hooks.size,nil,preferred);
        formID=take.value(bags.form,lib.forms.size,nil,preferred);
        variation=lib.variations[take.value(bags.variation,lib.variations.size,nil,preferred)].copy;
        if(first) { variation.name=if(channel==\pop) {"Neon Pop / C minor"} {"Interlock / C minor"} };
        progression=lib[mode][progressionID];
        durations=if(channel==\pop) {lib.durations[durationID].copy} {
            lib.durations[durationID].collect { |n| (n/2).round.asInteger.max(1)*2 }
        }; form=lib.forms[formID];
        form.do { |part|
            sections.add((name:part[0],start:total,bars:part[1])); total=total+part[1];
        };
        schedule=Array.newClear(total);
        while { cursor < total } {
            var length=durations.wrapAt(chordIndex).min(total-cursor);
            var chord=(start:cursor,bars:length,degree:progression.wrapAt(chordIndex));
            length.do { |offset| schedule[cursor+offset]=chord };
            cursor=cursor+length; chordIndex=chordIndex+1;
        };
        // Cue the incoming intro so its groove arrives by the end of a short mix.
        localBar=if(first) { if(channel==\pop) {0} {form[0][1]} } { (form[0][1]-entryBars).max(0) };
        patternID=variation.rhythm;
        energyBias=if(first) {1} {choose.value([0.85,0.94,1.0,1.08])};
        wildness=if(first) {1} {choose.value([0.75,0.9,1.1,1.35])};
        densityBias=if(first) {1} {choose.value([0.85,0.95,1.05,1.15])};
        plan=(deck:deck,serial:index,key:key,mode:mode,scale:scale,style:if(channel==\pop) {\pop} {\interlock},keyName:lib[\keys][key] ++ " " ++ mode,
            variation:variation,palette:choosePalette.value(index),progression:progression,progressionID:progressionID,durations:durations,
            durationID:durationID,hookID:hookID,formID:formID,sections:sections.asArray,schedule:schedule,
            length:total,mixBars:if(form.last[1] >= 16) {choose.value([8,16])} {8},
            targetBpm:if(first) {bpm} {(previousBpm+choose.value([-4,-2,2,4])).clip(122,136)},
            position:localBar,localBar:localBar,section:\groove,hook:false,mutations:0,
            effective:(chaos:0.25,density:0.55,mutation:0.30,tension:0.20),intensity:0.8);
        if(index > 0 and: { plan.targetBpm==previousBpm }) {
            plan.targetBpm=previousBpm+if(previousBpm >= 130) {-2} {2};
        };
        if(channel==\edme) {plan.eMode=eMode;plan.style=\edme};
        if(channel==\pop) {plan.schedule=~djPopHarmony.value(plan,lib,seed)};
        next={
            var local=localBar,part=sections.detect { |item| local < (item.start+item.bars) };
            var section=part.name,partBar=local-part.start,progress=partBar/(part.bars-1).max(1);
            var intensity,effective,drumBreak,hook,fill,events;
            if(local%4==0) { phraseLift=choose.value([-0.03,0,0.02,0.04]) };
            intensity=case { section==\intro } {0.5+(progress*0.2)}
                { section==\groove } {0.78} { section==\hook } {0.92}
                { section==\space } {0.48} { section==\breakdown } {0.3}
                { section==\buildup } {0.48+(progress*0.5)}
                { section==\drop } {1.12} { true } {0.78-(progress*0.25)};
            intensity=((intensity*energyBias)+phraseLift).clip(0.25,1.22);
            // One drum-only bar after the groove has settled, at most once in 32 bars.
            drumBreak=[\groove,\hook,\drop].includes(section) and: {partBar>=8}
                and: {local%32==12} and: {channel!=\pop};
            effective=(
                chaos:(controls.chaos.clip(0,1)*(0.45+(intensity*0.8))*wildness).clip(0,1),
                density:(controls.density.clip(0,1)*(0.3+(intensity*0.8))*densityBias).clip(0,1),
                mutation:(controls.mutation.clip(0,1)*(0.65+(intensity*0.45))).clip(0,1),
                tension:(controls.tension.clip(0,1)*(0.55+(intensity*0.7)
                    +if(section==\buildup) {progress*0.8} {0})).clip(0,1)
            );
            // Keep the bass foundation; vary its pickup after a full phrase.
            if(controls.hold.not and: {change or: {local%16==0 and: {random.value < effective.mutation}}}) {
                patternID=(patternID+1)%8; mutations=mutations+1;
            };
            change=false;
            fill=forcedFill or: {partBar%8==7 and: {random.value < (0.20+(effective.chaos*0.35))}};
            forcedFill=false;
            hook=([\hook,\drop].includes(section) or: {forcedHook>0}) and: {drumBreak.not};
            plan.localBar=local; plan.section=section; plan.hook=hook; plan.drumBreak=drumBreak;
            plan.intensity=intensity; plan.effective=effective; plan.patternID=patternID;
            plan.mutations=mutations; plan.sectionProgress=progress;
            events=styleBar.value(plan,local,section,progress,effective,hook,drumBreak,
                patternID,fill,seed,random,forcedHook>0);
            localBar=(localBar+1)%total; plan.position=localBar;
            forcedHook=(forcedHook-1).max(0);
            events;
        };
        plan[\nextBar]=next; plan[\hookNow]={ forcedHook=4 };
        plan[\mutate]={ change=true }; plan[\fill]={ forcedFill=true }; plan;
    };
    current=makeRecord.value(0,0,nil,bpm);
    nextBar={
        var events=List.new,automation,deckInfo=[nil,nil],mixing,startBpm,endBpm,frame;
        var requestedFX,requestKind,hotDeck,hotPlan,fxFor,activeStutter;
        var requested=nextRequested and: { bar%4==0 } and: { incoming.isNil };
        var automatic=current.position >= (current.length-current.mixBars);
        if(incoming.isNil and: { requested or: { automatic and: { controls.hold.not } } }) {
            incoming=makeRecord.value(1-current.deck,serial+1,current.key,current.targetBpm,current.mixBars);
            mixLength=current.mixBars; mixPosition=0; nextRequested=false;
        };
        mixing=incoming.notNil;
        requestedFX=fxRequested; fxRequested=nil;
        requestKind=if(requestedFX.notNil) {requestedFX.kind} {nil};
        hotDeck=if(mixing and: { mixPosition >= (mixLength/2) }) { incoming.deck } { current.deck };
        if(releaseFX) {heldFX=nil; heldRequest=nil; releaseFX=false; nextAutoBar=bar+16};
        if(heldRequest.notNil) {
            heldFX=(kind:heldRequest,age:0,deck:hotDeck,reset:true);
            heldRequest=nil; stutter=nil;
        };
        if(heldFX.notNil) {
            heldFX[\reset]=heldFX.age==0 or: {heldFX.deck!=hotDeck};
            heldFX.deck=hotDeck;
        };
        if(hookRequested) {
            if(mixing and: { mixPosition >= (mixLength/2) }) { incoming[\hookNow].value } { current[\hookNow].value };
            hookRequested=false;
        };
        if(fillRequested) { current[\fill].value; fillRequested=false };
        events.addAll(current[\nextBar].value); deckInfo[current.deck]=current;
        if(mixing) { events.addAll(incoming[\nextBar].value); deckInfo[incoming.deck]=incoming };
        hotPlan=deckInfo[hotDeck];
        // Effects have their own clock/RNG and are pinned to a record, never a
        // reusable deck slot. Auto bursts leave sixteen full clear bars after them.
        if(stutter.notNil) {
            var plan=deckInfo[stutter.deck];
            if(plan.isNil or: {plan.serial!=stutter.serial} or: {
                stutter[\source]==\auto and: {controls.autoStutter.not or: {mixing}}
            }) {stutter=nil};
        };
        if([\stutter4,\stutter8,\stutter16,\stutter].includes(requestKind)) {
            var division=switch(requestKind,\stutter4,{4},\stutter8,{8},{16});
            stutter=(division:division,rate:division/4,bars:requestedFX.bars,age:0,
                startBeat:if(requestedFX.bars==0.5) {2} {0},
                deck:hotDeck,serial:hotPlan.serial,source:\manual,depth:0.86);
            nextAutoBar=bar+requestedFX.bars.ceil+16;
        };
        if(stutter.isNil and: {heldFX.isNil} and: {requestKind.isNil} and: {controls.autoStutter}
            and: {mixing.not} and: {bar>=nextAutoBar} and: {hotPlan.drumBreak.not}) {
            var part=hotPlan.sections.detect { |p| hotPlan.localBar<(p.start+p.bars) };
            var partBar=hotPlan.localBar-part.start;
            var eligible=([\groove,\hook,\drop].includes(part.name) and: {partBar%8==4})
                or: {part.name==\buildup and: {partBar==0}};
            if(eligible and: {fxRandom.value < (0.35+(controls.chaos*0.25)
                +(controls.tension*0.15)+if(part.name==\buildup) {0.2} {0}).clip(0,0.85)}) {
                stutter=(division:16,rate:4,bars:0.5,age:0,startBeat:2,deck:hotDeck,
                    serial:hotPlan.serial,source:\auto,depth:0.68+(fxRandom.value*0.10));
                nextAutoBar=bar+17;
            };
        };
        activeStutter=nil;
        if(stutter.notNil) {
            activeStutter=stutter.copy; activeStutter.remaining=stutter.bars-stutter.age;
        };
        startBpm=current.targetBpm; endBpm=if(mixing) {incoming.targetBpm} {startBpm};
        fxFor={ |plan,t,step|
            var section=plan.section, intensity=plan.intensity.clip(0.2,1.25), wave,barT;
            var filter,cutoff,resonance,echo,delay,reverb,stutter,stutterRate=4,reset=false,values,base,phase;
            // `t` is the deck handover position and is zero outside a mix;
            // hot buttons need their own within-this-bar phase in both cases.
            barT=(step/16).clip(0,1);
            wave=(sin((plan.localBar*0.43)+(step*0.19)+(plan.deck*1.7))*0.5)+0.5;
            filter=case
                { section==\buildup } {0.55-(plan.sectionProgress*0.46)}
                { [\space,\breakdown].includes(section) } {0.28+(wave*0.13)}
                { [\hook,\drop].includes(section) } {0.035+(wave*0.035)}
                { true } {0.04+(wave*0.025)};
            cutoff=(900+((1-filter.clip(0,0.92))*10600)+(wave*1200)).clip(650,15500);
            resonance=(0.28+(filter*0.32)+(wave*0.05)).clip(0.18,0.82);
            echo=(0.015+(wave*0.025)+if(section==\space) {0.16} {0}).clip(0,0.32);
            // Stable dotted-eighth note time (in beats), including HOT throws.
            delay=0.75;
            reverb=(0.08+if([\space,\breakdown].includes(section)) {0.22} {0.03}
                +(wave*0.05)).clip(0,0.48);
            stutter=0;
            if(activeStutter.notNil and: {plan.serial==activeStutter.serial}) {
                var elapsed=(activeStutter.age*4)+(step*0.25)-activeStutter.startBeat;
                stutterRate=activeStutter.rate;
                if(elapsed>=0 and: {elapsed<(activeStutter.bars*4)}) {
                    stutter=activeStutter.depth; echo=echo.max(0.12);
                };
                reset=activeStutter.age==0 and: {(step*0.25)==activeStutter.startBeat};
            };
            if(requestKind.notNil and: { plan.deck==hotDeck }) {
                switch(requestKind,
                    \filter, { filter=(0.76+(barT*0.18)).clip(0,1); cutoff=(10500-(barT*9300)).clip(700,10500); resonance=0.63 },
                    \echo, { echo=0.88; reverb=0.18 },
                    // Let the wash bloom across the whole quantized bar instead of slamming on.
                    \wash, { var bloom=barT; filter=0.22+(bloom*0.25); cutoff=4200-(bloom*1800);
                        echo=0.12+(bloom*0.43); reverb=0.18+(bloom*0.72) },
                    \stutter4, {}, \stutter8, {}, \stutter16, {}, \stutter, {}
                );
            };
            values=(filter:filter.clip(0,1),cutoff:cutoff.clip(500,18000),resonance:resonance.clip(0.12,0.9),
                echo:echo.clip(0,1),delay:delay.clip(0.08,0.75),reverb:reverb.clip(0,1),
                stutter:stutter.clip(0,1),stutterRate:stutterRate,
                stutterReset:reset);
            if(heldFX.notNil and: {plan.deck==heldFX.deck}) {
                base=values.copy; phase=(heldFX.age+barT).clip(0,1);
                switch(heldFX.kind,
                    \filter,{values.filter=0.76+(phase*0.18);values.cutoff=10500-(phase*9300);values.resonance=0.63},
                    \echo,{values.echo=0.88;values.reverb=0.18},
                    \wash,{values.filter=0.22+(phase*0.25);values.cutoff=4200-(phase*1800);
                        values.echo=0.12+(phase*0.43);values.reverb=0.18+(phase*0.72)},
                    {values.stutter=0.86;values.stutterRate=switch(heldFX.kind,\stutter4,{1},\stutter8,{2},{4});
                        values.stutterReset=heldFX[\reset] and: {step==0}}
                );
                values[\manualKind]=heldFX.kind;values[\base]=base;
            };
            values;
        };
        automation=Array.fill(17,{ |step|
            var t=if(mixing) { (mixPosition+(step/16))/mixLength } {0};
            var gains=Array.fill(2,{ [0,0,0] });
            var fx=Array.fill(2,{ (filter:0,cutoff:12000,resonance:0.35,echo:0,delay:0.33,reverb:0.14,stutter:0,stutterRate:4,stutterReset:false) });
            if(mixing) {
                gains[current.deck]=[(1-(t/0.45)).clip(0,1),(1-(t/0.5)).clip(0,1),1-t];
                gains[incoming.deck]=[((t-0.55)/0.45).clip(0,1),((t-0.55)/0.35).clip(0,1),t];
                fx[current.deck]=fxFor.value(current,t,step);
                fx[incoming.deck]=fxFor.value(incoming,t,step);
            } {
                gains[current.deck]=[1,1,1];
                fx[current.deck]=fxFor.value(current,t,step);
            };
            // Clear lingering pitched voices and their returns during drum spotlights too.
            deckInfo.do { |plan,id|
                if(plan.notNil and: {plan.drumBreak}) {gains[id][0]=0; gains[id][1]=0};
            };
            (beat:step*0.25,bpm:startBpm+((endBpm-startBpm)*t),gains:gains,fx:fx,progress:t,hotFX:requestKind ? \none)
        });
        state.bar=bar; state.phase=mixPosition; state.bpm=automation[0].bpm;
        state.decks=deckInfo; state.mixing=mixing; state.progress=automation[0].progress;
        state.lastFX=requestKind ? \none; state.stutter=activeStutter;
        state.manualFX=if(heldFX.notNil) {heldFX.copy} {nil};
        state.currentSerial=current.serial; state.mixBars=if(mixing) {mixLength} {current.mixBars};
        frame=(events:events.sort { |a,b| a.beat < b.beat },automation:automation,decks:deckInfo,bar:bar,stutter:activeStutter);
        if(stutter.notNil) {
            stutter.age=stutter.age+1;
            if(stutter.age>=stutter.bars) {stutter=nil};
        };
        if(heldFX.notNil) {heldFX.age=heldFX.age+1};
        bar=bar+1;
        if(mixing) {
            mixPosition=mixPosition+1;
            if(mixPosition >= mixLength) { current=incoming; incoming=nil; serial=serial+1; mixPosition=0 };
        };
        frame;
    };
    engine=(channel:channel,controls:controls,state:state,nextBar:nextBar,requestNext:{ nextRequested=true },
        requestHook:{ hookRequested=true },requestFill:{ fillRequested=true },requestMutation:{ current[\mutate].value },
        requestFX:{ |kind,bars=1|
            var length=if(bars<1) {0.5} {bars.asInteger.clip(1,4)};
            fxRequested=(kind:kind.asSymbol,bars:length)
        },
        startFX:{ |kind|
            if([\filter,\echo,\wash,\stutter4,\stutter8,\stutter16].includes(kind).not) {
                Error("Unknown DJ effect").throw
            };
            heldRequest=kind;releaseFX=false;
        },
        stopFX:{heldRequest=nil;releaseFX=true});
    engine;
};
// Shared adapters keep live playback and NRT previews on the same routing and controls.
~djMessage={ |event,node,group,bus,bpm|
    var offset=[2,0,0,4][event.lane],message;
    message=[\s_new,event.voice,node,0,group,\out,bus+(event.deck*6)+offset,\freq,event.midinote.midicps,
        \amp,event.amp,\sustain,event.duration*60/bpm,\pan,event.pan,
        \color,event.color,\tone,event.tone,\seed,event.seed];
    if(event.lane==0) {message=message++[\drive,event.drive ? 0.35]};
    if(event[\glide].notNil) {message=message++[\fromFreq,event[\fromNote].midicps,\glide,event[\glide]]};
    message;
};
~djAutomation={ |point,decks|
    Array.fill(2,{ |id|
        var fx=point.fx[id];
        [\n_set,decks[id],\musicGain,point.gains[id][0],\bassGain,point.gains[id][1],
            \drumsGain,point.gains[id][2],\bpm,point.bpm,\fxFilter,fx.filter,\fxCutoff,fx.cutoff,
            \fxResonance,fx.resonance,\fxEcho,fx.echo,\fxDelay,fx.delay,\fxReverb,fx.reverb,\fxStutter,fx.stutter,
            \fxStutterRate,fx.stutterRate,\t_stutter,if(fx.stutterReset) {1} {0}];
    });
};
)
