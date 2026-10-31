// Composition only: no server, clock, playback, or global random-stream changes.
(
~makeInfiniteEngine = { |mode=\edm, seed=2600, settings|
    var bar=0, randomState=(seed.abs % 2147483646) + 1;
    var random, choose, weighted, degreeNote, nextBar, controls, state;
    var bassMemory, bassState=0, leadMemory, bassPattern, leadPattern;
    var fillRequested=false, mutationRequested=false, mutate, engine;
    if([\edm, \soundscape].includes(mode).not) { Error("Mode must be edm or soundscape").throw };
    controls=(chaos:0.25, density:0.55, mutation:0.30, tension:0.20, hold:false, arpProbability:0.96);
    if(settings.notNil) { settings.keysValuesDo { |k, v| controls[k]=v } };
    state=(key:36, scale:[0, 2, 3, 5, 7, 8, 10], progression:[0, 5, 2, 6],
        chord:[0, 3, 7], chordDegree:0, bar:0, tension:0.2, section:\groove);
    random = { randomState=(randomState * 48271) % 2147483647; randomState / 2147483647 };
    choose = { |items| items[(random.value * items.size).floor.asInteger] };
    weighted = { |weights|
        var target=random.value * weights.sum, total=0, result=weights.size - 1, found=false;
        weights.do { |weight, i|
            total=total + weight;
            if(found.not and: { target < total }) { result=i; found=true };
        };
        result;
    };
    degreeNote = { |degree| state.key + state.scale.wrapAt(degree) + (12 * (degree div: 7)) };
    // States: root, fifth, octave, diatonic approach. Memory is a two-bar phrase.
    bassMemory=Array.fill(32, { |i|
        if((i % 8) == 0) { bassState=0 } {
            bassState=weighted.value([
                [0.70, 0.23, 0.06, 0.01], [0.82, 0.10, 0.07, 0.01],
                [0.77, 0.18, 0.04, 0.01], [0.94, 0.04, 0.02, 0]
            ][bassState]);
        };
        bassState;
    });
    bassPattern=[0, 3, 4, 6, 8, 10, 11, 14];
    leadPattern=[0, 3, 6, 7, 10, 12, 14];
    // Indices into a chord-tone ladder. Recognizable call and response, then space.
    leadMemory=[0, 0, 1, 2, 1, 2, 1, 0, 0, 1, 2, 1, 0, 1, 2, 1,
        0, 1, 2, 1, 0, 2, 1, 0, 0, 1, 2, 1, 2, 1, 0, 0];
    mutate = { |chaos, tension|
        var index=choose.value([3, 6, 10, 11, 14, 19, 22, 26, 27, 30]);
        var from=bassMemory.wrapAt(index - 1), old=bassMemory[index];
        bassMemory[index]=weighted.value([
            [0.68, 0.24, 0.08, tension * chaos * 0.25],
            [0.82, 0.10, 0.08, tension * chaos * 0.2],
            [0.78, 0.18, 0.04, tension * chaos * 0.2],
            [0.95, 0.04, 0.01, 0]
        ][from]);
        if(bassMemory[index] == old) { bassMemory[index]=if(old == 0, 1, 0) };
        index=choose.value([3, 6, 7, 10, 12, 14, 19, 22, 23, 26, 28, 30]);
        leadMemory[index]=choose.value([leadMemory[index] - 1, leadMemory[index] + 1]
            .select { |degree| (degree >= 0) and: { degree <= 4 } });
    };
    nextBar = {
        var events=List.new, chaos=controls.chaos.clip(0, 1), density=controls.density.clip(0, 1);
        var mutation=controls.mutation.clip(0, 1), tension=controls.tension.clip(0, 1);
        var chordDegree, chord, chordLadder=[0, 2, 4, 7, 9], section=(bar div: 8) % 4;
        var fill, adventure=(bar % 4) / 3, bassCount=0, add, pulses;
        var soundRoot;
        state.bar=bar; state.bpm=engine.bpm;
        chordDegree=state.progression[(bar div: 2) % state.progression.size];
        chord=[0, 2, 4].collect { |offset| degreeNote.value(chordDegree + offset) };
        state.chordDegree=chordDegree; state.chord=chord; state.tension=tension;
        state.section=[\groove, \lift, \space, \return][section];
        fill=fillRequested or: { ((bar % 8) == 7) and: { random.value < (0.45 + (chaos * 0.4)) } };
        fillRequested=false;
        if(controls.hold.not and: {
            mutationRequested or: { (bar > 0) and: { (bar % 4) == 0 } and: { random.value < mutation } }
        }) { mutate.value(chaos, tension) };
        mutationRequested=false;
        add = { |track, voice, step, note, duration, amp, pan=0|
            events.add((track:track, voice:voice, beat:step * 0.25,
                midinote:note, duration:duration, amp:amp, pan:pan));
        };
        if(mode == \edm) {
            16.do { |step|
                var anchor=[0, 6, 8, 14].includes(step);
                var active=anchor or: { bassPattern.includes(step) and: { density >= 0.3 } };
                var note, memory=bassMemory[((bar % 2) * 16) + step];
                if((section == 1) and: { density >= 0.45 } and: { [7, 15].includes(step) }) { active=true };
                if(active.not and: { density > 0.65 }) {
                    active=random.value < ((density - 0.65) * 1.6);
                };
                if(active) {
                    // Roots on strong beats; high tension only permits weak-beat approaches.
                    if((step % 8) == 0) { memory=0 };
                    note=degreeNote.value(chordDegree + [0, 4, 7, 6][memory]);
                    if((memory == 3) and: { tension < 0.45 }) { note=chord[0] };
                    add.value(0, \igBass, step, note, 0.18, if(anchor, 0.19, 0.135));
                    bassCount=bassCount + 1;
                };
            };
            16.do { |step|
                var active=leadPattern.includes(step), index=((bar % 2) * 16) + step;
                var degree=chordDegree + chordLadder[leadMemory[index]], note;
                // Space every fourth bar; a busier bass also leaves the lead more room.
                if(((bar % 4) == 3) and: { step > 10 }) { active=false };
                if((density < 0.3) and: { [0, 6, 12].includes(step).not }) { active=false };
                if((section == 2) and: { step > 7 }) { active=false };
                if((bassCount > 10) and: { step.odd } and: { random.value < 0.5 }) { active=false };
                if(active) {
                    if(step.odd and: { random.value < (chaos * tension * adventure) }) {
                        degree=degree + choose.value([-1, 1]);
                    };
                    // Every four-bar boundary resolves explicitly to the new chord root.
                    if((step == 0) and: { (bar % 4) == 0 }) { degree=chordDegree };
                    note=degreeNote.value(degree) + 24;
                    if(step.odd and: { tension > 0.7 } and: { chaos > 0.5 }
                        and: { random.value < ((tension - 0.7) * chaos * adventure) }) { note=note + 1 };
                    add.value(1, \igLead, step, note, if(step == 0, 0.38, 0.19),
                        if(step == 0, 0.075, 0.052), -0.18);
                };
            };
            // Evenly spaced Euclidean hits, rotated onto offbeats; density sets pulse count.
            pulses=(3 + (density * 11) + if(section == 1, 1, 0)).round.asInteger.clip(3, 14);
            state.arpPulses=pulses;
            16.do { |step|
                var rotated=(step + if(section == 3, 13, 15)) % 16;
                var hit=((rotated * pulses) % 16) < pulses;
                var probability=(controls.arpProbability - (chaos * 0.12)).clip(0, 1);
                var note=degreeNote.value(chordDegree + [0, 2, 4, 7].wrapAt(step + (bar % 2))) + 12;
                if((section == 2) and: { step > 7 }) { hit=false };
                if(hit and: { random.value < probability }) {
                    add.value(2, \igArp, step, note, 0.14, if(step.odd, 0.062, 0.045), 0.28);
                };
            };
            16.do { |step|
                var accent, omit;
                if((step % 4) == 0) {
                    omit=(step == 12) and: { (bar % 8) == 7 } and: { random.value < (chaos * 0.2) };
                    if(omit.not) { add.value(3, \igKick, step, 31, 0.5, if(step == 0, 0.48, 0.42)) };
                };
                if([4, 12].includes(step)) { add.value(3, \igSnare, step, 50, 0.16, 0.12, -0.08) };
                accent=(step % 4) == 2;
                if(accent or: { step.even and: { density >= 0.3 } }
                    or: { step.odd and: { random.value < (density.squared * 0.55) } }) {
                    if(accent or: { random.value > (chaos * 0.18) }) {
                        add.value(3, \igHat, step, 116, if(accent, 0.13, 0.045),
                            if(accent, 0.09, 0.045), 0.25);
                    };
                };
                if(fill and: { step >= 13 }) {
                    add.value(3, \igSnare, step, 50, 0.09, 0.035 + ((step - 13) * 0.02), -0.08);
                };
            };
        } {
            // Preserve the four-role soundscape mode, using the same harmonic state.
            soundRoot=chord[0];
            if(bar.even) { add.value(0, \igCloud, 0, soundRoot - 12, 12, 0.12) };
            add.value(1, \igCloud, 0, choose.value(chord) + 12, 8, 0.09, -0.45);
            if(random.value < (0.2 + (density * 0.7))) {
                add.value(2, \igLead, choose.value([0, 4, 8, 12]), choose.value(chord) + 24, 3, 0.035, 0.45);
            };
            if(bar.even) { add.value(3, \igAir, 0, 78 + (tension * 12), 10, 0.12, 0.2) };
        };
        bar=bar + 1;
        events.sort { |a, b| a.beat < b.beat };
    };
    engine=(nextBar:nextBar, mode:mode, bpm:if(mode == \edm, 120, 60), controls:controls, state:state,
        requestFill:{ fillRequested=true }, requestMutation:{ mutationRequested=true });
    engine;
};
// One audio adapter for all four tracks; drums share a lane with named subvoices.
~infiniteMessage = { |event, engine, node, group, bus|
    [\s_new, event.voice, node, 0, group, \out, bus,
        \freq, event.midinote.midicps, \amp, event.amp,
        \sustain, event.duration * 60 / engine.bpm, \pan, event.pan]
};
)
