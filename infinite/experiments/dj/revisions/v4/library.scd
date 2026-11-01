// Data only. Progression degrees are zero-based positions in the selected scale.
(
~djLibrary=(
    minor:[
        [0,5,2,6], [0,6,5,6], [0,3,5,4], [0,2,6,5],
        [0,5,3,4], [0,4,5,3], [0,3,6,0], [0,6,2,3],
        [5,6,0,0], [0,2,3,5], [0,5,6,4], [0,3,2,6],
        [0,0,5,6], [0,4,3,6], [2,6,0,5], [0,5,2,4]
    ],
    major:[
        [0,4,5,3], [0,5,3,4], [0,3,4,0], [5,3,0,4],
        [0,1,3,4], [0,2,5,3], [3,4,2,5], [0,3,5,4],
        [5,4,3,0], [0,4,1,3], [0,2,3,4], [0,5,1,4],
        [3,0,4,5], [0,1,4,0], [2,5,1,4], [0,4,3,5]
    ],
    durations:[
        [2,2,2,2], [4,4,4,4], [1,1,2,4], [4,2,1,1], [3,1,2,2],
        [2,4,1,1], [1,3,1,3], [8,4,2,2], [2,2,4,8], [1,1,1,5],
        [6,2,4,4], [2,6,2,6], [4,1,1,2], [3,3,1,1], [8,2,2,4],
        [1,2,1,4], [4,4,2,6], [2,1,1,4], [5,3,2,6], [2,2,2,2,4,4,1,3]
    ],
    bassRhythms:[
        [2,6,10,14], [0,3,6,8,10,14], [0,3,4,7,8,11,12,15], [0,4,6,8,12,14],
        [0,3,6,10,11,14], [0,6,8,11,14], [2,5,6,10,13,14], [0,2,3,6,8,10,11,14]
    ],
    kicks:[
        [0,4,8,12], [0,4,8,12], [0,4,8,12,14], [0,4,8,12],
        [0,4,8,12], [0,6,8,12,14], [0,4,8,12], [0,4,8,12,15]
    ],
    hookRhythms:[
        [0,3,6,8,10,14], [0,2,6,7,10,12,14], [0,3,4,7,8,11,14], [0,4,6,8,12,15],
        [0,3,6,10,12,14], [0,2,5,8,10,13], [0,4,7,8,11,14], [0,3,6,7,10,14,15]
    ],
    hooks:[
        [0,1,2,1,0,2,1,0], [0,0,2,1,3,2,1,0], [2,1,0,1,2,3,2,0], [0,2,3,2,1,0,1,0],
        [0,1,0,2,1,3,2,0], [0,2,1,2,0,1,3,2], [2,2,1,0,1,2,3,0], [0,3,2,1,0,1,2,0],
        [0,1,2,3,2,1,0,0], [2,0,1,2,3,2,1,0], [0,2,0,1,2,3,1,0], [0,1,3,2,1,2,1,0],
        [3,2,1,0,2,1,0,0], [0,0,1,2,1,3,2,1], [1,0,2,1,3,2,1,0], [0,2,1,0,3,2,1,0]
    ],
    keys:["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
);
~djLibrary.variations=Array.fill(32, { |i|
    (id:i, name:["Velvet", "Glass", "Copper", "Night"][i div: 8] ++ " " ++
        ["Offbeat", "Drive", "Gallop", "Pulse", "Skipping", "Broken", "Lift", "Rolling"][i % 8],
        color:i div: 8, rhythm:i % 8, arpDirection:i div: 8,
        swing:[0.015, 0.025, 0.035, 0.045][i div: 8])
});

// Record forms have different lengths; all boundaries are four-bar phrases.
~djLibrary.forms=[
    [[\intro,8],[\groove,8],[\hook,8],[\space,4],[\buildup,4],[\drop,16],[\outro,8]],
    [[\intro,8],[\groove,16],[\hook,8],[\breakdown,8],[\buildup,8],[\drop,16],[\outro,16]],
    [[\intro,16],[\groove,16],[\hook,16],[\breakdown,8],[\buildup,8],[\drop,16],[\outro,16]],
    [[\intro,8],[\groove,8],[\hook,8],[\drop,8],[\breakdown,4],[\buildup,4],[\drop,16],[\outro,8]],
    [[\intro,8],[\groove,16],[\breakdown,4],[\buildup,4],[\hook,8],[\groove,8],[\drop,16],[\outro,8]],
    [[\intro,16],[\groove,16],[\hook,8],[\space,8],[\groove,8],[\buildup,8],[\drop,16],[\outro,16]]
];
~djLibrary.bassAnswers=[
    [0,3,4,6,8,10,11,14], [0,3,6,7,8,10,14,15],
    [0,2,4,7,8,11,12,14], [0,3,4,6,8,10,12,15],
    [0,3,5,6,8,10,11,14], [0,2,4,6,8,11,14,15],
    [0,3,4,7,8,10,13,14], [0,2,3,6,8,10,11,14]
];
~djLibrary.compRhythms=[[2,10],[0,7,14],[2,6,11,14],[0,6,10],[3,11],[2,7,10,15],[0,10],[3,6,11,14]];
// A record keeps one coordinated ensemble. These are different synth graphs,
// not just brightness presets; new records rotate the ensemble.
~djLibrary.palettes=[
    (id:0,name:"Wired House",bassName:"Classic sub",leadName:"Octave saw",kitName:"Tight house",color:0,
        voices:(djBass:\djBass,djHook:\djHook,djPad:\djPad,djArp:\djArp,djStab:\djStab,
            djKick:\djKick,djClap:\djClap,djSnare:\djSnare,djHat:\djHat,djPerc:\djPerc)),
    (id:1,name:"Brass Circuit",bassName:"Reese bass",leadName:"Unison brass",kitName:"Analog punch",color:1,
        voices:(djBass:\djReeseBass,djHook:\djBrassLead,djPad:\djStringPad,djArp:\djBrassLead,djStab:\djBrassLead,
            djKick:\djAnalogKick,djClap:\djAnalogClap,djSnare:\djAnalogSnare,djHat:\djAnalogHat,djPerc:\djAnalogPerc)),
    (id:2,name:"Digital Drive",bassName:"FM bass",leadName:"FM growl",kitName:"Dry electro",color:2,
        voices:(djBass:\djFMBass,djHook:\djFMLead,djPad:\djGlassPad,djArp:\djFMLead,djStab:\djFMLead,
            djKick:\djElectroKick,djClap:\djElectroClap,djSnare:\djElectroSnare,djHat:\djElectroHat,djPerc:\djElectroPerc)),
    (id:3,name:"Acid Foundry",bassName:"Acid bass",leadName:"Sync stack",kitName:"Dust metal",color:3,
        voices:(djBass:\djAcidBass,djHook:\djSyncLead,djPad:\djStringPad,djArp:\djSyncLead,djStab:\djStab,
            djKick:\djDustKick,djClap:\djDustClap,djSnare:\djDustSnare,djHat:\djDustHat,djPerc:\djDustPerc))
];
)
