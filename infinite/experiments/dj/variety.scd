// Song-level choices. Explicit seeds still reproduce a performance.
(
~djFreshSeed={
    var seed=(Date.seed.abs%2147483646)+1;
    if(seed==~djLastFreshSeed){seed=(seed%2147483646)+1};
    ~djLastFreshSeed=seed;seed;
};
~djFormTemplates=(
    edme:[
        [\intro,\groove,\hook,\breakdown,\buildup,\drop,\outro],
        [\intro,\hook,\groove,\space,\drop,\breakdown,\buildup,\drop,\outro],
        [\intro,\groove,\drop,\groove,\breakdown,\buildup,\hook,\outro],
        [\intro,\groove,\space,\groove,\buildup,\drop,\outro],
        [\intro,\buildup,\drop,\breakdown,\hook,\groove,\drop,\outro],
        [\intro,\groove,\hook,\space,\groove,\hook,\drop,\outro]
    ],
    pop:[
        [\intro,\groove,\buildup,\hook,\groove,\hook,\space,\drop,\outro],
        [\intro,\hook,\groove,\hook,\breakdown,\groove,\drop,\outro],
        [\intro,\groove,\hook,\groove,\buildup,\drop,\outro],
        [\intro,\groove,\space,\hook,\groove,\hook,\breakdown,\drop,\outro],
        [\intro,\hook,\space,\groove,\buildup,\hook,\drop,\outro],
        [\intro,\groove,\buildup,\hook,\breakdown,\drop,\outro]
    ],
    dubstep:[
        [\intro,\groove,\space,\drop,\outro],
        [\intro,\drop,\breakdown,\groove,\drop,\outro],
        [\intro,\groove,\breakdown,\drop,\space,\drop,\outro]
    ],
    rock:[
        [\intro,\groove,\hook,\groove,\hook,\space,\drop,\outro],
        [\intro,\hook,\groove,\hook,\breakdown,\drop,\outro],
        [\intro,\groove,\space,\groove,\buildup,\drop,\outro],
        [\intro,\groove,\hook,\breakdown,\groove,\drop,\hook,\outro],
        [\intro,\groove,\hook,\groove,\drop,\outro],
        [\intro,\groove,\buildup,\hook,\space,\hook,\drop,\outro]
    ]
);
~djSongForm={|channel,id,choose|
    var lengths=(
        intro:[4,8,12],groove:[8,12,16,24],hook:[8,12,16],drop:[8,16,24],
        space:[4,8,12],breakdown:[4,8,12],buildup:[4,8],outro:[8,12,16]
    );
    ~djFormTemplates[channel].wrapAt(id).collect {|section|[section,choose.value(lengths[section])]};
};
)
