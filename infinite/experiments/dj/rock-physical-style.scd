// Playing decisions for the modal string and shared pedal rig. See GUITAR.md.
// The earlier gesture stream remains available for saved tone-version-1 tracks.
(
~djRockPhysicalExpression={|events,plan|
    var previous=plan[\rockPhysicalLead],opens=[40,45,50,55,59,64];
    events.collect {|event|
        var e=event.copy,rng,random,lead,at,near,strings,string,roll;
        if(e.voice==\rockGuitar){
            rng=((e.seed*65537)+((plan.serial+1).squared*13007)+524287)%2147483646+1;
            random={rng=(rng*48271)%2147483647;rng/2147483647};
            lead=e.role==\djHook;at=(plan.engineBar*4)+e.beat;
            strings=(0..5).select {|i|(e.midinote-opens[i]).inclusivelyBetween(0,22)};
            string=strings.sort {|a,b|(e.midinote-opens[a]-7).abs<(e.midinote-opens[b]-7).abs}.first ? 0;
            near=lead and:{previous.notNil} and:{(at-previous.end).abs<0.22}
                and:{(e.midinote-previous.note).abs.inclusivelyBetween(1,5)};
            if(near and:{strings.includes(previous.string)}){string=previous.string}{near=false};
            e.voice=\rockPhysicalGuitar;e.stringIndex=string;e.fromNote=e.midinote;
            e.slideBeats=0;e.bendSemis=0;e.bendMode=0;e.vibrato=0;e.vibratoRate=4.7+(random.value*1.0);
            e.pickPosition=0.105+(random.value*0.045); // metres from bridge, not an arbitrary comb fraction
            e.articulation=0;roll=random.value;
            if(lead){
                if(near and:{roll<0.32}){
                    e.fromNote=previous.note;e.slideBeats=(e.duration*0.30).clip(0.08,0.18);
                    e.articulation=1; // fretted slide: retained energy, no fresh pick transient
                }{
                    if(e.duration>=0.60 and:{roll<0.55} and:{e.midinote>=57}){
                        e.bendSemis=if(random.value<0.65){1}{2};
                        e.bendMode=if(e[\rockLanding] ? false){2}{1};
                        // An arrival bend must be possible below the target on this string.
                        if((e.midinote-e.bendSemis)<opens[string]){e.bendMode=0;e.bendSemis=0};
                    };
                };
                if(e.duration>=0.75){e.vibrato=0.12+(random.value*0.16)};
                if(e[\rockLanding] ? false){e.vibrato=e.vibrato.min(0.18)};
                previous=(note:e.midinote,end:at+e.duration,string:string);
                plan.rockPhysicalLead=previous;
            };
        };
        e;
    };
};
~djRockPhysicalFX={|plan|
    var quiet=[\intro,\space,\breakdown].includes(plan.section),id=plan.palette.id;
    var solo=plan[\rockSoloActive] ? false,t=plan.effective.tension;
    (guitarComp:if(id==1){0.48}{0.18},guitarChorus:if(id==1){0.24}{0.025},
        guitarPedal:if(quiet){if(id==1){0}{1}}{[2,1,3][id]},
        guitarDrive:((if(quiet){0.08}{[0.28,0.12,0.48][id]})+(t*0.22)+if(solo){0.08}{0}).clip(0,0.8),
        guitarTone:(0.42+(t*0.18)).clip(0,1),
        // A whole phrase uses a single rig: simultaneous notes interact in its circuit.
        guitarFuzz:if(id==2 and:{quiet.not} and:{plan.localBar%8>=4}){0.72}{0});
};
)
