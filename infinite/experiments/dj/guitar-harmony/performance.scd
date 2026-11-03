// Four harmony/articulation studies, using the earlier contact/string rig.
(
~ghBuildStudies={
    var studies=(triads:List.new,extensions:List.new,slash:List.new,phrasing:List.new);
    var changes=List.new,changeID=0,strokeID=0,register,add,emit,choose,keys,rootPath,ledPath;
    register={|study,section,key,voices,at,until,pattern|
        var id=changeID,spec=~ghSpecs[key],notes=voices.collect {|p|p[1]};
        changes.add((id:id,study:study,section:section,key:key,label:~ghLabel.value(key,voices),
            voices:voices.deepCopy,bass:notes.minItem,at:at,until:until,pattern:pattern,
            inversion:if(spec[\intervals].size==3){spec[\intervals].indexOf((notes.minItem-spec[\root])%12) ? -1}{-1}));
        changeID=changeID+1;id;
    };
    emit={|study,id,voices,at,hold,direction=\down,material=\hard,cutoff=1e6,depth=0.00040|
        var events=~gcStroke.value(voices,at,direction,material,1.6,hold,depth,0,strokeID);
        strokeID=strokeID+1;
        events.do {|e|
            e[\hold]=e[\hold].min(cutoff-e[\at]-0.085);
            if(e[\hold]>=0.06){e[\change]=id;studies[study].add(e)};
        };
    };
    add={|study,section,key,voices,at,hold=0.65,direction=\down,material=\hard,pattern=\chord|
        var id=register.value(study,section,key,voices,at,at+hold+0.16,pattern);
        emit.value(study,id,voices,at,hold,direction,material);id;
    };
    choose={|key,inversion,target|
        ~ghTriads.value(key,#[2,3,4],inversion).sort {|a,b|
            (a.collect {|p|p[1]}.mean-target).abs<(b.collect {|p|p[1]}.mean-target).abs
        }.first;
    };
    [\a,\fsmin].do {|key,section|
        6.do {|i|var inversion=i%3,base=if(key==\a){61}{58},voices;
            voices=choose.value(key,inversion,base+(inversion*4));
            add.value(\triads,section,key,voices,0.1+(section*8)+(i*1.23),0.88);
        };
    };
    keys=[\a,\fsmin,\d,\e,\a,\fsmin,\d,\e];
    rootPath=~ghLead.value(keys,true);ledPath=~ghLead.value(keys,false);
    [rootPath,ledPath].do {|path,j|
        path.do {|voices,i|add.value(\triads,j+2,keys[i],voices,16.1+(j*8)+(i*0.85),0.64)};
    };
    [\a,\amaj7,\a7,\amin7,\aadd9,\a9].do {|key,section|
        var voices=~ghShapes[key],start=0.1+(section*6),id;
        id=register.value(\extensions,section,key,voices,start,start+5.1,\color_comparison);
        [0,0.75,1.50,2.25].do {|offset,i|emit.value(\extensions,id,voices,start+offset,0.45,if(i.even){\down}{\up})};
        voices.do {|pair,i|emit.value(\extensions,id,[pair],start+3.1+(i*0.23),0.68,\down)};
    };
    [\a,\acs,\ae].do {|key,i|add.value(\slash,0,key,~ghShapes[key],0.1+(i*2.35),1.30,\down)};
    // Re-pick the low E every three seconds; upper harmonies change above it.
    [[\e,\pedalE],[\ae,\pedalA],[\de,\pedalD],[\e7,\pedalE7]].do {|entry,i|
        var voices=~ghShapes[entry[1]],at=8.1+(i*1.5),id;
        id=register.value(\slash,1,entry[0],voices,at,at+1.5,\e_pedal);
        if(i.even){emit.value(\slash,id,[voices.first],at,2.85,\pinch,\nail,16,0.00052)};
        emit.value(\slash,id,voices.drop(1),at,1.05,\pinch,\nail,at+1.5,0.00052);
    };
    [[\a,\highA],[\egs,\highEgs],[\fsmin7,\highFsmin7],[\e,\highE],
        [\d,\highD],[\acs,\acs],[\bmin7,\bmin7],[\e7shell,\highE7shell]].do {|entry,i|
        add.value(\slash,2,entry[0],~ghShapes[entry[1]],16.1+(i*0.85),0.64,\pinch,\nail,\descending_bass);
    };
    [\ae,\e7,\ae,\e7,\aadd9].do {|key,i|
        var voices=~ghShapes[key],at=24.1+(i*1.25),id;
        id=register.value(\slash,3,key,voices,at,at+1.25,\resolved_riff);
        emit.value(\slash,id,voices,at,0.64,\down);
        emit.value(\slash,id,voices.select {|p|p[0]>=3},at+0.78,0.20,\up,\hard,at+1.25);
    };
    [\block,\syncopation,\bass_answer,\arpeggio].do {|pattern,section|
        [\a,\fsmin7,\dadd9,\e7].do {|key,bar|
            var voices=~ghShapes[key],barStart=0.1+(section*10)+(bar*2.4);
            var onset=barStart-if(pattern==\arpeggio and:{bar>0}){0.15}{0};
            var next=barStart+2.4-if(pattern==\arpeggio and:{bar<3}){0.15}{0};
            var id=register.value(\phrasing,section,key,voices,onset,next,pattern);
            switch(pattern,
                \block,{[0,2].do {|beat|emit.value(\phrasing,id,voices,barStart+(beat*0.6),0.95,\down,\hard,next)}},
                \syncopation,{[0.5,1.75,2.5,3.5].do {|beat,i|
                    emit.value(\phrasing,id,voices,barStart+(beat*0.6),[0.14,0.22,0.14,0.18][i],if(i.even){\up}{\down},\hard,next)}},
                \bass_answer,{
                    [0,2].do {|beat|
                        emit.value(\phrasing,id,[voices.first],barStart+(beat*0.6),1.02,\pinch,\nail,next,0.00054);
                        emit.value(\phrasing,id,voices.drop(1),barStart+((beat+0.5)*0.6),0.58,\pinch,\nail,next,0.00054);
                    };
                },
                \arpeggio,{
                    [0,1,-1,2,0,-2,-1,1].do {|index,i|
                        var at=if(i==0){onset}{barStart+(i*0.3)},pair=voices.wrapAt(index);
                        emit.value(\phrasing,id,[pair],at,if(index==0){0.92}{0.58},if(i.even){\down}{\up},\hard,next);
                    };
                }
            );
        };
    };
    ~ghChanges=changes.asArray;~ghPaths=(root:rootPath,led:ledPath,keys:keys);
    studies.keysValuesDo {|key,list|studies[key]=list.asArray};studies;
};
)
