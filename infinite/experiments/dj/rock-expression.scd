// Guitar gestures are assigned after pentatonic/chord-tone landing decisions.
// This separate seeded stream leaves the written notes and rhythm section intact.
(
~djRockExpression={|events,plan|
    var previous=plan[\rockPreviousLead];
    var result=events.collect {|event|
        var e=event.copy,rng,random,roll,at,interval,near,lead,quiet;
        if(e.voice==\rockGuitar){
            rng=((e.seed*65537)+((plan.serial+1).squared*13007)+524287)%2147483646+1;
            random={rng=(rng*48271)%2147483647;rng/2147483647};
            lead=e.role==\djHook;quiet=[\intro,\space,\breakdown].includes(plan.section);
            e.voice=\rockExpressiveGuitar;e.fromNote=e.midinote;e.slideBeats=0;
            e.bendSemis=0;e.bendMode=0;e.vibrato=0;e.vibratoRate=4.8+(random.value*1.2);
            e.pick=0.32+(random.value*0.28);
            e.pedal=case {quiet}{if(plan.palette.id==1){0}{1}}
                {plan.palette.id==0}{2} {plan.palette.id==1}{1}
                {true}{if(plan.hook){3}{2}};
            e.pedalGain=(0.10+(e.drive*0.50)+(plan.effective.tension*0.22)).clip(0.05,0.8);
            if(quiet){e.pedalGain=e.pedalGain*0.45};
            if(lead){
                at=(plan.engineBar*4)+e.beat;roll=random.value;
                interval=if(previous.isNil){0}{(e.midinote-previous.note).abs};
                near=previous.notNil and:{(at-previous.end).abs<0.22} and:{interval>0} and:{interval<=5};
                e.pedal=if(plan.palette.id==2 and:{(e[\rockPhraseAge] ? 0)%4>=2}){3}{if(plan.palette.id==0){2}{1}};
                e.pedalGain=(0.30+(plan.effective.tension*0.25)).clip(0.2,0.7);
                if(near and:{roll<0.28}){
                    e.fromNote=previous.note;e.slideBeats=(e.duration*0.28).clip(0.07,0.18);
                }{
                    if(e.duration>=0.45 and:{roll<0.50}){
                        e.bendSemis=if(random.value<0.65){1}{2};
                        e.bendMode=if(e[\rockLanding] ? false){2}{1};
                    };
                };
                if(e.duration>=0.55){e.vibrato=0.07+(random.value*0.10)};
                // Arrival bends and vibrato settle back onto the written chord tone.
                if(e[\rockLanding] ? false){e.vibrato=e.vibrato.min(0.11)};
                previous=(note:e.midinote,end:at+e.duration);
            };
        };
        e;
    };
    plan.rockPreviousLead=previous;result;
};
~djRockGuitarFX={|plan|
    var comp=[0.32,0.52,0.22][plan.palette.id],chorus=[0.025,0.18,0.035][plan.palette.id];
    if(plan[\rockSoloActive] ? false){comp=comp+0.08;chorus=chorus+0.035};
    if([\space,\breakdown].includes(plan.section) and:{plan.palette.id==1}){chorus=chorus+0.06};
    (guitarComp:comp.clip(0,0.7),guitarChorus:chorus.clip(0,0.28));
};
)
