// Seeded record planning around the original generator's four interacting engines.
// No playback, clocks, file writes, or global random-stream edits.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "library.scd").load;
(root.dirname.dirname.dirname.dirname +/+ "infinite-engine.scd").load;
~makeDJEngine={ |seed=2600,bpm=128,settings|
    var lib=~djLibrary,rng=(seed.abs%2147483646)+1,random,choose,take,nearest,makeRecord,nextBar,engine;
    var bags=(variation:List.new,key:List.new,duration:List.new,hook:List.new,form:List.new,
        major:List.new,minor:List.new);
    var current,incoming,mixPosition=0,mixLength=8,bar=0,serial=0;
    var nextRequested=false,hookRequested=false,fillRequested=false,fxRequested=nil;
    var controls=(chaos:0.25,density:0.55,mutation:0.30,tension:0.20,hold:false);
    var state=(bar:0,bpm:bpm,mixing:false,progress:0,decks:[nil,nil],phase:0,lastFX:\none);
    if(settings.notNil) { settings.keysValuesDo { |key,value| controls[key]=value } };
    bpm=bpm.clip(118,140); state.bpm=bpm;
    random={ rng=(rng*48271)%2147483647; rng/2147483647 };
    choose={ |items| items[(random.value*items.size).floor.asInteger] };
    take={ |bag,size,excluded,preferred|
        var choices,picked;
        if(bag.isEmpty) { size.do { |i| bag.add(i) } };
        choices=bag.asArray.reject { |item| item==excluded };
        if(choices.isEmpty) { choices=bag.asArray };
        picked=if(preferred.notNil and: { choices.includes(preferred) }) { preferred } { choose.value(choices) };
        bag.removeAt(bag.indexOf(picked)); picked;
    };
    nearest={ |note,previous,low=52,high=76|
        var options=[-48,-36,-24,-12,0,12,24,36,48].collect { |octave| note+octave }
            .select { |pitch| (pitch >= low) and: { pitch <= high } };
        options.sort { |a,b| (a-previous).abs < (b-previous).abs }.first;
    };
    makeRecord={ |deck,index,previousKey,previousBpm,entryBars=0|
        var first=index==0,preferred=if(first) {0} {nil},plan,next,key,mode,scale,progression,durations;
        var variation,progressionID,durationID,hookID,formID,form,sections=List.new,total=0,schedule;
        var cursor=0,chordIndex=0,groove,localBar,forcedHook=0,change=false,forcedFill=false;
        var phraseLift=0,lastLead=64,voicing=[55,60,64],patternID,mutations=0,energyBias,wildness,densityBias;
        key=take.value(bags.key,12,previousKey,preferred);
        mode=if(index.even) {\minor} {\major};
        scale=if(mode==\minor) {[0,2,3,5,7,8,10]} {[0,2,4,5,7,9,11]};
        progressionID=take.value(bags[mode],lib[mode].size,nil,preferred);
        durationID=take.value(bags.duration,lib.durations.size,nil,preferred);
        hookID=take.value(bags.hook,lib.hooks.size,nil,preferred);
        formID=take.value(bags.form,lib.forms.size,nil,preferred);
        variation=lib.variations[take.value(bags.variation,lib.variations.size,nil,preferred)].copy;
        if(first) { variation.name="Baseline Groove" };
        progression=lib[mode][progressionID]; durations=lib.durations[durationID]; form=lib.forms[formID];
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
        groove=~makeInfiniteEngine.value(\edm,seed+(index*7919));
        groove.state.key=36+key; groove.state.scale=scale;
        // Cue the incoming intro so its groove arrives by the end of a short mix.
        localBar=if(first) { form[0][1] } { (form[0][1]-entryBars).max(0) };
        patternID=variation.rhythm;
        energyBias=if(first) {1} {choose.value([0.85,0.94,1.0,1.08])};
        wildness=if(first) {1} {choose.value([0.75,0.9,1.1,1.35])};
        densityBias=if(first) {1} {choose.value([0.85,0.95,1.05,1.15])};
        plan=(deck:deck,serial:index,key:key,mode:mode,keyName:lib[\keys][key] ++ " " ++ mode,
            variation:variation,progression:progression,progressionID:progressionID,durations:durations,
            durationID:durationID,hookID:hookID,formID:formID,sections:sections.asArray,schedule:schedule,
            length:total,mixBars:if(form.last[1] >= 16) {choose.value([8,16])} {8},
            targetBpm:if(first) {bpm} {(previousBpm+choose.value([-4,-2,2,4])).clip(122,136)},
            position:localBar,localBar:localBar,section:\groove,hook:false,mutations:0,
            effective:(chaos:0.25,density:0.55,mutation:0.30,tension:0.20),intensity:0.8);
        if(index > 0 and: { plan.targetBpm==previousBpm }) {
            plan.targetBpm=previousBpm+if(previousBpm >= 130) {-2} {2};
        };
        next={
            var local=localBar,chord=schedule[local],part=sections.detect { |item| local < (item.start+item.bars) };
            var section=part.name,progress=(local-part.start)/(part.bars-1).max(1),intensity,effective;
            var events=List.new,source,bassCount=0,hook,drumsOn,bassOn,drumBreak,add,mapped,answer,fill;
            var breakPulse=formID.even and: { local.even };
            var degreeNote={ |degree| 36+key+scale.wrapAt(degree)+(12*(degree div:7)) };
            var notes=[0,2,4].collect { |offset| degreeNote.value(chord.degree+offset) };
            if(local%4==0) { phraseLift=choose.value([-0.07,0,0.04,0.08]) };
            intensity=case { section==\intro } {0.55+(progress*0.25)}
                { section==\groove } {0.84} { section==\hook } {1.0}
                { section==\space } {0.55} { section==\breakdown } {0.35}
                { section==\buildup } {0.55+(progress*0.55)}
                { section==\drop } {1.12} { true } {0.85-(progress*0.28)};
            intensity=((intensity*energyBias)+phraseLift).clip(0.25,1.22);
            // Give the drum lane occasional room to speak inside a record, not
            // only during a handover. Two phrase-ending bars stay fully rhythmic
            // while pitched material steps out of the way.
            drumBreak=[\groove,\hook,\drop].includes(section) and: { [12,13].includes(local%16) };
            effective=(
                chaos:(controls.chaos.clip(0,1)*(0.45+(intensity*0.8))*wildness).clip(0,1),
                // Keep the default set punchy instead of filling every subdivision;
                // the drop still gets more material, but the kick/bass remain legible.
                density:(controls.density.clip(0,1)*(0.25+(intensity*0.78))*densityBias).clip(0,1),
                mutation:(controls.mutation.clip(0,1)*(0.65+(intensity*0.45))).clip(0,1),
                tension:(controls.tension.clip(0,1)*(0.55+(intensity*0.7)
                    +if(section==\buildup) {progress*0.8} {0})).clip(0,1)
            );
            if(controls.hold.not and: { change or: { local%8==0 and: { random.value < effective.mutation } } }) {
                patternID=(patternID+choose.value([1,3,5]))%8;
                groove[\requestMutation].value; mutations=mutations+1;
            };
            change=false;
            effective.keysValuesDo { |name,value| groove.controls[name]=value };
            groove.controls.hold=controls.hold;
            groove.state.progression=[chord.degree];
            fill=forcedFill or: { local%8==7 and: { random.value < (0.35+(effective.chaos*0.5)) } };
            forcedFill=false;
            if(fill) { groove[\requestFill].value };
            source=groove[\nextBar].value;
            hook=([\hook,\drop].includes(section) or: { forcedHook > 0 }) and: { drumBreak.not };
            bassOn=(section != \breakdown or: { breakPulse }) and: { section != \intro or: { progress >= 0.45 } }
                and: { drumBreak.not };
            drumsOn=section != \breakdown;
            answer=(local%4)==3;
            add={ |lane,voice,beat,note,duration,amp,pan=0|
                var human=if(voice==\djKick or: { lane==0 }) {0} {random.value*0.012};
                var velocity=(0.94+(random.value*0.12))*(0.74+(intensity*0.26));
                // The baseline permits chromatic weak notes at extreme settings.
                // Keep the DJ's adventurous movement diatonic to its active key.
                if(lane < 3 and: { scale.includes((note-key)%12).not }) {
                    note=[note-1,note+1].detect { |pitch| scale.includes((pitch-key)%12) };
                };
                events.add((deck:deck,track:(deck*4)+lane,lane:lane,voice:voice,
                    beat:(beat+human).clip(0,3.95),midinote:note,duration:duration.max(0.035),
                    amp:(amp*velocity).clip(0.001,0.65),pan:pan,color:variation.color,
                    tone:(0.20+(effective.tension*0.45)+(intensity*0.19)).clip(0,1),
                    seed:seed+(index*100003)+(localBar*101)+events.size));
            };
            source.do { |event|
                var step=(event.beat*4).round.asInteger,beat=event.beat,voice=event.voice,note=event.midinote;
                var active=true,duration=event.duration,amp=event.amp;
                if(step.odd and: { event.track != 0 }) { beat=beat+variation.swing };
                switch(event.track,
                    0,{
                        active=bassOn;
                        // The original Markov pitches drive a second recurring answer rhythm.
                        if(answer) {
                            var slots=lib.bassAnswers[patternID];
                            if(bassCount < slots.size) { beat=slots[bassCount]*0.25 } { active=false };
                        };
                        if(section==\space and: { step%4 != 0 }) { active=false };
                        if(section==\breakdown and: { step%8 != 0 }) { active=false };
                        if(section==\outro and: { progress > 0.6 } and: { step.odd }) { active=false };
                        duration=if(step%8==0) {0.32+(intensity*0.15)} {0.15+(effective.density*0.12)};
                        note=nearest.value(note,40+key,28,55); voice=\djBass;
                        bassCount=bassCount+1;
                    },
                    1,{
                        active=(hook or: { local%4 < 2 and: { [0,3,6,10,14].includes(step) } })
                            and: { drumBreak.not };
                        // Let the opening kick/bass groove establish itself before
                        // the first record's lead enters.
                        if(first and: { local < (form[0][1]+2) }) { active=false };
                        if(section==\intro and: { progress < 0.5 }) { active=false };
                        if([\space,\breakdown].includes(section) and: { forcedHook==0 }) {
                            active=local%4==0 and: { step==0 };
                        };
                        if(answer and: { step > 10 }) { active=false };
                        if(section==\outro and: { [0,6].includes(step).not }) { active=false };
                        if(hook and: { first.not } and: { step%4 != 0 }) {
                            var indexInHook=((local%2)*8)+(step div:2);
                            note=degreeNote.value(chord.degree+[0,2,4,7].wrapAt(lib.hooks[hookID].wrapAt(indexInHook)))+12;
                        };
                        note=nearest.value(note,lastLead,52,76);
                        if(active) { lastLead=note };
                        duration=duration*if(step==0) {1.2} {0.85};
                        amp=amp*if(hook) {1.08} {0.62}; voice=\djHook;
                    },
                    2,{
                        active=(section != \breakdown) and: { section != \intro or: { progress >= 0.5 } }
                            and: { drumBreak.not };
                        if([\groove,\hook].includes(section) and: { step.odd }) { active=false };
                        if(section==\space and: { step > 6 }) { active=false };
                        if(answer and: { step >= 12 }) { active=false };
                        // Rotate direction by record, retaining a repeated two-bar figure.
                        mapped=case { variation.arpDirection==0 } {step+(local%2)}
                            { variation.arpDirection==1 } {15-step}
                            { variation.arpDirection==2 } {[0,2,1,3].wrapAt(step)}
                            { true } {[0,1,2,3,2,1].wrapAt(step)};
                        note=nearest.value(degreeNote.value(chord.degree+[0,2,4,7].wrapAt(mapped))+12,64,52,76);
                        amp=amp*0.72; voice=\djArp;
                    },
                    3,{
                        active=drumsOn or: { voice==\igHat and: { [6,14].includes(step) } };
                        if(voice==\igKick) {
                            if(section==\breakdown and: { breakPulse } and: { step==0 }) { active=true };
                            voice=\djKick; note=31;
                            if(section==\buildup and: { progress < 0.5 } and: { step%8 != 0 }) { active=false };
                            if((answer or: { section==\buildup and: { progress > 0.9 } }) and: { step==12 }
                                and: { random.value < (effective.chaos*0.35) }) { active=false };
                        };
                        if(voice==\igSnare) {
                            voice=if(variation.color.even) {\djClap} {\djSnare};
                            if(section==\intro and: { progress < 0.25 }) { active=false };
                        };
                        if(voice==\igHat) { voice=\djHat };
                    }
                );
                if(active) { add.value(event.track,voice,beat,note,duration,amp,event.pan) };
            };
            // Pads appear in space; rhythmic chord comping answers the arp elsewhere.
            if(local==chord.start or: { local%4==0 }) {
                voicing=notes.collect { |note,i| nearest.value(note+12,voicing[i],50,72) };
            };
            if([\breakdown,\space].includes(section) and: { local%2==0 } and: { drumBreak.not }) {
                voicing.do { |note,i| add.value(2,\djPad,0,note,5.6,0.03,(i-1)*0.35) };
            } {
                if(drumBreak.not and: { effective.density > 0.25 }) {
                    lib.compRhythms[variation.rhythm].do { |step,j|
                        if((j%2)==(local%2) or: { section==\drop and: { [0,4,8,12].includes(j) } }) {
                            voicing.do { |note,i|
                                add.value(2,\djStab,(step*0.25)+(i*0.008),note,
                                    if(step%2==0) {0.35} {0.19},0.029,(i-1)*0.3);
                            };
                        };
                    };
                };
            };
            if(drumsOn) {
                [3,7,11,15].do { |step|
                    if(random.value < (effective.density*effective.chaos*0.35)) {
                        add.value(3,\djPerc,(step*0.25)+variation.swing,60,0.09,0.026,-0.30);
                    };
                };
                if(section==\buildup and: { progress >= 0.5 }) {
                    [8,10,12,14].do { |step|
                        if(random.value < progress) { add.value(3,\djSnare,step*0.25,50,0.10,0.025+(progress*0.025),-0.08) };
                    };
                    // Quiet texture only near the end of a lift, not an identical riser every bar.
                    if(progress >= 0.8) { add.value(3,\djRise,0,60,3.8,0.025) };
                };
            };
            plan.localBar=local; plan.section=section; plan.hook=hook; plan.drumBreak=drumBreak; plan.intensity=intensity;
            plan.effective=effective; plan.patternID=patternID; plan.mutations=mutations;
            localBar=(localBar+1)%total; plan.position=localBar;
            forcedHook=(forcedHook-1).max(0);
            events.asArray.sort { |a,b| a.beat < b.beat };
        };
        plan[\nextBar]=next; plan[\hookNow]={ forcedHook=4 };
        plan[\mutate]={ change=true }; plan[\fill]={ forcedFill=true }; plan;
    };
    current=makeRecord.value(0,0,nil,bpm);
    nextBar={
        var events=List.new,automation,deckInfo=[nil,nil],mixing,startBpm,endBpm,frame;
        var requestedFX,hotDeck,fxFor;
        var requested=nextRequested and: { bar%4==0 } and: { incoming.isNil };
        var automatic=current.position >= (current.length-current.mixBars);
        if(incoming.isNil and: { requested or: { automatic and: { controls.hold.not } } }) {
            incoming=makeRecord.value(1-current.deck,serial+1,current.key,current.targetBpm,current.mixBars);
            mixLength=current.mixBars; mixPosition=0; nextRequested=false;
        };
        mixing=incoming.notNil;
        requestedFX=fxRequested; fxRequested=nil;
        hotDeck=if(mixing and: { mixPosition >= (mixLength/2) }) { incoming.deck } { current.deck };
        if(hookRequested) {
            if(mixing and: { mixPosition >= (mixLength/2) }) { incoming[\hookNow].value } { current[\hookNow].value };
            hookRequested=false;
        };
        if(fillRequested) { current[\fill].value; fillRequested=false };
        events.addAll(current[\nextBar].value); deckInfo[current.deck]=current;
        if(mixing) { events.addAll(incoming[\nextBar].value); deckInfo[incoming.deck]=incoming };
        startBpm=current.targetBpm; endBpm=if(mixing) {incoming.targetBpm} {startBpm};
        fxFor={ |plan,t,step|
            var section=plan.section, intensity=plan.intensity.clip(0.2,1.25), wave,barT;
            var filter,cutoff,resonance,echo,delay,reverb,stutter;
            // `t` is the deck handover position and is zero outside a mix;
            // hot buttons need their own within-this-bar phase in both cases.
            barT=(step/16).clip(0,1);
            wave=(sin((plan.localBar*0.43)+(step*0.19)+(plan.deck*1.7))*0.5)+0.5;
            filter=case
                { section==\buildup } {0.12+(t*0.46)+(wave*0.06)}
                { [\space,\breakdown].includes(section) } {0.28+(wave*0.13)}
                { [\hook,\drop].includes(section) } {0.035+(wave*0.035)}
                { true } {0.10+(intensity*0.08)+(wave*0.04)};
            cutoff=(900+((1-filter.clip(0,0.92))*10600)+(wave*1200)).clip(650,15500);
            resonance=(0.28+(filter*0.32)+(wave*0.05)).clip(0.18,0.82);
            echo=(0.015+(wave*0.025)+if(section==\space) {0.16} {0}).clip(0,0.32);
            delay=[0.19,0.25,0.33,0.375].wrapAt(plan.localBar+step+plan.deck);
            reverb=(0.08+if([\space,\breakdown].includes(section)) {0.22} {0.03}
                +(wave*0.05)).clip(0,0.48);
            stutter=if(section==\buildup and: {t>0.55}) {0.10*t} {0};
            if(requestedFX.notNil and: { plan.deck==hotDeck }) {
                switch(requestedFX,
                    \filter, { filter=(0.76+(barT*0.18)).clip(0,1); cutoff=(10500-(barT*9300)).clip(700,10500); resonance=0.63 },
                    \echo, { echo=0.88; delay=[0.25,0.375].wrapAt(plan.localBar+step); reverb=0.28 },
                    // Let the wash bloom across the whole quantized bar instead of slamming on.
                    \wash, { var bloom=barT; filter=0.22+(bloom*0.25); cutoff=4200-(bloom*1800);
                        echo=0.12+(bloom*0.43); reverb=0.18+(bloom*0.72) },
                    \stutter, { stutter=0.86; echo=0.18 }
                );
            };
            (filter:filter.clip(0,1),cutoff:cutoff.clip(500,18000),resonance:resonance.clip(0.12,0.9),
                echo:echo.clip(0,1),delay:delay.clip(0.08,0.75),reverb:reverb.clip(0,1),stutter:stutter.clip(0,1));
        };
        automation=Array.fill(17,{ |step|
            var t=if(mixing) { (mixPosition+(step/16))/mixLength } {0};
            var gains=Array.fill(2,{ [0,0,0] });
            var fx=Array.fill(2,{ (filter:0,cutoff:12000,resonance:0.35,echo:0,delay:0.33,reverb:0.14,stutter:0) });
            if(mixing) {
                gains[current.deck]=[(1-(t/0.45)).clip(0,1),(1-(t/0.5)).clip(0,1),1-t];
                gains[incoming.deck]=[((t-0.55)/0.45).clip(0,1),((t-0.55)/0.35).clip(0,1),t];
                fx[current.deck]=fxFor.value(current,t,step);
                fx[incoming.deck]=fxFor.value(incoming,t,step);
            } {
                gains[current.deck]=[1,1,1];
                fx[current.deck]=fxFor.value(current,t,step);
            };
            (beat:step*0.25,bpm:startBpm+((endBpm-startBpm)*t),gains:gains,fx:fx,progress:t,hotFX:requestedFX ? \none)
        });
        state.bar=bar; state.phase=mixPosition; state.bpm=automation[0].bpm;
        state.decks=deckInfo; state.mixing=mixing; state.progress=automation[0].progress;
        state.lastFX=requestedFX ? \none;
        state.currentSerial=current.serial; state.mixBars=if(mixing) {mixLength} {current.mixBars};
        frame=(events:events.sort { |a,b| a.beat < b.beat },automation:automation,decks:deckInfo,bar:bar);
        bar=bar+1;
        if(mixing) {
            mixPosition=mixPosition+1;
            if(mixPosition >= mixLength) { current=incoming; incoming=nil; serial=serial+1; mixPosition=0 };
        };
        frame;
    };
    engine=(controls:controls,state:state,nextBar:nextBar,requestNext:{ nextRequested=true },
        requestHook:{ hookRequested=true },requestFill:{ fillRequested=true },requestMutation:{ current[\mutate].value },
        requestFX:{ |kind| fxRequested=kind.asSymbol });
    engine;
};
// Shared adapters keep live playback and NRT previews on the same routing and controls.
~djMessage={ |event,node,group,bus,bpm|
    var offset=[2,0,0,4][event.lane];
    [\s_new,event.voice,node,0,group,\out,bus+(event.deck*6)+offset,\freq,event.midinote.midicps,
        \amp,event.amp,\sustain,event.duration*60/bpm,\pan,event.pan,
        \color,event.color,\tone,event.tone,\seed,event.seed];
};
~djAutomation={ |point,decks|
    Array.fill(2,{ |id|
        var fx=point.fx[id];
        [\n_set,decks[id],\musicGain,point.gains[id][0],\bassGain,point.gains[id][1],
            \drumsGain,point.gains[id][2],\bpm,point.bpm,\fxFilter,fx.filter,\fxCutoff,fx.cutoff,
            \fxResonance,fx.resonance,\fxEcho,fx.echo,\fxDelay,fx.delay,\fxReverb,fx.reverb,\fxStutter,fx.stutter];
    });
};
)
