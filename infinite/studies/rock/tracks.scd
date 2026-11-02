// Three finite backing-track studies: rhythm guitar, bass and drums; no lead solo.
// All timing is in beats. Shared scales are pitch-class offsets from each tonic.
(
~rockSpecs=[
    (id:\ironwood,file:"rock-ironwood",title:"Ironwood",bpm:102,tonic:4,
        scale:[0,3,5,7,10],scaleName:"E minor pentatonic",notes:"E G A B D",
        style:\riff,guitarGain:1.45,drive:0.62,mute:0.70,
        form:[[\intro,4],[\groove,12],[\answer,8],[\return,8]],
        description:"Palm-muted power-chord rock; leave space for an E minor-pentatonic solo."),
    (id:\greenroom,file:"rock-green-room",title:"Green Room",bpm:94,tonic:9,
        scale:[0,2,3,5,7,9,10],scaleName:"A Dorian",notes:"A B C D E F# G",
        style:\dorian,guitarGain:2.6,drive:0.12,mute:0.32,
        form:[[\intro,4],[\groove,8],[\answer,8],[\space,4],[\return,8]],
        description:"Clean minor-seventh chords and a major IV; the F-sharp gives Dorian its lift."),
    (id:\openroad,file:"rock-open-road",title:"Open Road",bpm:112,tonic:2,
        scale:[0,2,4,5,7,9,10],scaleName:"D Mixolydian",notes:"D E F# G A B C",
        style:\mixo,guitarGain:1.55,drive:0.34,mute:0.18,
        form:[[\intro,4],[\groove,8],[\answer,8],[\space,4],[\return,8]],
        description:"Open major chords over I-flatVII-IV; C-natural supplies the Mixolydian color.")
];
~rockEvents={ |spec,seed=731,effects=true|
    var events=List.new,sections=List.new,cursor=0,add,strum,barCount=32;
    spec.form.do { |part| sections.add((name:part[0],start:cursor,bars:part[1]));cursor=cursor+part[1] };
    add={ |voice,lane,beat,note=60,duration=0.2,amp=0.1,pan=0,mute,drive,role|
        events.add((voice:voice,lane:lane,beat:beat,midinote:note,duration:duration,amp:amp,pan:pan,
            mute:mute ? spec.mute,drive:drive ? spec.drive,role:role ? voice,
            seed:seed+(events.size*37)+(spec.tonic*1009)));
    };
    strum={ |beat,notes,duration,level,muting|
        [-0.65,0.65].do { |pan,side|
            notes.do { |note,i|
                add.value(\rkGuitar,0,beat+(i*0.016)+(side*0.012),note,duration,
                    (level*spec.guitarGain)/(notes.size.sqrt),pan,muting,nil,\guitar);
            };
        };
    };
    barCount.do { |bar|
        var part=sections.detect { |p|bar<(p.start+p.bars) },local,quiet,intro,last,root,chord;
        var steps,durations,kicks,fill,pulse,offset,base=bar*4,progression;
        local=bar-part.start;quiet=part.name==\space;intro=part.name==\intro;last=bar==31;
        fill=bar%8==7 and:{last.not};
        progression=case
            {spec.style==\riff} {if(part.name==\answer){[3,5,0,10]}{[0,0,3,5,0,0,10,5]}}
            {spec.style==\dorian} {if(part.name==\answer){[3,5,0,0]}{[0,0,5,5,0,0,10,5]}}
            {true} {if(part.name==\answer){[5,10,0,0]}{[0,10,5,0]}};
        offset=if(last){0}{progression.wrapAt(local)};
        root=36+spec.tonic+offset;
        while {root>55} {root=root-12};
        chord=case
            {spec.style==\riff} {[root,root+7,root+12]}
            {spec.style==\dorian} {
                switch(offset,
                    0,{[45,52,55,60]}, 5,{[50,57,64,66]},
                    3,{[48,55,60,64]}, 10,{[43,50,55,59]}, {[45,52,55,60]});
            }
            {true} {
                switch(offset,
                    0,{[50,57,62,66]}, 10,{[48,55,60,64]}, 5,{[43,50,55,59]}, {[50,57,62,66]});
            };
        // Repeated rhythm cells, one answer at the end of each four-bar phrase.
        steps=case {quiet} {[0,8]}
            {spec.style==\riff} {if(local%4==3){[0,2,4,6,8,11,14]}{[0,2,4,6,8,10,12,14]}}
            {spec.style==\dorian} {[0,3,6,10,14]}
            {true} {[0,3,6,8,11,14]};
        if(intro and:{local<2}) {steps=[0,8]};
        if(last) {steps=[0,4,8]};
        steps.do { |step,i|
            var length=case {quiet} {1.5} {last} {if(i==2){1.6}{0.35}}
                {spec.style==\riff} {if(step%4==0){0.30}{0.19}}
                {spec.style==\dorian} {0.34} {true} {if(step%4==0){0.75}{0.30}};
            var level=if(quiet){0.085}{if(spec.style==\riff){0.15}{0.12}};
            strum.value(base+(step*0.25),chord,length,
                level*if(step%4==0){1}{0.78},if(quiet){0.10}{spec.mute});
        };
        // The bass locks to the kick and guitar rather than filling the solo space.
        steps=case {quiet} {[0,8]} {spec.style==\dorian} {[0,3,6,8,11,14]}
            {spec.style==\riff} {[0,2,4,6,8,10,12,14]} {true} {[0,3,6,8,10,14]};
        if(intro and:{local<2}) {steps=[0,8]};if(last){steps=[0,4,8]};
        steps.do { |step,i|
            var note=root-12,length=if(quiet){1.4}{0.35};
            if(local%4==3 and:{i==(steps.size-1)} and:{last.not}) {
                note=case {spec.style==\dorian and:{offset==5}} {42} // F-sharp: Dorian sixth
                    {spec.style==\mixo} {36} // C-natural: Mixolydian flat seventh
                    {true} {root};
            };
            add.value(\rkBass,1,base+(step*0.25),note,length,if(quiet){0.16}{0.22});
        };
        kicks=if(quiet){[0,8]}{if(bar%2==0){[0,6,8]}{[0,7,8,10]}};
        if(intro and:{local<2}) {kicks=[0,8]};if(last){kicks=[0,8]};
        kicks.do { |step|add.value(\rkKick,2,base+(step*0.25),48,0.3,if(step==0){0.53}{0.43})};
        [4,12].do { |step|
            if(last.not or:{step==4}) {add.value(\rkSnare,2,base+(step*0.25)+0.012,50,0.2,if(quiet){0.16}{0.28})};
        };
        if(spec.style==\dorian and:{quiet.not} and:{local.odd}) {
            add.value(\rkSnare,2,base+2.75,50,0.08,0.055,-0.06);
        };
        8.do { |i|
            var step=i*2,open=step==14 and:{local%4==3} and:{fill.not};
            if((last.not or:{step<=8}) and:{fill.not or:{step<12}}) {
                add.value(\rkHat,2,base+(i*0.5),100,if(open){0.21}{0.055},
                    if(quiet){0.034}{if(i.even){0.072}{0.046}},0.28);
            };
        };
        if(fill) {
            [12,13,14,15].do { |step,i|
                add.value(if(i<2){\rkSnare}{\rkTom},2,base+(step*0.25),
                    [50,50,50,43][i],0.2,0.15+(i*0.018),[-0.06,-0.06,0.1,0.35][i]);
            };
        };
        if(local==0 and:{intro.not} and:{quiet.not}) {add.value(\rkCrash,2,base,90,1.8,0.09,-0.3)};
    };
    // A real tonic ending with decay, rather than cutting an active bar in half.
    {
        var root=36+spec.tonic,notes;
        notes=case {spec.style==\riff} {[root,root+7,root+12]}
            {spec.style==\dorian} {[45,52,55,60]} {true} {[50,57,62,66]};
        strum.value(128,notes,1.8,0.12,0.12);
        add.value(\rkBass,1,128,root-12,1.8,0.22);
        add.value(\rkKick,2,128,48,0.3,0.5);
        add.value(\rkCrash,2,128,90,1.8,0.10,-0.3);
    }.value;
    // Effects belong to individual notes/lanes; quiet sections stay unprocessed.
    events.do { |event|
        var bar=(event.beat/4).floor.asInteger.min(31),part=sections.detect {|p|bar<(p.start+p.bars)};
        var local=bar-part.start,step=((event.beat%4)*4).round.asInteger;
        event.overdrive=0;event.fuzz=0;event.wah=0;event.slap=0;event.grit=0;
        if(effects and:{[\answer,\return].includes(part.name)} and:{event.beat<128}) {
            if(event.voice==\rkGuitar) {
                switch(spec.style,
                    \riff,{
                        event.overdrive=if(step%4==0){0.35}{0.1};
                        // Left guitar fuzz joins for the second half, then drops out.
                        if(local>=4 and:{event.pan<0}){event.fuzz=0.62};
                    },
                    \dorian,{
                        if(step%4==0){event.overdrive=0.32};
                        if(local%4>=2 and:{[6,10].includes(step)}){event.wah=0.65};
                    },
                    \mixo,{
                        event.overdrive=if(event.pan<0){0.42}{0.12};
                        if(local%4==3 and:{step==14}){event.slap=0.65};
                    }
                );
            };
            if(event.voice==\rkBass and:{spec.style==\riff} and:{local%4==3}){event.grit=0.30};
        };
    };
    events.asArray.sort { |a,b|a.beat<b.beat };
};
~rockMessage={ |event,node,group,bus,bpm|
    [\s_new,event.voice,node,0,group,\out,bus+(event.lane*2),\freq,event.midinote.midicps,
        \sustain,event.duration*60/bpm,\amp,event.amp,\pan,event.pan,
        \drive,event.drive,\mute,event.mute,\seed,event.seed,
        \overdrive,event.overdrive,\fuzz,event.fuzz,\wah,event.wah,\slap,event.slap,\grit,event.grit];
};
)
