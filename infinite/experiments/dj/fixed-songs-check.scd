// Approved fixed songs in the live EDM/Pop rotation. Pure engine check; no audio.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,message|if(ok.not){Error(message).throw}};
var strip={|event|[event.lane,event.voice,event.step,event.midinote,event.duration,event.amp,event.tone,event.pan]};
try {
    (root+/+"engine.scd").load;
    assert.value(~djFixedSongs.size==5,"Expected five approved songs");
    [\edme,\pop].do {|channel|
        var expected=~djFixedSongs.select {|spec|spec.channel==channel}.collect(_.id).asSet,heard=Set.new;
        [11,2600,4242].do {|seed|
            var engine=~makeDJEngine.value(seed,128,(channel:channel,autoStutter:false)),checked=Set.new;
            400.do {
                var frame=engine[\nextBar].value;
                frame.decks.do {|plan|
                    if(plan.notNil and:{plan[\fixedSong].notNil}){
                        var spec=plan.fixedSong,local=(plan.position-1)%plan.length;
                        var mine=frame.events.select {|e|e.deck==plan.deck};
                        heard.add(spec.id);
                        assert.value(spec.channel==channel,"Song played on the wrong channel");
                        assert.value(mine.every {|e|e.lane!=1},"Instrumental song played a lead");
                        assert.value(plan.targetBpm==spec.bpm,"Song lost its approved tempo");
                        if(local<plan.sections[0].bars){
                            assert.value(mine.every {|e|e.lane==3},"Song intro has pitched parts");
                        };
                        if(local==0){checked.add(plan.serial)};
                    };
                };
            };
            if(seed==11){assert.value(checked.size>=2,"Rotation played too few approved songs")};
        };
        assert.value(heard==expected,"Rotation missed an approved "++channel++" song");
    };
    // One full live pass equals the shared backing for its mapped source bars.
    ~djFixedSongs.do {|spec|
        var form=~djFixedSongLiveForm.value(4),state=~djFixedSongState.value,live=~djFixedSongState.value;
        var plan=(fixedSong:spec,fixedSourceBars:form.sourceBars,fixedState:live,deck:1,serial:3,palette:(color:2));
        assert.value(form.length==56 and:{form.sourceBars.last==7},"Unexpected live song form");
        form.length.do {|local|
            var a=~djFixedSongLiveBar.value(plan,local).collect(strip);
            var b=~djFixedSongBar.value(spec,form.sourceBars[local],state).events.collect(strip);
            assert.value(a==b,"Live bar differs from the shared backing");
        };
    };
    // Grammar checks and rehearsal settings can opt out.
    [(fixedSongs:false),(palette:1),(tonality:\dorian)].do {|settings|
        var engine=~makeDJEngine.value(11,128,(channel:\pop,autoStutter:false).putAll(settings));
        300.do {
            engine[\nextBar].value.decks.do {|plan|
                assert.value(plan.isNil or:{plan[\fixedSong].isNil},"Fixed song ignored "++settings.asString);
            };
        };
    };
    "Fixed songs OK".postln;
    0.exit;
} {|error|error.reportError;1.exit};
)
