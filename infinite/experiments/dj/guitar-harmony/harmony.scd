// Pitch spelling, playable guitar shapes and triad voice leading. Strings 0..5
// run from low E to high E. Research and listening guide: README.md / RESEARCH.md.
(
~ghSpecs=(
    a:(label:"A",root:9,intervals:[0,4,7]),
    fsmin:(label:"F#m",root:6,intervals:[0,3,7]),
    d:(label:"D",root:2,intervals:[0,4,7]),
    e:(label:"E",root:4,intervals:[0,4,7]),
    amaj7:(label:"Amaj7",root:9,intervals:[0,4,7,11]),
    a7:(label:"A7",root:9,intervals:[0,4,7,10]),
    amin7:(label:"Am7",root:9,intervals:[0,3,7,10]),
    aadd9:(label:"Aadd9",root:9,intervals:[0,2,4,7]),
    a9:(label:"A9",root:9,intervals:[0,2,4,7,10]),
    fsmin7:(label:"F#m7",root:6,intervals:[0,3,7,10]),
    dadd9:(label:"Dadd9",root:2,intervals:[0,2,4,7]),
    e7:(label:"E7",root:4,intervals:[0,4,7,10]),
    e7shell:(label:"E7 (no5)",root:4,intervals:[0,4,10]),
    bmin7:(label:"Bm7",root:11,intervals:[0,3,7,10]),
    ae:(label:"A/E",root:9,intervals:[0,4,7],bass:4),
    acs:(label:"A/C#",root:9,intervals:[0,4,7],bass:1),
    egs:(label:"E/G#",root:4,intervals:[0,4,7],bass:8),
    de:(label:"D/E",root:2,intervals:[0,4,7],bass:4)
);
~ghShapes=(
    a:[[1,45],[2,52],[3,57],[4,61],[5,64]],
    amaj7:[[1,45],[2,52],[3,56],[4,61],[5,64]],
    a7:[[1,45],[2,52],[3,55],[4,61],[5,64]],
    amin7:[[1,45],[2,52],[3,55],[4,60],[5,64]],
    aadd9:[[1,45],[2,52],[3,59],[4,61],[5,64]],
    a9:[[1,45],[2,52],[3,59],[4,61],[5,67]],
    fsmin7:[[0,42],[1,49],[2,52],[3,57],[4,61],[5,66]],
    dadd9:[[2,50],[3,57],[4,64],[5,66]],
    e7:[[0,40],[1,47],[2,50],[3,56],[4,59],[5,64]],
    ae:[[0,40],[1,45],[2,52],[3,57],[4,61],[5,64]],
    acs:[[1,49],[2,52],[3,57],[4,61]],
    // Compact shapes for an E pedal and a genuine descending guitar bass line.
    pedalE:[[0,40],[2,52],[3,56],[4,59]],
    pedalA:[[0,40],[2,52],[3,57],[4,61]],
    pedalD:[[0,40],[2,54],[3,57],[4,62]],
    pedalE7:[[0,40],[2,50],[3,56],[4,59]],
    highA:[[2,57],[3,61],[4,64]],
    highEgs:[[2,56],[3,59],[4,64]],
    highFsmin7:[[2,54],[3,57],[4,61],[5,64]],
    highE:[[2,52],[3,56],[4,59],[5,64]],
    highD:[[2,50],[3,57],[4,62],[5,66]],
    highE7shell:[[2,52],[3,56],[4,62],[5,64]],
    bmin7:[[1,47],[2,54],[3,57],[4,62],[5,66]]
);
~ghPCs={|spec|((spec[\intervals]+spec[\root])%12).asSet};
~ghPlayable={|voices|
    var opens=[40,45,50,55,59,64],frets=voices.collect {|pair|pair[1]-opens[pair[0]]};
    var stopped=frets.select {|f|f>0};
    (voices.collect {|p|p[0]}.asSet.size==voices.size)
        and:{frets.every {|f|f.inclusivelyBetween(0,19)}}
        and:{stopped.isEmpty or:{stopped.maxItem-stopped.minItem<=4}}
        and:{stopped.asSet.size<=4};
};
~ghTriads={|key,strings=#[2,3,4],inversion= -1|
    var spec=~ghSpecs[key],opens=[40,45,50,55,59,64],pcs=~ghPCs.value(spec),choices,result=List.new;
    choices=strings.collect {|string|(0..14).select {|fret|pcs.includes((opens[string]+fret)%12)}};
    choices[0].do {|a|choices[1].do {|b|choices[2].do {|c|
        var voices=[[strings[0],opens[strings[0]]+a],[strings[1],opens[strings[1]]+b],[strings[2],opens[strings[2]]+c]];
        var notes=voices.collect {|p|p[1]},bass=(notes.minItem-spec[\root])%12;
        if(~ghPlayable.value(voices) and:{notes[0]<notes[1]} and:{notes[1]<notes[2]} and:{notes.last-notes.first<12}
            and:{notes.collect {|n|n%12}.asSet==pcs}
            and:{inversion<0 or:{bass==spec[\intervals][inversion]}}){result.add(voices)};
    }}};
    result.asArray.sort {|a,b|a.collect {|p|p[1]}.sum<b.collect {|p|p[1]}.sum};
};
~ghMove={|a,b|a.collect {|pair,i|(pair[1]-b[i][1]).abs}.sum};
~ghLead={|keys,rootOnly=false|
    var candidates=keys.collect {|key|~ghTriads.value(key,#[2,3,4],if(rootOnly){0}{-1})};
    var costs,paths;
    candidates[0]=~ghTriads.value(keys[0],#[2,3,4],0);
    if(candidates.any(_.isEmpty)){Error("No playable triad path").throw};
    costs=candidates[0].collect {|voices|(voices.collect {|p|p[1]}.mean-61).abs*0.001};
    paths=candidates[0].collect {|voices|[voices]};
    if(keys.size>1){(1..(keys.size-1)).do {|step|
        var nextCosts=Array.new,nextPaths=Array.new;
        candidates[step].do {|voices|
            var best=1e9,bestPath;
            candidates[step-1].do {|previous,i|
                var cost=costs[i]+~ghMove.value(previous,voices);
                if(cost<best){best=cost;bestPath=paths[i]++[voices]};
            };
            nextCosts=nextCosts.add(best);nextPaths=nextPaths.add(bestPath);
        };
        costs=nextCosts;paths=nextPaths;
    }};
    paths[costs.minIndex];
};
~ghLabel={|key,voices|
    var spec=~ghSpecs[key],bass=voices.collect {|p|p[1]}.minItem%12;
    var names=["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"];
    if(spec[\label].contains("/") or:{bass==spec[\root]}){spec[\label]}{spec[\label]++"/"++names[bass]};
};
)
