// Sparse Tension colors, fixed-mode studies and pentatonic melodies. Pure functions.
(
~djTonalities=(
    harmonicMinor:(scale:[0,2,3,5,7,8,11],family:\minor,label:"Harmonic minor"),
    melodicMinor:(scale:[0,2,3,5,7,9,11],family:\minor,label:"Melodic minor"),
    aeolian:(scale:[0,2,3,5,7,8,10],family:\minor,label:"Aeolian"),
    ionian:(scale:[0,2,4,5,7,9,11],family:\major,label:"Ionian"),
    dorian:(scale:[0,2,3,5,7,9,10],family:\minor,label:"Dorian"),
    phrygian:(scale:[0,1,3,5,7,8,10],family:\minor,label:"Phrygian"),
    mixolydian:(scale:[0,2,4,5,7,9,10],family:\major,label:"Mixolydian"),
    lydian:(scale:[0,2,4,6,7,9,11],family:\major,label:"Lydian")
);
// Independent seeded choices preserve the rhythm/timbre random streams.
// At most a two-bar phrase ending is colored; the engine enforces the cooldown.
~djTensionColor={|family,tension,seed,serial,window,preference=\original,degrees= #[0]|
    var pressure=((tension-0.60)/0.40).clip(0,1),chance=0.08+(pressure*0.47);
    var rare=((tension-0.85)/0.15).clip(0,1)*0.20;
    var mild=if(family==\minor){\dorian}{\mixolydian},exotic=if(family==\minor){\phrygian}{\lydian};
    var rng=(((seed.abs*65537)+((serial+1).squared*104729)+((window+1).squared*13007)+67867967)%2147483646)+1,random,chosen;
    var unsafe=(dorian:5,phrygian:4,mixolydian:2,lydian:3);
    random={rng=(rng*48271)%2147483647;rng/2147483647};
    if(tension>0.60){
        if(preference==exotic){chance=chance*rare};
        if(random.value<chance){
            chosen=if([mild,exotic].includes(preference)){preference}{if(random.value<rare){exotic}{mild}};
            // Avoid turning the chord under the accent into a diminished triad.
            if(degrees.includes(unsafe[chosen])){chosen=nil};
        };
    };
    chosen;
};
~djModalLibrary={ |original,tonality=\original|
    var lib=original,banks=(
        harmonicMinor:[[0,3,4,0],[0,5,3,4],[0,3,5,4],[5,3,4,0],[0,4,3,0],[3,0,5,4],
            [0,0,3,4],[0,5,4,0],[3,5,4,0],[5,4,3,0],[0,3,0,4],[0,4,5,3]],
        melodicMinor:[[0,1,3,4],[0,3,4,0],[0,1,4,0],[3,0,1,4],[0,4,3,0],[1,3,4,0],
            [0,0,3,4],[0,3,1,4],[3,1,4,0],[1,0,3,4],[0,4,1,3],[0,1,0,4]],
        dorian:[[0,3,0,6],[0,1,3,0],[0,6,3,0],[0,2,3,0],[0,3,1,6],[3,0,6,0],
            [0,4,3,0],[0,3,2,6],[6,3,0,0],[0,1,6,3],[0,2,6,3],[0,6,1,3]],
        phrygian:[[0,1,0,6],[0,5,1,0],[0,3,1,0],[0,1,5,6],[0,6,1,0],[5,1,0,0],
            [0,2,1,0],[0,3,5,1],[6,5,1,0],[0,1,3,6],[0,5,3,1],[3,1,6,0]],
        mixolydian:[[0,6,3,0],[0,3,0,6],[0,4,6,3],[0,1,3,0],[0,5,3,6],[3,6,0,0],
            [0,6,5,3],[0,1,6,0],[5,3,6,0],[0,4,3,6],[0,3,5,6],[6,3,1,0]],
        lydian:[[0,1,0,4],[0,4,1,0],[0,5,1,4],[0,1,5,0],[0,6,1,0],[1,0,4,0],
            [0,2,1,0],[0,1,6,4],[5,1,0,0],[0,4,5,1],[0,6,4,1],[1,5,4,0]]
    );
    if(banks[tonality].notNil){
        lib=original.copy;
        lib.minor=banks[tonality];lib.major=banks[tonality];
        // The flat-II chord is a stronger Phrygian pickup than a diminished v.
        if(tonality==\phrygian){lib.cadenceDegree=1};
    };
    lib;
};
~djMelodyPalette={ |events,plan,choice=\full|
    var palette=plan.scale.atAll(if(plan.mode==\major){[0,1,2,4,5]}{[0,2,3,4,6]});
    plan.melodyPalette=if(choice==\pentatonic){palette}{plan.scale};
    if(choice==\pentatonic){
        events.collect {|event|
            var e=event.copy;
            if([\djHook,\djArp,\eSignature].includes(e.role)){
                var candidates=((e.midinote-3)..(e.midinote+3)).select {|n|palette.includes((n-plan.key)%12)};
                if(e[\rockLanding] ? false){
                    candidates=(60..84).select {|n|
                        var pc=(n-plan.key)%12;palette.includes(pc) and:{e.chordTones.includes(pc)}
                    };
                };
                e.midinote=candidates.sort {|a,b|(a-event.midinote).abs<(b-event.midinote).abs}.first;
                if(e[\rockLanding] ? false){e.landingOffset=[0,2,4][e.chordTones.indexOf((e.midinote-plan.key)%12)]};
            };
            e;
        };
    } {events};
};
)
