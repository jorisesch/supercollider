// Voltage Heart. All positions and written note lengths are in beats.
{
    |transpose = -2| // Written in F-sharp minor. The default plays in E minor.
    var bpm = 134, beatSeconds = 60 / bpm, bars = 40, events = List.new;
    var voicings, roots, hook, bassLines, turnaround, add, playHook, playChord, fillDrums, frequency;
    frequency = { |midi| (midi + transpose).midicps };
    voicings = [[54,61,64,69],[57,62,66,69],[57,64,69,73],[56,59,64,71],[56,59,61,65]];
    roots = [30,38,33,40,37]; // F# minor, D major, A major, E major, C#7.
    // The opening C#–C#–E pickup groups the first two beats 3+3+2.
    hook = [
        [[0,73,0.42],[0.75,73,0.22],[1.50,76,0.31],[2,78,0.62],[3,76,0.19],[3.50,73,0.30]],
        [[0,74,0.63],[1,73,0.28],[1.50,69,0.34],[2.50,74,1.03]],
        [[0,73,0.42],[0.75,73,0.22],[1.50,76,0.31],[2,81,0.66],[3,78,0.20],[3.50,76,0.30]],
        [[0,71,0.50],[0.75,76,0.38],[1.50,78,0.36],[2,76,0.95],[3.50,73,0.26]],
        [[0,73,0.42],[0.75,73,0.22],[1.50,76,0.31],[2,78,0.79],[3.25,81,0.40]],
        [[0,81,0.52],[1,78,0.32],[1.75,76,0.24],[2.25,74,0.73],[3.50,69,0.31]],
        [[0,73,0.42],[0.75,73,0.22],[1.50,76,0.31],[2,81,0.64],[3,83,0.20],[3.50,81,0.30]],
        [[0,80,0.47],[0.75,76,0.29],[1.50,71,0.35],[2,76,0.52],[3,73,0.24]]
    ];
    // Each bass event carries an offset in semitones, duration and velocity.
    bassLines = [
        [[0.50,0,0.36,1],[1.50,0,0.33,0.88],[2.50,0,0.37,1],[3.50,0,0.34,0.93]],
        [[0.50,0,0.36,1],[1.25,0,0.22,0.85],[1.75,12,0.16,0.60],
            [2.50,0,0.37,1],[3.50,0,0.35,0.90]],
        [[0.50,0,0.36,1],[1.50,0,0.33,0.87],[2.50,0,0.38,1],
            [3.25,0,0.20,0.84],[3.75,7,0.14,0.63]]
    ];
    turnaround = [
        [[2.50,52,0.12,-0.16],[3.00,48,0.17,0.16],[3.50,43,0.23,-0.11]],
        [[2.25,50,0.14,0.16],[3.00,47,0.17,-0.13],[3.50,43,0.21,0.10],[3.75,50,0.12,-0.10]]
    ];
    add = { |beat, voice, bus, args|
        events.add([beat * beatSeconds, voice, [\out,bus,\seed,1800 + events.size] ++ args]);
    };
    playHook = { |beat, notes, octave, amp, tone, stop=4|
        notes.do { |note, i|
            if(note[0] < stop) {
                add.value(beat + note[0], \vhLead, 24, [\freq,frequency.value(note[1] + octave),
                    \sustain,note[2].min(stop - note[0]) * beatSeconds,
                    \amp,amp * [1,0.82,0.94,1,0.82,0.91].wrapAt(i),\tone,tone]);
            };
        };
    };
    playChord = { |at, chord, voice, length, amp, tone|
        voicings[chord].do { |pitch, i|
            add.value(at + (i * 0.009), voice, 16, [\freq,frequency.value(pitch),\sustain,length * beatSeconds,
                \amp,amp * [0.80,0.96,1,0.94][i],\tone,tone,\pan,[0,-0.48,0.42,0.18][i]]);
        };
    };
    fillDrums = { |beat, variation|
        turnaround[variation].do { |note|
            add.value(beat + note[0], \vhTom, 20, [\freq,note[1].midicps,\amp,note[2],\pan,note[3]]);
        };
        add.value(beat + [3.26,3.48][variation], \vhSnare, 20,
            [\amp,0.13,\sustain,0.083,\pan,-0.05]);
    };

    bars.do { |bar|
        var beat = bar * 4, phase = bar % 4, chord = phase, notes = hook[bar % 8];
        var intro = bar < 4, groove = bar >= 4 and: {bar < 12};
        var breakdown = bar >= 12 and: {bar < 16};
        var build = bar >= 16 and: {bar < 20}, drop = bar >= 20 and: {bar < 36};
        var last = bar == 39, tag = bar >= 36;
        var fill = [7,11,23,27,31,35].includes(bar);
        var floor = groove or: {drop or: {tag}};
        var bassLine;

        if(bar == 15 or: {bar == 19}) { chord = 4 };

        // Start with the hook in a smaller register, then bring it up an octave for the drop.
        if(intro) {
            playChord.value(beat, chord, \vhPad, 3.55, 0.094, 0.34);
            playHook.value(beat, notes, -12, 0.27, 0.36, if(bar == 3) {2.75} {4});
            if(bar == 2 or: {bar == 3}) {
                [0,2].do { |at| add.value(beat + at, \vhKick, 22, [\amp,0.43]) };
            };
            if(bar == 3) { fillDrums.value(beat, 0) };
        };

        if(groove or: {drop or: {tag and: {last.not}}}) {
            playHook.value(beat, notes, if(groove) {-12} {0}, if(drop) {0.49} {0.38},
                if(drop) {0.82} {0.56}, if(fill) {3.17} {4});
            playChord.value(beat, chord, \vhPad, if(fill) {2.55} {3.55},
                if(drop) {0.081} {0.061}, if(drop) {0.58} {0.47});
            (if(bar >= 28) {[[0.75,0.34],[1.50,0.25],[2.75,0.40]]}
                {[[0.50,0.26],[2.50,0.40]]}).do { |accent|
                playChord.value(beat + accent[0], chord, \vhStab, accent[1],
                    if(drop) {0.135} {0.098}, if(drop) {0.77} {0.50});
            };
            if([20,28].includes(bar)) {
                // Land the downbeat with a wide tonic stab and a lower octave hook double.
                playChord.value(beat, chord, \vhStab, 0.50, 0.16, 0.84);
                playHook.value(beat, notes, -12, 0.21, 0.53, 3.12);
                add.value(beat + 0.24, \vhBass, 18, [\freq,frequency.value(roots[chord]),
                    \sustain,0.19 * beatSeconds,\amp,0.45,\tone,0.63]);
            };
            if([29,33].includes(bar)) {
                add.value(beat + 2.5, \vhLead, 24, [\freq,frequency.value(69),\sustain,0.38,\amp,0.15,\tone,0.62,\pan,0.27]);
            };
        };

        if(floor) {
            4.do { |i|
                if((fill.not or: {i < 3}) and: {last.not or: {i <= 2}}) {
                    add.value(beat + i, \vhKick, 22, [\amp,[0.72,0.65,0.70,0.65][i] * if(groove) {0.94} {1}]);
                };
                if(i.odd and: {(fill.not or: {i == 1}) and: {last.not or: {i == 1}}}) {
                    add.value(beat + i + 0.013, \vhClap, 20, [\amp,if(drop) {0.29} {0.24}]);
                };
                if((fill.not or: {i < 2}) and: {last.not}) {
                    add.value(beat + i + 0.51, \vhHat, 20, [\amp,[0.075,0.053,0.069,0.052][i],
                        \sustain,[0.107,0.043,0.093,0.044][i],\pan,[0.29,-0.23,0.23,-0.29][i]]);
                };
            };
            if(fill) { fillDrums.value(beat, (bar div: 4) % 2) };
            bassLine = bassLines[if(bar < 8) {0} {(phase % 2) + 1}];
            bassLine.do { |note|
                if((fill.not or: {note[0] < 3}) and: {last.not or: {note[0] < 1.75}}) {
                    add.value(beat + note[0], \vhBass, 18, [\freq,frequency.value(roots[chord] + note[1]),
                        \sustain,note[2] * beatSeconds,\amp,note[3] * if(drop) {0.54} {0.40},
                        \tone,if(drop) {0.76} {0.42}]);
                };
            };
        };

        if(breakdown) {
            playChord.value(beat, chord, \vhPad, 3.66, 0.135, 0.43);
            playHook.value(beat, if(bar == 15) {[[0,80,0.64],[1.50,73,0.30],[2,77,0.49],[3,80,0.42]]}
                {notes.select { |note| [0,1.5,2,2.5].includes(note[0]) }},
                -12, 0.27, if(bar == 15) {0.45} {0.28});
        };

        if(build) {
            playChord.value(beat, chord, \vhPad, if(bar == 19) {2.28} {3.67},
                0.12, 0.48 + ((bar - 16) * 0.08));
            // Delay the octave lift until the drop. Shorten the last dominant notes into the snare roll.
            playHook.value(beat, if(bar == 19) {
                [[0,73,0.41],[0.75,73,0.23],[1.50,77,0.23],[2,80,0.24],[2.67,77,0.18],[3,80,0.15]]
            } {notes}, -12, 0.33 + ((bar - 16) * 0.037), 0.44 + ((bar - 16) * 0.10), 3.2);
            if(bar == 16) {
                add.value(beat, \vhRiser, 20, [\amp,0.29,\sustain,15.05 * beatSeconds]);
            };
            if(bar < 18) {
                [0,2].do { |at| add.value(beat + at, \vhKick, 22, [\amp,0.52]) };
            };
            (switch(bar,
                16, { [1,3] },
                17, { [0,1,2,3,3.50] },
                18, { Array.series(8,0,0.5) },
                19, { [0,0.50,1,1.33,1.67,2,2.25,2.50,2.75,3,3.25] }
            )).do { |at, i|
                add.value(beat + at, \vhSnare, 20, [\amp,0.10 + (i * 0.014) + ((bar - 16) * 0.020),
                    \sustain,if(bar == 19) {0.067} {0.09},\pan,[-0.14,0.14].wrapAt(i)]);
            };
        };

        if([4,20,28].includes(bar)) {
            add.value(beat, \vhImpact, 20, [\amp,if(bar == 20) {0.35} {0.16}]);
        };
        if(last) {
            playHook.value(beat, [[0,80,0.40],[0.75,76,0.33],[1.50,73,0.24],[2,78,1.41]], 0, 0.43, 0.75);
            playChord.value(beat, 3, \vhPad, 1.55, 0.08, 0.47);
            playChord.value(beat + 2, 0, \vhPad, 1.65, 0.12, 0.55);
            playChord.value(beat + 2, 0, \vhStab, 0.75, 0.15, 0.80);
            add.value(beat + 2.23, \vhBass, 18, [\freq,frequency.value(30),\sustain,0.63,\amp,0.42,\tone,0.56]);
            add.value(beat + 2, \vhImpact, 20, [\amp,0.14]);
        };
    };
    (bpm: bpm, seconds: bars * 4 * beatSeconds, events: events.asArray.sort { |a,b| a[0] < b[0] })
}
