// Five composed listening studies. Hook notes are absolute MIDI notes, with explicit
// onsets and lengths in beats: [beat within four-bar phrase, note, duration].
(
~studySpecs=[
    (id:"study-01-afterglow",title:"Afterglow",bpm:124,key:"A minor",keyPC:9,
        scale:[0,2,3,5,7,8,10],family:0,lead:\studyBell,swing:0.025,
        gain:1.8,room:0.78,wet:0.22,delay:0.18,duck:0.42,
        sections:[\groove,\tease,\theme,\theme,\break,\build,\drop,\close],
        chords:[
            (root:33,notes:[55,59,60,64],bars:2,name:"Am9"),
            (root:29,notes:[57,60,64,67],bars:2,name:"Fmaj9"),
            (root:36,notes:[55,59,62,64],bars:2,name:"Cmaj9"),
            (root:31,notes:[55,59,62,69],bars:2,name:"Gadd9")],
        bass:[[0,0,0.55,1],[1.5,0,0.3,0.7],[2.5,7,0.35,0.8],[3.5,12,0.32,0.7]],
        a:[[0,76,0.75],[1,72,0.5],[1.75,71,0.25],[2,69,1.3],[3.5,72,0.4],
            [4,76,1],[5.5,79,0.5],[6,76,1],[7.5,74,0.4],[8,72,1.4],[10,71,0.75],
            [11,69,0.7],[12,67,1],[13.5,69,0.45],[14,71,0.45],[15,72,0.75]],
        b:[[0,79,1.5],[2,76,0.5],[3,74,0.8],[4,76,1.3],[6,74,0.5],[7,72,0.7],
            [8,74,1],[9.5,71,0.5],[10.5,69,0.5],[11.5,67,0.4],[12,71,0.75],
            [13,74,0.75],[14,72,0.5],[15,69,0.75]]),
    (id:"study-02-glassline",title:"Glassline",bpm:128,key:"D minor",keyPC:2,
        scale:[0,2,3,5,7,8,10],family:1,lead:\studyPluck,swing:0.012,
        gain:1.8,room:0.78,wet:0.19,delay:0.19,duck:0.5,
        sections:[\intro,\theme,\theme,\answer,\break,\build,\drop,\close],
        chords:[
            (root:38,notes:[53,60,64,69],bars:4,name:"Dm9"),
            (root:34,notes:[53,57,60,62],bars:4,name:"Bbmaj9"),
            (root:29,notes:[52,57,60,67],bars:4,name:"Fmaj9"),
            (root:36,notes:[55,60,62,64],bars:4,name:"Cadd9")],
        bass:[[0.5,0,0.35,1],[1.5,0,0.35,0.9],[2.25,7,0.25,0.7],[2.75,0,0.25,0.8],[3.5,12,0.35,0.75]],
        a:[[0,69,0.5],[0.75,74,0.75],[2,77,1],[3,76,0.5],[4,74,1.5],
            [6,69,0.75],[7,72,0.5],[8,74,0.75],[9,77,0.75],[10,81,1.5],
            [12,79,0.5],[13,77,0.5],[14,76,0.5],[15,74,0.75]],
        b:[[0,77,1],[1.5,76,0.5],[2.5,74,0.75],[4,72,1.5],[6,69,0.75],[7,72,0.5],
            [8,74,1.5],[10,76,0.5],[11,77,0.75],[12,76,0.75],[13.5,72,0.5],[14.5,74,1.25]]),
    (id:"study-03-night-circuit",title:"Night Circuit",bpm:130,key:"F# minor",keyPC:6,
        scale:[0,2,3,5,7,8,10],family:2,lead:\studyStab,swing:0.008,
        gain:1.75,room:0.62,wet:0.11,delay:0.11,duck:0.55,
        sections:[\groove,\groove,\theme,\answer,\break,\build,\drop,\close],
        chords:[
            (root:42,notes:[57,61,66,68],bars:2,name:"F#m9"),
            (root:38,notes:[54,57,61,64],bars:2,name:"Dmaj9"),
            (root:33,notes:[56,59,61,64],bars:2,name:"Amaj9"),
            (root:40,notes:[56,59,64,66],bars:2,name:"Eadd9")],
        bass:[[0,0,0.28,1],[0.75,0,0.2,0.7],[1.5,7,0.25,0.8],[2,0,0.32,1],
            [2.75,12,0.2,0.7],[3.5,7,0.25,0.8]],
        a:[[0,66,0.35],[0.75,66,0.25],[1.5,69,0.35],[2.75,73,0.5],[4,76,0.7],
            [5.5,73,0.5],[6.5,69,0.5],[7.5,66,0.3],[8,66,0.5],[9.5,64,0.4],
            [10.5,61,0.7],[12,64,0.45],[13.5,66,0.4],[14.75,69,0.5]],
        b:[[0,73,0.7],[1.5,69,0.4],[2.75,66,0.6],[4,64,0.45],[5.5,66,0.4],[7,69,0.7],
            [8,73,0.5],[9.5,76,0.5],[10.75,73,0.5],[12,69,0.5],[13.5,64,0.4],[15,66,0.6]]),
    (id:"study-04-sun-room",title:"Sun Room",bpm:120,key:"C major",keyPC:0,
        scale:[0,2,4,5,7,9,11],family:3,lead:\studyKeys,swing:0.065,
        gain:1.8,room:0.65,wet:0.16,delay:0.13,duck:0.36,
        sections:[\intro,\groove,\theme,\theme,\break,\return,\drop,\close],
        chords:[
            (root:36,notes:[55,59,62,64],bars:2,name:"Cmaj9"),
            (root:35,notes:[55,59,62,67],bars:2,name:"G/B"),
            (root:33,notes:[55,59,60,64],bars:2,name:"Am9"),
            (root:29,notes:[57,60,64,67],bars:2,name:"Fmaj9")],
        bass:[[0,0,0.55,1],[1.75,7,0.3,0.8],[2.5,0,0.35,0.9],[3.25,12,0.3,0.75]],
        a:[[0.5,76,0.6],[1.5,79,0.4],[2.5,81,0.6],[3.5,79,0.3],[4.5,76,0.7],
            [6,74,0.4],[7,72,0.65],[8.5,71,0.6],[9.5,74,0.4],[10.5,76,0.6],
            [12,74,0.6],[13.5,72,0.5],[15,71,0.65]],
        b:[[0,79,0.6],[1.5,76,0.5],[3,74,0.7],[4.5,72,0.7],[6,76,0.4],[7,79,0.6],
            [8.5,81,0.7],[10,79,0.4],[11,76,0.7],[12.5,74,0.5],[14,72,1.25]]),
    (id:"study-05-wide-horizon",title:"Wide Horizon",bpm:126,key:"E minor",keyPC:4,
        scale:[0,2,3,5,7,8,10],family:4,lead:\studyWide,swing:0.008,
        gain:1.75,room:0.83,wet:0.22,delay:0.17,duck:0.55,
        sections:[\intro,\tease,\theme,\theme,\break,\build,\drop,\close],
        chords:[
            (root:40,notes:[55,59,64,66],bars:4,name:"Em9"),
            (root:36,notes:[55,59,62,64],bars:4,name:"Cmaj9"),
            (root:31,notes:[54,57,59,62],bars:4,name:"Gmaj9"),
            (root:38,notes:[54,57,62,64],bars:4,name:"Dadd9")],
        bass:[[0.5,0,0.42,1],[1.5,0,0.42,0.9],[2.5,7,0.4,0.85],[3.5,12,0.35,0.75]],
        a:[[0,71,1.5],[1.75,74,0.5],[2.5,76,2.5],[5.5,79,0.5],[6.25,78,0.5],
            [7,76,1.5],[9,74,0.75],[10,71,1.5],[12,69,1],[13.5,67,0.75],[15,66,0.75]],
        b:[[0,67,1],[1.5,71,0.75],[2.5,74,1.25],[4,76,2.5],[7,74,0.75],
            [8,71,1.5],[10,69,0.75],[11,67,0.75],[12,66,1],[13.5,67,0.75],[15,64,0.8]])
];
~studyEvents={ |spec|
    var events=List.new, seed=31000+(spec.family*1000), chords=List.new, cursor=0, index=0;
    var allowed=spec.scale.collect { |offset| (spec.keyPC+offset)%12 }, add, nearest;
    nearest={ |pitch,notes|
        var options=notes.collect { |note| [-24,-12,0,12,24].collect { |octave| note+octave } }.flat;
        options.sort { |a,b| (a-pitch).abs < (b-pitch).abs }.first;
    };
    add={ |voice,beat,note=60,duration=0.25,amp=0.1,pan=0,tone=0.5,extra|
        var lane=if([\studyKick,\studyClap,\studySnare,\studyHat,\studyShake,\studyRim,\studyCrash,\studyRise].includes(voice),2,
            if(voice == \studyBass,1,0));
        var event=(voice:voice,beat:beat,midinote:note,duration:duration,amp:amp,pan:pan,tone:tone,
            family:spec.family,lane:lane,seed:seed+events.size);
        if(extra.notNil) { event.putAll(extra) };
        if((beat >= 0) and: { beat < 128 }) { events.add(event) };
    };
    while { cursor < 31 } {
        var chord=spec.chords.wrapAt(index).copy;
        chord.start=cursor; chord.bars=chord.bars.min(31-cursor);
        chord.bars.do { chords.add(chord) }; cursor=cursor+chord.bars; index=index+1;
    };
    // Resolve the last bar to the tonic; shorten the preceding chord to leave room.
    { var tonic=spec.chords[0].copy; tonic.start=31; tonic.bars=1; chords.add(tonic) }.value;
    32.do { |bar|
        var start=bar*4, chord=chords[bar], section=spec.sections[bar div:4];
        var broken=spec.family == 3, dark=spec.family == 2, wide=spec.family == 4;
        var drums=section != \break, bass=section != \break, full=[\theme,\drop,\close].includes(section);
        var tone=case { section == \build } { 0.25+((bar%4)*0.16) }
            { section == \break } { 0.25 } { section == \drop } { 0.8 } { true } { 0.55 };
        var phrase=if((bar div:4).even,spec.a,spec.b), leadOn, chordVoice;
        if(section == \intro and: { bar < 2 }) { bass=false };
        if(drums) {
            var kicks=if(broken,[0,7,10,14],[0,4,8,12]);
            if(section == \intro and: { wide or: { spec.family == 1 } }) { kicks=[0,8] };
            if(section == \build and: { bar < 22 }) { kicks=[0,8] };
            kicks.do { |step|
                if((bar != 31 or: { step < 12 }) and: { bar != 23 or: { step < 12 } }) {
                    add.value(\studyKick,start+(step*0.25),31,0.3,if(dark,0.63,0.60),0,tone,
                        (freq:if(wide,48,50),decay:if(dark,0.28,0.34),edge:if(dark,0.04,0.025)));
                };
            };
            [4,12].do { |step|
                if((section != \intro or: { bar >= 2 }) and: { bar != 23 or: { step < 12 } } and: { bar != 31 or: { step < 12 } }) {
                    add.value(if(dark,\studySnare,\studyClap),start+(step*0.25),50,0.14,if(broken,0.17,0.16),-0.08);
                    if(broken) { add.value(\studyRim,start+(step*0.25)+0.012,60,0.05,0.045,-0.25,0.5,(freq:420)) };
                };
            };
            8.do { |i|
                var beat=i*0.5, accent=i.odd;
                if((bar != 23 or: { beat < 3 }) and: { bar != 31 or: { beat < 2.5 } }) {
                    add.value(\studyHat,start+beat,116,if(accent,0.13,0.038),if(accent,0.065,0.027),0.28);
                };
            };
            if(section != \intro or: { bar >= 2 }) {
                16.do { |step|
                    if(step.odd and: { (bar != 23 or: { step < 12 }) and: { bar != 31 or: { step < 10 } } }) {
                        add.value(\studyShake,start+(step*0.25)+spec.swing,60,0.04,
                            if(step%4==3,0.06,0.032),if(step%4==3,-0.3,0.35));
                    };
                };
            };
            if([\theme,\drop,\close,\groove,\return].includes(section) and: { bar.odd }) {
                [1.75,3.25].do { |beat| if(bar != 31) {
                    add.value(\studyRim,start+beat+spec.swing,60,0.06,if(dark,0.045,0.03),-0.35,0.4,(freq:if(dark,310,570)));
                } };
            };
            if(section == \build and: { bar >= 22 }) {
                8.do { |step|
                    var beat=step*0.5;
                    if(beat < 3 or: { bar == 22 }) {
                        add.value(\studySnare,start+beat,50,0.08,0.035+((bar-22)*0.018)+(step*0.002),-0.08);
                    };
                };
            };
        };
        if([8,24].includes(bar)) { add.value(\studyCrash,start,60,1.5,if(dark,0.07,0.10)) };
        if(section == \build and: { bar == 22 }) {
            add.value(\studyRise,start,60,6.9,if(wide,0.09,0.055));
        };
        if(bass) {
            spec.bass.do { |note|
                var pitch=chord.root+note[1], beat=note[0], amp=0.26*note[3];
                if(allowed.includes(pitch%12).not) { pitch=nearest.value(pitch,chord.notes) };
                if((section != \intro or: { beat < 2 }) and: { bar != 23 or: { beat < 3 } } and: { bar != 31 }) {
                    add.value(\studyBass,start+beat,pitch,note[2],amp,0,tone);
                };
            };
            if(bar == 31) { add.value(\studyBass,start,chord.root,2.6,0.25,0,tone*0.7) };
        };
        chordVoice=if(broken,\studyKeys,\studyPad);
        if(bar == chord.start or: { section == \break and: { bar.even } }) {
            chord.notes.do { |pitch,i|
                var duration=if(chordVoice == \studyPad,(chord.bars*4)-2.8,1.3);
                add.value(chordVoice,start,pitch,duration.max(0.5),if(dark,0.035,0.055),(i-1.5)*0.25,tone*0.7);
            };
        };
        if(broken and: { drums } and: { bar != chord.start }) {
            [0.75,2.5].do { |beat|
                chord.notes.keep(3).do { |pitch,i| add.value(\studyKeys,start+beat+spec.swing,pitch,0.35,0.055,(i-1)*0.25,0.5) };
            };
        };
        leadOn=full or: { section == \tease } or: { section == \answer } or: { section == \return };
        if(dark and: { section == \groove } and: { bar >= 4 }) { leadOn=true };
        if(leadOn and: { bar != 31 }) {
            phrase.do { |note,i|
                var relative=note[0]-(4*(bar%4));
                var active=(relative >= 0) and: { relative < 4 };
                if([\tease,\answer,\return,\groove].includes(section) and: { i.odd }) { active=false };
                if(active) {
                    add.value(spec.lead,start+relative+if(broken,spec.swing,0),note[1],note[2],
                        if(section == \tease,0.085,if(wide,0.24,0.145))*if(i%4==0,1,0.88),-0.05,tone);
                };
            };
        };
        if(section == \break) {
            if(bar.even) {
                add.value(\studyKeys,start+0.5,chord.notes.last+12,2.2,0.09,-0.12,0.45);
                add.value(\studyBell,start+2.5,chord.notes[1]+12,1.1,0.065,0.3,0.35);
            };
        };
        if(section == \build and: { bar >= 22 }) {
            add.value(if(wide,\studyPluck,spec.lead),start+2.5,spec.a[0][1],0.55,0.08,0,tone);
        };
        if((full or: { section == \build }) and: { broken.not } and: { dark.not } and: { bar != 31 }) {
            8.do { |step|
                var beat=(step*0.5)+0.25, pitch=chord.notes.wrapAt(step+(bar%2))+12;
                if((section != \build or: { bar >= 21 }) and: { bar != 23 or: { beat < 3 } }) {
                    add.value(\studyBell,start+beat+spec.swing,pitch,0.15,if(wide,0.034,0.028),0.3,tone);
                };
            };
        };
        if(bar == 31) {
            add.value(if(wide,\studyWide,spec.lead),start,60+spec.keyPC,2.7,if(wide,0.21,0.13),0,0.4);
        };
    };
    events.sort { |a,b| a.beat < b.beat };
};
~studyMessage={ |event,spec,node,group,bus|
    [\s_new,event.voice,node,0,group,\out,bus+(event.lane*2),\freq,event[\freq] ? event.midinote.midicps,
        \amp,event.amp,\sustain,event.duration*60/spec.bpm,\pan,event.pan,\tone,event.tone,\family,event.family,
        \seed,event.seed,\decay,event[\decay] ? 0.34,\edge,event[\edge] ? 0.03]
};
~studyMixArgs={ |spec,bus|
    [\in,bus,\bpm,spec.bpm,\gain,spec.gain,\room,spec.room,\wet,spec.wet,\delay,spec.delay,\duck,spec.duck]
};
)
