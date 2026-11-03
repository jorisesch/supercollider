// Strings are numbered 0 (low E) .. 5 (high E). All voicings are playable.
(
~gcVoicings=(
    em:[[0,40],[1,47],[2,52],[3,55],[4,59],[5,64]],
    c:[[1,48],[2,52],[3,55],[4,60],[5,64]],
    g:[[0,43],[1,47],[2,50],[3,55],[4,59],[5,67]],
    d:[[2,50],[3,57],[4,62],[5,66]]
);
~gcStroke={|voices,at,direction=\down,material=\hard,speed=1.5,hold=0.7,depth=0.00042,acceleration=0,id=0|
    var sorted=voices.sort {|a,b|a[0]<b[0]},first;
    if(direction==\up){sorted=sorted.reverse};first=sorted.first[0];
    sorted.collect {|pair,order|
        var distance=(pair[0]-first).abs*0.0105,travel,localSpeed,initial;
        localSpeed=(speed.squared+(2*acceleration*distance)).max(0.3).sqrt;
        travel=if(direction==\simultaneous or:{direction==\pinch}){0}{2*distance/(speed+localSpeed)};
        initial=~gcInitial.value(pair[1],pair[0],material,depth,localSpeed,if(direction==\up){-1}{1});
        (at:at+travel+if(direction==\simultaneous or:{direction==\pinch}){0}{initial[\releaseLatency]},
            touchAt:at+travel,note:pair[1],string:pair[0],hold:hold,initial:initial,
            direction:direction,stroke:id,order:order,gesture:nil);
    };
};
~gcBuildStudies={
    var strums=List.new,contacts=List.new,doubles=List.new,chords=[\em,\c,\g,\d];
    var thirds=[[[3,64],[4,67]],[[3,66],[4,69]],[[3,67],[4,71]],[[3,69],[4,72]]];
    var sixths=[[[2,62],[4,71]],[[2,64],[4,72]],[[2,66],[4,74]],[[2,67],[4,76]]];
    var materials=[\hard,\angled,\flexible,\flesh,\nail];
    5.do {|section|
        8.do {|i|
            var chord=~gcVoicings[chords[(i div:2)%4]],direction,speed=1.5,voices,at=0.1+(section*8)+(i*0.72);
            direction=switch(section,0,{\simultaneous},1,{\down},2,{\up},3,{if(i.even){\down}{\up}},4,{if(i.even){\down}{\up}});
            voices=if(section==3 and:{i.odd}){chord.select {|pair|pair[0]>=3}}{chord};
            if(section==4){speed=if(i.even){0.65}{3.2}};
            strums.addAll(~gcStroke.value(voices,at,direction,\hard,speed,0.52,0.00042,
                if(section==3){6}{0},(section*8)+i));
        };
    };
    materials.do {|material,section|
        [64,67,69,71].do {|note,i|
            contacts.addAll(~gcStroke.value([[if(note<67){4}{5},note]],0.1+(section*6)+(i*0.6),\down,material,1.5,0.44,0.00042,0,(section*5)+i));
        };
        contacts.addAll(~gcStroke.value(~gcVoicings[\em],3.1+(section*6),\down,material,1.5,1.25,0.00042,0,(section*5)+4));
    };
    // Adjacent-string thirds: tiny ordered pick rake, never a doubled single oscillator.
    8.do {|i|doubles.addAll(~gcStroke.value(thirds[i%4],0.1+(i*0.72),if(i.even){\down}{\up},\hard,1.6,0.55,0.00042,0,i))};
    // Nonadjacent sixths: thumb/finger pinch can select the pair without a spare string.
    8.do {|i|doubles.addAll(~gcStroke.value(sixths[i%4],8.1+(i*0.72),\pinch,\flesh,1.5,0.58,0.00065,0,8+i))};
    // G-string A bends toward the held B on the next string. The partner is fixed.
    3.do {|i|
        var events=~gcStroke.value([[3,69],[4,71]],16.1+(i*1.9),\down,\hard,1.4,1.5,0.00042,0,16+i);
        var lower=events.detect {|e|e[\string]==3};
        lower[\gesture]=(
            offset:0,levels:if(i==0){[0,0,1.7,2.10,1.96,2,2]}{if(i==1){[2,2,1.3,0,0,0,0]}{[0,0.85,0.85,2.05,1.98,2,2]}},
            times:[0.10,0.18,0.16,0.26,0.20,0.10]*1.5,
            depth:[0.22,0.12,0.28][i],delay:[0.65,0.90,0.43][i],rise:[0.12,0.08,0.17][i],grow:0.45,
            rateStart:[4.8,5.3,5.8][i],rateEnd:[5.5,5.0,6.4][i],
            wander:0.04,phase:[0,0.7,1.3][i],skew:1.2,vibMode:if(i==1){0}{2},notch:0,notchAt:0.5);
        doubles.addAll(events);
    };
    // Short double-stop chops alternate with more open, ringing pair answers.
    10.do {|i|
        var pair=thirds.wrapAt([0,0,1,2,2,3,2,1,0,0][i]),hold=if(i%3==0){0.17}{0.47};
        doubles.addAll(~gcStroke.value(pair,24.1+(i*0.55),if(i.even){\down}{\up},if(i%3==1){\nail}{\angled},
            1.2+(i%3*0.55),hold,0.00042,0,24+i));
    };
    (strums:strums.asArray,contacts:contacts.asArray,doubles:doubles.asArray);
};
)
