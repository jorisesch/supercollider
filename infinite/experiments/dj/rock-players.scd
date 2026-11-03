// Fictional guitarists: song-level habits, with bounded performance variation.
// Pure score policy; no SynthDefs or playback. See PLAYERS.md.
(
~djRockPlayers=[
    (id:0,name:"Rook",description:"Clipped garage rhythm, short answers, narrow vibrato",
        rhythm:[[0,2,4,6,8,10,12,14],[0,2,4,6,8,10,12,15]],
        chorus:[[0,2,6,8,10,14],[0,2,6,8,10,15]],
        leadRhythm:[[0,2,4,8,10,12],[0,2,4,8,11]],
        contour:[[0,2,4,2,0,2],[0,2,4,2,1,0]],
        mute:0.66,pick:0.112,pickSpread:0.002,rate:5.0,rateSpread:0.08,
        vibrato:0.14,vibratoSpread:0.015,vibratoAfter:1.0,
        slideChance:0.16,bendChance:0.36,bendSemis:1,
        pedal:2,drive:0.32,driveMin:0.28,driveMax:0.41,tone:0.46,comp:0.18,chorusFX:0.025,fuzz:0),
    (id:1,name:"June",description:"Ringing jangle, spaced replies, light quick vibrato",
        rhythm:[[0,6,8,14],[0,6,8,15]],chorus:[[0,4,7,8,12,14],[0,4,7,8,12,15]],
        leadRhythm:[[0,4,8,12],[0,4,7,12]],contour:[[0,2,4,2],[2,1,0,2]],
        mute:0.22,pick:0.140,pickSpread:0.0025,rate:5.8,rateSpread:0.08,
        vibrato:0.12,vibratoSpread:0.012,vibratoAfter:0.75,
        slideChance:0.42,bendChance:0.14,bendSemis:1,
        pedal:1,drive:0.10,driveMin:0.06,driveMax:0.19,tone:0.51,comp:0.48,chorusFX:0.24,fuzz:0),
    (id:2,name:"Flint",description:"Heavy spaced riffs, broad slow vibrato, whole-step bends",
        rhythm:[[0,3,8,11],[0,3,8,14]],chorus:[[0,3,6,8,11,14],[0,3,6,8,11,15]],
        leadRhythm:[[0,3,6,8,11],[0,3,8,12]],contour:[[0,2,0,4,2],[4,2,0,1]],
        mute:0.45,pick:0.102,pickSpread:0.002,rate:4.6,rateSpread:0.07,
        vibrato:0.23,vibratoSpread:0.015,vibratoAfter:0.75,
        slideChance:0.12,bendChance:0.58,bendSemis:2,
        pedal:3,drive:0.46,driveMin:0.42,driveMax:0.55,tone:0.42,comp:0.18,chorusFX:0.025,fuzz:0.52)
];
~djRockPlayerFor={|plan,seed|
    var player=~djRockPlayers[plan.palette.id].deepCopy;
    // Separate from the engine RNG, preserving drum/harmony decisions.
    var n=((seed.abs*65537)+((plan.serial+1)*104729)+13007)%2147483647;
    player.motif=n%2;player;
};
~djRockPlayerLabel={|plan|
    if(plan.notNil and:{plan[\rockPlayer].notNil}){" / Guitar: "++plan.rockPlayer.name}{""};
};
~djRockPlayerRhythm={|events,plan,partBar,quiet,intro,progress,chorus,effective|
    var p=plan.rockPlayer,chords=events.select {|e|e.role==\rockChord},result=List.new,steps,templates;
    var answer=partBar%8==7 and:{effective.mutation>0.2} and:{(plan[\rockHeld] ? false).not};
    var rng=((plan.serial+1)*104729)+(plan.localBar*997)+13007,random;
    random={rng=(rng*48271)%2147483647;rng/2147483647};
    plan.rockRhythmVariant=if(answer){1}{0};
    if(chords.isEmpty or:{quiet} or:{intro and:{progress<0.4}}){events}{
        templates=chords.select {|e|e.step==chords.first.step};
        steps=(if(chorus){p.chorus}{p.rhythm})[plan.rockRhythmVariant];
        if(effective.density<0.3){steps=[0,8]};
        events.reject {|e|e.role==\rockChord}.do {|e|result.add(e)};
        steps.do {|step,i|
            var next=steps.at(i+1) ? 16;
            templates.do {|original,j|
                var e=original.copy,offset=original.beat-(original.step*0.25);
                e.beat=((step*0.25)+offset+((random.value-0.5)*0.004)).clip(0,3.95);e.step=step;
                e.duration=if(chorus){((next-step)*0.25-0.04).clip(0.16,0.85)}{if(step%4==0){0.27}{0.17}};
                e.amp=original.amp*if(step%4==0){1}{0.78};
                e.mute=(p.mute+if(chorus){-0.16}{0.04}).clip(0.08,0.86);
                e.seed=original.seed+(step*997)+j;
                result.add(e);
            };
        };
        result.asArray;
    };
};
~djRockPlayerFX={|plan|
    var p=plan.rockPlayer,quiet=[\intro,\space,\breakdown].includes(plan.section);
    var solo=plan[\rockSoloActive] ? false,t=plan.effective.tension;
    // The pedal, chorus and compressor stay fixed for this song. Section
    // dynamics and Tension move gain only within the player's personal range.
    (guitarComp:p.comp,guitarChorus:p.chorusFX,guitarPedal:p.pedal,
        guitarDrive:(p.drive+if(quiet){-0.04}{0}+(t*0.04)+if(solo){0.025}{0}).clip(p.driveMin,p.driveMax),
        guitarTone:p.tone+(t*0.04),guitarFuzz:p.fuzz);
};
)
