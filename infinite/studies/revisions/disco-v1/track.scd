// Explicit 32-bar composition. No playback or server side effects.
(
~discoSpec=(id:"study-06-coastal-pocket-v1",title:"Coastal Pocket",bpm:120,bars:32,
    key:"C major / A minor",seed:62000,
    // Two bars each. Rootless keyboard voicings leave room for the bass hook.
    chords:[
        (name:"Am9",root:33,third:3,seventh:10,notes:[48,55,59,64],chop:[55,59,60,64]),
        (name:"Dm9",root:38,third:3,seventh:10,notes:[53,57,60,64],chop:[53,57,60,64]),
        (name:"G13",root:31,third:4,seventh:10,notes:[53,57,59,64],chop:[53,57,59,64]),
        (name:"Cmaj9",root:36,third:4,seventh:11,notes:[52,55,59,62],chop:[52,55,59,62])
    ],
    sections:[\settle,\pocket,\hook,\answer,\breath,\lift,\return,\close],
    // [onset, chord-relative role, duration in beats, velocity]. Repeat, don't redraw.
    bassA:[
        [0,\root,0.46,1.0],[0.75,\fifth,0.18,0.73],[1.5,\octave,0.22,0.86],
        [2,\root,0.42,0.96],[2.75,\seventh,0.16,0.67],
        [3.25,\fifth,0.26,0.82],[3.75,\octave,0.13,0.65]
    ],
    bassB:[
        [0,\root,0.50,1.0],[0.75,\third,0.21,0.78],[1.5,\fifth,0.24,0.84],
        [2,\octave,0.25,0.88],[2.75,\seventh,0.15,0.62],
        [3,\fifth,0.23,0.79],[3.5,\third,0.17,0.73],[3.75,\fifth,0.13,0.65]
    ],
    // Eight-bar melody; MIDI 53..67 only. Calls and answers share the backing's register.
    hook:[
        [[0,64,0.40],[0.75,64,0.15],[1.5,67,0.40],[2.25,64,0.50],[3.25,60,0.40]],
        [[0,59,0.55],[0.75,60,0.30],[1.5,64,0.60],[3,57,0.60]],
        [[0,65,0.40],[0.75,65,0.15],[1.5,64,0.40],[2.25,60,0.50],[3.25,57,0.40]],
        [[0,60,0.60],[1.5,57,0.40],[2.75,53,0.45]],
        [[0,59,0.40],[0.75,59,0.15],[1.5,62,0.40],[2.25,64,0.50],[3.25,62,0.40]],
        [[0.5,59,0.60],[1.75,57,0.35],[2.5,55,0.80]],
        [[0,64,0.60],[1.5,62,0.30],[2.25,59,0.50],[3.25,55,0.40]],
        [[0.5,59,0.40],[1.5,60,0.50],[3,60,0.70]]
    ]
);

~discoEvents={
    var spec=~discoSpec,events=List.new,ordinal=0,add,swing;
    // 55% sixteenth swing. Other positions retain their written timing.
    swing={ |beat| beat+if(((beat*4).round.asInteger%2)==1) { 0.025 } { 0 } };
    add={ |voice,beat,note=60,amp=0.1,duration=0.2,lane=0,pan=0,tone=0.4|
        if(beat < 128) {
            events.add((voice:voice,beat:beat,midinote:note,amp:amp,duration:duration,
                lane:lane,pan:pan,tone:tone,seed:spec.seed+ordinal));
            ordinal=ordinal+1;
        };
    };
    32.do { |bar|
        var at=bar*4,chord=spec.chords[(bar.div(2))%4],section=spec.sections[bar.div(4)];
        var thin=(bar >= 16) and: { bar < 18 },intro=bar < 4,closing=bar >= 30;
        var tone=if(section==\lift) { 0.25+((bar-20)*0.12) } { 0.46 };
        var bassPattern=if(bar.even) { spec.bassA } { spec.bassB };
        var roles=(root:0,third:chord.third,fifth:7,seventh:chord.seventh,octave:12);
        var keyHits,chopHits,hookOn;

        // Four-to-floor foundation; a two-bar breath and a deliberate last-beat omission.
        if(thin.not) {
            4.do { |beat|
                if(((bar==15) and: { beat==3 }).not and: { ((bar==31) and: { beat==3 }).not }) {
                    add.value(\discoKick,at+beat,60,if(beat.even) {0.53} {0.49},0.2,2);
                };
            };
        };
        if(thin.not or: { bar==17 }) {
            [1,3].do { |beat|
                add.value(\discoClap,at+beat+0.014,60,if(intro) {0.15} {0.18},0.2,2,0.04);
            };
        };
        8.do { |step|
            var pos=step*0.5,off=step.odd;
            if(thin.not or: { off }) {
                add.value(\discoHat,at+pos+if(off) {0.009} {0},60,
                    if(off) {0.058} {0.028}*if(thin) {0.55} {1},
                    if(off and: { intro.not }) {0.20} {0.075},2,0.24);
            };
        };
        if(bar >= 4 and: { thin.not }) {
            16.do { |step|
                if([0,3,4,6,8,11,12,14,15].includes(step)) {
                    add.value(\discoShake,at+swing.value(step*0.25)+0.008,60,
                        if(step%4==2) {0.065} {0.035},0.05,2,-0.32);
                };
            };
            if(bar%2==1) { add.value(\discoRim,at+2.75+0.025,60,0.045,0.1,2,-0.22) };
        };
        if([7,15,23,31].includes(bar)) {
            [2.5,3.25,3.75].do { |pos,i|
                add.value(\discoRim,at+swing.value(pos),60,[0.045,0.06,0.04][i],0.1,2,-0.18);
            };
        };

        // Bass is the main recurring hook. The breath keeps just its first two anchors.
        bassPattern.do { |item,i|
            if(thin.not or: { [0,3].includes(i) }) {
                if(((bar==31) and: { item[0]>=2 }).not) {
                    add.value(\discoBass,at+swing.value(item[0]),chord.root+roles[item[1]],
                        0.32*item[3],item[2],1,0,tone);
                };
            };
        };
        if(bar==31) { add.value(\discoBass,at+2,36,0.31,1.45,1,0,0.35) };

        // Warm electric keys: syncopated comping, not a stream of new random chords.
        keyHits=if(thin) { [[0,3.2,0.11]] } {
            if(bar.even) { [[0,1.1,0.105],[1.75,0.6,0.07],[3.25,0.4,0.08]] } {
                [[0.5,0.8,0.09],[2,1,0.085]]
            }
        };
        if(bar==31) { keyHits=[[0.5,0.65,0.08],[2,1.5,0.12]] };
        keyHits.do { |hit|
            chord.notes.do { |note,i|
                add.value(\discoKeys,at+swing.value(hit[0])+(i*0.006),note,hit[2],hit[1],
                    0,[-0.35,-0.12,0.12,0.35][i],tone);
            };
        };

        // Damped, strummed chord chops, with an eight-bar rhythmic vocabulary.
        chopHits=if(bar%4==3) { [0.5,1.5,2.25,3.5] } { [0.5,1.5,2.75,3.5] };
        if(intro) { chopHits=if(bar < 2) { [1.5,3.5] } { [0.5,2.75,3.5] } };
        if(thin) { chopHits=[] };
        if(closing) { chopHits=if(bar==31) { [0.5,1.5] } { [0.5,2.75,3.5] } };
        chopHits.do { |pos,j|
            chord.chop.do { |note,i|
                add.value(\discoChop,at+swing.value(pos)+0.016+(i*0.008),note,
                    if(intro) {0.12} {0.18}*if(j==1) {0.82} {1},0.22,0,
                    if(j.even) {-0.4} {0.36},tone);
            };
        };

        // The full eight-bar melody appears twice, separated by breathing room.
        hookOn=((bar >= 8) and: { bar < 16 }) or: { (bar >= 24) and: { bar < 32 } };
        if(hookOn) {
            spec.hook[bar%8].do { |item,i|
                add.value(\discoReed,at+swing.value(item[0])+0.012,item[1],
                    if(i==0) {0.12} {0.103},item[2],0,0.06,tone);
            };
        };
        // A low-volume two-note hint before the first theme, and a pickup into its return.
        if(bar==7) {
            add.value(\discoReed,at+2.5,59,0.075,0.3,0,0.06,0.25);
            add.value(\discoReed,at+3.25+0.025,60,0.08,0.35,0,0.06,0.25);
        };
        if(bar==23) {
            add.value(\discoReed,at+2.5,60,0.085,0.35,0,0.06,0.35);
            add.value(\discoReed,at+3.25+0.025,62,0.09,0.35,0,0.06,0.4);
        };
    };
    events.asArray.sort { |a,b| a.beat < b.beat };
};
~discoMessage={ |event,node,group,bus|
    [\s_new,event.voice,node,0,group,\out,bus+(event.lane*2),
        \freq,event.midinote.midicps,\amp,event.amp,\sustain,event.duration*(60/~discoSpec.bpm),
        \pan,event.pan,\tone,event.tone,\seed,event.seed];
};
~discoMixArgs={ |bus| [\in,bus,\bpm,~discoSpec.bpm,\gain,1.75,\wet,0.10,\delay,0.085] };
)
