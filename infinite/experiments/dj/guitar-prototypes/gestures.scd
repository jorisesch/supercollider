// Opt-in performance studies. No changes to the live DJ or its saved recipes.
(
~gpProfiles=[\reference,\restrained,\loose,\urgent];
~gpPhrase=[
    [0,64,1.3,\plain],[1.5,67,0.45,\curl],[2.25,69,1.25,\arrival],
    [4,71,1.35,\preRelease],[5.75,69,0.4,\plain],[6.5,67,0.8,\curl],
    [8,64,2.5,\hold],[11,67,0.45,\plain],[11.75,69,1.25,\arrival],
    [13.5,71,1.75,\double],[16,74,1.5,\hold],[17.75,71,0.5,\plain],
    [18.5,69,1,\release],[20,67,1,\curl],[21.25,69,1.8,\arrival],
    [24,71,0.5,\plain],[24.75,69,0.5,\plain],[25.5,67,1,\plain],
    [27,64,4,\anchor]
];
~gpGesture={|profile,note,index,hold,seed=731|
    var rng=((seed*65537)+(index*104729)+1)%2147483646+1,random;
    var kind=note[3],p=(hold:hold,note:note[1],index:index,profile:profile,kind:kind);
    var weights=[0.10,0.20,0.15,0.30,0.15,0.10],error,overshoot,depth,onset,rate,roll;
    random={rng=(rng*48271)%2147483647;rng/2147483647};
    p[\offset]=0;p[\levels]=Array.fill(7,0);p[\times]=weights*hold;
    p[\depth]=0;p[\delay]=0;p[\rise]=0.05;p[\grow]=1;p[\rateStart]=5.3;p[\rateEnd]=5.3;
    p[\wander]=0;p[\phase]=0;p[\skew]=1;p[\vibMode]=0;p[\notch]=0;p[\notchAt]=0.55;
    p[\refBend]=0;p[\refMode]=0;p[\refVib]=0;
    if(profile==\reference){
        if([\arrival,\double,\preRelease,\release].includes(kind)){
            p[\refBend]=2;p[\refMode]=if(kind==\arrival){2}{1};
        };
        if(hold>=0.45){p[\refVib]=0.18};
        p[\kind]=if(p[\refMode]==1){\upReturn}{if(p[\refMode]==2){\arrival}{\plain}};
    }{
        error=(random.value-0.5)*if(profile==\loose){0.24}{0.10};
        overshoot=if(profile==\urgent){0.10+(random.value*0.12)}{random.value*0.08};
        roll=random.value;
        // A few notes that invite an ornament are deliberately left plain.
        if(profile==\restrained and:{[1,5,8,12,13].includes(index)}){kind=\plain};
        if(profile==\urgent and:{[1,5,13].includes(index)}){kind=\plain};
        p[\kind]=kind;
        switch(kind,
            \arrival,{
                p[\offset]= -2;
                p[\levels]=[0,0,1.6+(random.value*0.28),2+overshoot,2+error,2+error,2];
                if(profile==\loose and:{index==8}){
                    // This passing bend remains a little flat until it is released.
                    p[\levels]=p[\levels].collect {|v,i|if(i>=3){1.84+(random.value*0.08)}{v}};
                };
                // Hand hesitation and correction time vary independently of note length.
                weights=[0.025+(random.value*0.12),0.16+(random.value*0.16),0.08,0.28,0.16,0.10];
                p[\vibMode]=if(profile==\loose){1}{2};
            },
            \preRelease,{
                // Pick an already bent string, then relax toward the fretted note.
                p[\levels]=[2+error,2+error,1.75,0.6,0,0,0];
                weights=[0.10,0.13,0.15,0.18,0.18,0.26];
            },
            \release,{
                p[\levels]=[1+error,1,0.4,0,0,0,0];
                weights=[0.05,0.12,0.18,0.20,0.20,0.25];
            },
            \double,{
                p[\levels]=[0,0.85,0.85,2+overshoot,2+error,1.75,0];
                weights=[0.15,0.17,0.13,0.28,0.12,0.15];
                p[\vibMode]=2;
            },
            \curl,{
                // An intentionally incomplete blues inflection on G, the minor third.
                depth=if(profile==\loose){0.25+(random.value*0.25)}{0.18+(random.value*0.18)};
                p[\levels]=[0,0,depth,depth*0.7,depth*0.4,0,0];
                weights=[0.06,0.18,0.16,0.24,0.20,0.16];
            }
        );
        p[\times]=weights.normalizeSum*hold;
        // Plain short connectors and selected long notes have no vibrato at all.
        if(hold>=0.45 and:{kind!=\curl} and:{kind!=\plain or:{roll<0.20}}){
            onset=switch(profile,
                \restrained,{0.28+(random.value*0.45)},
                \loose,{0.08+(random.value*0.60)},
                \urgent,{0.015+(random.value*0.20)});
            if(kind==\arrival){onset=onset.max(p[\times].keep(3).sum+0.025)};
            p[\delay]=onset.min(hold*0.78);
            p[\rise]=if(profile==\urgent){0.04+(random.value*0.06)}{0.10+(random.value*0.18)};
            p[\depth]=switch(profile,\restrained,{0.12+(random.value*0.10)},
                \loose,{0.22+(random.value*0.18)},\urgent,{0.17+(random.value*0.20)});
            rate=switch(profile,\restrained,{4.3+(random.value*0.6)},
                \loose,{4.0+(random.value*0.9)},\urgent,{5.4+(random.value*0.9)});
            p[\rateStart]=rate;
            p[\rateEnd]=rate*switch(profile,\restrained,{1.03},\loose,{0.90+(random.value*0.30)},\urgent,{1.15});
            p[\wander]=if(profile==\loose){0.12}{0.035};
            p[\phase]=random.value*2pi;p[\skew]=0.8+(random.value*0.6);
            p[\grow]=if(profile==\restrained){0.35}{if(profile==\loose){0.55}{0.8}};
            if(profile==\loose and:{index%3==0}){p[\notch]=0.88;p[\notchAt]=0.42+(random.value*0.20)};
            if(kind==\anchor){p[\depth]=p[\depth].min(0.24);p[\notch]=0};
            if([\preRelease,\release].includes(kind)){
                // Vibrato enters after the release on this particular phrase.
                p[\delay]=p[\delay].max(hold*0.60);p[\vibMode]=0;
            };
        };
        // Let the first long statement ring straight in the restrained study.
        if(profile==\restrained and:{index==6}){p[\depth]=0};
    };
    p;
};
~gpArgs={|p|
    var args=[\pOffset,p[\offset],\pVDepth,p[\depth],\pVDelay,p[\delay],\pVRise,p[\rise],
        \pVGrow,p[\grow],\pRateStart,p[\rateStart],\pRateEnd,p[\rateEnd],\pWander,p[\wander],
        \pPhase,p[\phase],\pSkew,p[\skew],\pVMode,p[\vibMode],\pNotch,p[\notch],\pNotchAt,p[\notchAt]];
    p[\levels].do {|v,i|args=args++[("pB"++i).asSymbol,v]};
    p[\times].do {|v,i|args=args++[("pT"++i).asSymbol,v]};args;
};
)
