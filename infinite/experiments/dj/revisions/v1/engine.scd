// Pure seeded composition and DJ planning. No clocks, synths, or global RNG edits.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "library.scd").load;
~makeDJEngine={ |seed=2600, bpm=128|
    var lib=~djLibrary, rng=(seed.abs % 2147483646) + 1, random, choose, take;
    var variationBag=List.new, keyBag=List.new, durationBag=List.new, hookBag=List.new;
    var progressionBags=(major:List.new,minor:List.new), makeRecord, nextBar, engine;
    var current, incoming, phase=0, bar=0, serial=0, nextRequested=false, hookRequested=false;
    var controls=(chaos:0.25, density:0.60, mutation:0.25, tension:0.20, hold:false);
    var state=(bar:0, bpm:bpm, mixing:false, progress:0, decks:[nil,nil], phase:0);
    var nearest={ |note, previous, low=52, high=84|
        var options=[-36,-24,-12,0,12,24,36].collect { |octave| note + octave }
            .select { |pitch| (pitch >= low) and: { pitch <= high } };
        options.sort { |a,b| (a - previous).abs < (b - previous).abs }.first;
    };
    bpm=bpm.clip(118,140); state.bpm=bpm;
    random={ rng=(rng * 48271) % 2147483647; rng / 2147483647 };
    choose={ |items| items[(random.value * items.size).floor.asInteger] };
    take={ |bag, size, excluded|
        var choices, picked;
        if(bag.isEmpty) { size.do { |i| bag.add(i) } };
        choices=bag.asArray.reject { |item| item == excluded };
        if(choices.isEmpty) { choices=bag.asArray };
        picked=choose.value(choices); bag.removeAt(bag.indexOf(picked)); picked;
    };
    makeRecord={ |deck, index, initialBar=0, previousKey, previousBpm|
        var plan, next, localBar=initialBar, key, mode, scale, progression, durations, schedule=Array.newClear(80);
        var variation, cursor=0, chordIndex=0, motif, bassMemory, lastLead=72, voicing=[60,64,67];
        var forcedHook=0, change=false, progressionID, durationID, hookID;
        key=take.value(keyBag, lib[\keys].size, previousKey);
        mode=if(index.even, \minor, \major);
        scale=if(mode == \minor, [0,2,3,5,7,8,10], [0,2,4,5,7,9,11]);
        progressionID=take.value(progressionBags[mode],lib[mode].size); durationID=take.value(durationBag,lib.durations.size);
        hookID=take.value(hookBag,lib.hooks.size);
        progression=lib[mode][progressionID]; durations=lib.durations[durationID];
        variation=lib.variations[take.value(variationBag, lib.variations.size)]; motif=lib.hooks[hookID].copy;
        bassMemory=Array.fill(32, { |i| if((i % 8) == 0, 0, choose.value([0,0,0,0,4,4,7])) });
        while { cursor < 80 } {
            var length=durations.wrapAt(chordIndex).min(80 - cursor);
            var chord=(start:cursor, bars:length, degree:progression.wrapAt(chordIndex), index:chordIndex);
            length.do { |offset| schedule[cursor + offset]=chord };
            cursor=cursor + length; chordIndex=chordIndex + 1;
        };
        plan=(deck:deck, serial:index, key:key, mode:mode,
            keyName:lib[\keys][key] ++ " " ++ mode, variation:variation,
            progression:progression, progressionID:progressionID, durations:durations, durationID:durationID, hookID:hookID, schedule:schedule,
            targetBpm:if(index == 0, bpm.clip(118,140),
                (previousBpm + choose.value([-4,-2,2,4])).clip(122,136)),
            localBar:localBar, section:\groove, hook:false);
        if(index > 0 and: { plan.targetBpm == previousBpm }) {
            plan.targetBpm=previousBpm + if(previousBpm >= 130, -2, 2);
        };
        next={
            var events=List.new, local=localBar % 80, chord=schedule[local], notes, section;
            var density=controls.density.clip(0,1), chaos=controls.chaos.clip(0,1), tension=controls.tension.clip(0,1);
            var degreeNote, add, hook, bassOn, drumsOn, rhythm=variation.rhythm, slots, pulses;
            degreeNote={ |degree| 36 + key + scale.wrapAt(degree) + (12 * (degree div: 7)) };
            notes=[0,2,4].collect { |offset| degreeNote.value(chord.degree + offset) };
            section=case { local < 16 } { \intro } { local < 32 } { \groove }
                { local < 40 } { \hook } { local < 48 } { \breakdown }
                { local < 56 } { \buildup } { local < 72 } { \drop } { true } { \outro };
            hook=[\hook,\drop].includes(section) or: { forcedHook > 0 };
            bassOn=(section != \breakdown) and: { (section != \intro) or: { local >= 8 } };
            drumsOn=section != \breakdown;
            if(controls.hold.not and: { change or: { local > 0 and: { (local % 16) == 0 }
                and: { random.value < controls.mutation.clip(0,1) } } }) {
                var position=choose.value([1,2,3,4,5,6]);
                motif[position]=(motif[position] + choose.value([-1,1])).clip(0,3);
            };
            change=false;
            add={ |track, voice, step, note, duration, amp, pan=0|
                var swung=step * 0.25 + if(step.odd and: { track != 0 } and: { voice != \djKick }, variation.swing, 0);
                events.add((deck:deck, track:(deck * 4) + track, lane:track, voice:voice, beat:swung,
                    midinote:note, duration:duration, amp:amp, pan:pan, color:variation.color,
                    tone:(0.3 + (tension * 0.35) + if(section == \buildup, (local % 8) * 0.035, 0)).clip(0,1),
                    seed:seed + (index * 1009) + (localBar * 31) + events.size));
            };
            if(bassOn) {
                slots=lib.bassRhythms[rhythm];
                16.do { |step|
                    var active=slots.includes(step), offset=bassMemory.wrapAt((localBar * 16) + step), pitch;
                    if((density < 0.3) and: { (step % 4) != 2 }) { active=false };
                    if((density > 0.8) and: { [7,15].includes(step) }) { active=true };
                    if(active) {
                        if((step % 8) == 0) { offset=0 };
                        pitch=nearest.value(degreeNote.value(chord.degree + offset), notes[0], 28, 47);
                        add.value(0, \djBass, step, pitch, if(step.even, 0.55, 0.34), if(step.even, 0.19, 0.145));
                    };
                };
            };
            slots=lib.hookRhythms[rhythm];
            slots.do { |step, i|
                var active=hook or: { (local.even and: { [0,12].includes(step) }) };
                var degree=chord.degree + [0,2,4,7].wrapAt(motif.wrapAt((localBar * slots.size) + i)), pitch;
                if(section == \intro and: { local < 8 } and: { forcedHook == 0 }) { active=false };
                if(section == \outro and: { step > 4 }) { active=false };
                if(section == \breakdown and: { forcedHook == 0 }) { active=(local % 4 == 0) and: { step == 0 } };
                if((density < 0.25) and: { step.odd }) { active=false };
                if(active) {
                    if(step.odd and: { random.value < (chaos * tension * 0.2) }) { degree=degree + 1 };
                    if(step == 0 and: { (local % 4) == 0 }) { degree=chord.degree };
                    pitch=nearest.value(degreeNote.value(degree) + 24, lastLead, 60,84); lastLead=pitch;
                    add.value(1, \djHook, step, pitch, if(hook, 0.6, 0.9), if(hook, 0.075, 0.045), -0.15);
                };
            };
            if(local == chord.start and: { density >= 0.2 }) {
                voicing=notes.collect { |note, i| nearest.value(note + 24, voicing[i], 52,79) };
                voicing.do { |note,i|
                    add.value(2, \djPad, 0, note, ((chord.bars * 4) - 3).max(0.5), 0.027, (i - 1) * 0.4);
                };
            };
            pulses=(3 + (density * 8)).round.asInteger;
            if(section != \breakdown and: { section != \intro or: { local >= 8 } }) {
                16.do { |step|
                    var position=case { variation.arpDirection == 0 } { step }
                        { variation.arpDirection == 1 } { 15 - step }
                        { variation.arpDirection == 2 } { [0,2,1,3].wrapAt(step) }
                        { true } { [0,1,2,3,2,1].wrapAt(step) };
                    if(((step * pulses) % 16) < pulses and: { random.value > (chaos * 0.1) }) {
                        add.value(2, \djArp, step, nearest.value(degreeNote.value(chord.degree + [0,2,4,7].wrapAt(position)) + 12, 67,52,84),
                            0.22, 0.035, 0.25);
                    };
                };
            };
            16.do { |step|
                if(drumsOn and: { lib.kicks[rhythm].includes(step) }) {
                    if((section != \buildup) or: { local >= 52 } or: { (step % 8) == 0 }) {
                        add.value(3, \djKick, step, 31, 0.65, if(step == 0, 0.42, 0.38));
                    };
                };
                if(drumsOn and: { [4,12].includes(step) } and: { section != \intro or: { local >= 4 } }) {
                    add.value(3, \djSnare, step, 50, 0.25, 0.11, -0.1);
                };
                if(step.even and: { drumsOn or: { [6,14].includes(step) } }) {
                    add.value(3, \djHat, step, 116, if(step % 4 == 2, 0.22, 0.08), if(step % 4 == 2, 0.065,0.035), 0.25);
                };
                if(section == \buildup and: { local >= 52 } and: { step >= 8 }
                    and: { step.even or: { local == 55 } }) {
                    add.value(3, \djSnare, step, 50, 0.13, 0.025 + ((local - 52) * 0.01), -0.1);
                };
            };
            if(section == \buildup and: { local >= 52 }) {
                add.value(3, \djRise, 0, 60, 3.8, 0.025 + ((local - 52) * 0.01));
            };
            plan.localBar=local; plan.section=section; plan.hook=hook;
            localBar=localBar + 1; forcedHook=(forcedHook - 1).max(0);
            events.sort { |a,b| a.beat < b.beat };
        };
        plan[\nextBar]=next;
        plan[\hookNow]={ forcedHook=4 };
        plan[\mutate]={ change=true };
        plan;
    };
    current=makeRecord.value(0,0,16,nil,bpm);
    nextBar={
        var events=List.new, automation, deckInfo=[nil,nil], mixing, startBpm, endBpm, frame;
        var requested=nextRequested and: { (bar % 8) == 0 } and: { incoming.isNil };
        if(requested) { phase=48; nextRequested=false };
        if(phase == 48 and: { incoming.isNil }) {
            if(controls.hold and: { requested.not }) { phase=0 } {
                incoming=makeRecord.value(1 - current.deck, serial + 1,0,current.key,current.targetBpm);
            };
        };
        mixing=incoming.notNil;
        if(hookRequested) {
            if(mixing and: { phase >= 56 }) { incoming[\hookNow].value } { current[\hookNow].value };
            hookRequested=false;
        };
        events.addAll(current[\nextBar].value); deckInfo[current.deck]=current;
        if(mixing) { events.addAll(incoming[\nextBar].value); deckInfo[incoming.deck]=incoming };
        startBpm=current.targetBpm; endBpm=if(mixing) { incoming.targetBpm } { startBpm };
        automation=Array.fill(17, { |step|
            var t=if(mixing, ((phase - 48) + (step / 16)) / 16, 0).clip(0,1);
            var gains=Array.fill(2, { [0,0,0] });
            if(mixing) {
                gains[current.deck]=[(1 - (t / 0.45)).clip(0,1), (1 - (t / 0.5)).clip(0,1), 1-t];
                gains[incoming.deck]=[((t - 0.55) / 0.45).clip(0,1), ((t - 0.55) / 0.35).clip(0,1), t];
            } { gains[current.deck]=[1,1,1] };
            (beat:step * 0.25, bpm:startBpm + ((endBpm - startBpm) * t), gains:gains, progress:t)
        });
        state.bar=bar; state.phase=phase; state.bpm=automation[0].bpm;
        state.decks=deckInfo; state.mixing=mixing; state.progress=automation[0].progress;
        state.currentSerial=current.serial;
        frame=(events:events.sort { |a,b| a.beat < b.beat }, automation:automation, decks:deckInfo, bar:bar);
        bar=bar+1; phase=phase+1;
        if(phase >= 64) { current=incoming; incoming=nil; serial=serial+1; phase=0 };
        frame;
    };
    engine=(controls:controls, state:state, nextBar:nextBar,
        requestNext:{ nextRequested=true }, requestHook:{ hookRequested=true },
        requestMutation:{ current[\mutate].value });
    engine;
};
)
