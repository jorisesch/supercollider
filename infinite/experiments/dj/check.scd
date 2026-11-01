// Pure checks; no server, playback, or files containing audio.
(
var root=thisProcess.nowExecutingPath.dirname, assert={ |condition,message| if(condition.not) { Error(message).throw } };
try {
    var a,b,styles=Set.new, keys=Set.new, progressions=Set.new, durations=Set.new, hooks=Set.new;
    var forms=Set.new,lengths=Set.new,energies=Set.new,chaosLevels=Set.new;
    var fxFilters=Set.new,fxEchoes=Set.new,fxReverbs=Set.new;
    var bassNotes=0,rootFifths=0,drumOnlyBars=0,palettes=Set.new,recordPalettes=Dictionary.new,definitionNames;
    var deckBars=0,bassBars=0,leadBars=0,leadNotes=0,leadLengths=Set.new;
    var swingHits=0,ghostHits=0,breaths=0,lowGaps=0,returns=0,bassTones=Set.new,bassDrives=Set.new;
    var previousBreath=Dictionary.new,previousSpotlight=Dictionary.new;
    var autoBars=0,autoBursts=0,autoLengths=Set.new,autoRates=Set.new,lastAutoEnd= -8;
    var records=Set.new, previousBpm, mixed=0, builds=0, hookBars=0, active=[], peak=0, seconds=0;
    ["live.scd","controls.scd","deck-view-check.scd","spectrum.scd","spectrum-check.scd","recall.scd","interaction-check.scd","launch.scd","../c-edm.scd"].do { |file|
        assert.value(File.readAllString(root +/+ file).compile.notNil,"Parse failed: " ++ file);
    };
    (root +/+ "engine.scd").load;
    (root +/+ "instruments.scd").load;
    ~djDefs.do { |def| assert.value(def.asBytes.size > 0,"Invalid instrument") };
    definitionNames=~djDefs.collect(_.name);
    ~djLibrary.palettes.do { |palette|
        palette.voices.values.do { |voice| assert.value(definitionNames.includes(voice),"Undefined palette voice: " ++ voice) };
    };
    [\djBass,\djHook,\djKick].do { |role|
        assert.value(~djLibrary.palettes.collect { |p| p.voices[role] }.asSet.size==4,
            "Palette names reuse the same instrument for " ++ role);
    };
    ~djLibrary.palettes.do { |palette|
        var def=~djDefs.detect { |d| d.name==palette.voices[\djBass] };
        assert.value([\tone,\drive].every { |control| def.allControlNames.any { |c| c.name==control } },
            "Bass instrument is missing its filter or saturation control");
    };
    {
        var left=~makeDJEngine.value(2600,128,(palette:0)),right=~makeDJEngine.value(2600,128,(palette:2));
        var musicalFields={ |frame| frame.events.collect { |e| [e.role,e.beat,e.midinote,e.duration,e.amp,e.seed] } };
        32.do {
            assert.value(musicalFields.value(left[\nextBar].value)==musicalFields.value(right[\nextBar].value),
                "Changing instruments changed the composition");
        };
    }.value;
    a=~makeDJEngine.value(2600,128); b=~makeDJEngine.value(2600,128);
    8192.do {
        var frame=a[\nextBar].value, other=b[\nextBar].value, previous=0, barBpm=frame.automation[0].bpm;
        assert.value(frame.events.asCompileString == other.events.asCompileString,"Seeded notes changed");
        assert.value(frame.automation.asCompileString == other.automation.asCompileString,"Seeded mixing changed");
        if(frame.stutter.notNil and: {frame.stutter[\source]==\auto}) {
            var fx=frame.stutter,plan=frame.decks[fx.deck];
            autoBars=autoBars+fx.bars;
            assert.value(a.state.mixing.not and: {plan.serial==fx.serial}
                and: {[\groove,\hook,\drop,\buildup].includes(plan.section)},
                "Automatic stutter escaped its musical placement or record");
            assert.value(fx.bars==0.5 and: {fx.remaining==0.5} and: {fx.division==16} and: {fx.startBeat==2},
                "Automatic stutter lost its half-bar sixteenth shape");
            assert.value(frame.automation.every { |point|
                var on=point.beat>=2 and: {point.beat<4};
                (point.fx[fx.deck].stutter>0)==on
            },"Half-bar stutter escaped beats three and four");
            assert.value(frame.automation.count { |point| point.fx[fx.deck].stutterReset }==1
                and: {frame.automation[8].fx[fx.deck].stutterReset},"Half-bar gate did not reset once on beat three");
            if(fx.age==0) {
                autoBursts=autoBursts+1; autoLengths.add(fx.bars); autoRates.add(fx.division);
                assert.value(frame.bar >= (lastAutoEnd+16),"Automatic stutter has no breathing room");
                lastAutoEnd=frame.bar+1;
            };
        };
        frame.decks.do { |plan|
            if(plan.notNil) {
                var own=frame.events.select { |e| e.deck==plan.deck },lead=own.select { |e| e.role==\djHook };
                deckBars=deckBars+1;
                if(own.any { |e| e.role==\djBass }) {bassBars=bassBars+1};
                if(plan.lowOut) {
                    lowGaps=lowGaps+1;
                    assert.value(own.select { |e| [\djKick,\djBass].includes(e.role) }.every { |e| e.beat<3 }
                        and: {own.any { |e| e.role==\djBass }},"Pre-drop pickup removed too much or leaked late low end");
                };
                assert.value(own.any { |e| e.role==\djKick },"Drum foundation disappeared");
                if(plan.breath) {
                    breaths=breaths+1;
                    assert.value(plan.cutFrom==3
                        and: {own.select { |e| [\djKick,\djBass].includes(e.role) }.every { |e| e.beat<3 }}
                        and: {own.any { |e| e.role==\djBass and: {e.beat>=2} }},
                        "Pullback lasted longer than one beat or leaked late kick/bass hits");
                    if(previousBreath[plan.serial].notNil) {
                        assert.value((plan.localBar-previousBreath[plan.serial])>=16,"Pullbacks became too frequent");
                    };
                    previousBreath[plan.serial]=plan.localBar;
                };
                if(plan.section==\drop and: {plan.sectionProgress==0}) {
                    returns=returns+1;
                    assert.value(own.any { |e| e.role==\djKick and: {e.beat==0} }
                        and: {own.any { |e| e.role==\djBass }},"Drop did not restore kick and bass together");
                };
                assert.value(own.select { |e| [\djArp,\djStab].includes(e.role) }.isEmpty,
                    "Automatic melodic layers returned");
                if(lead.notEmpty) {
                    leadBars=leadBars+1; leadNotes=leadNotes+lead.size;
                    leadLengths.add(lead.size);
                    assert.value([\hook,\drop].includes(plan.section) and: {lead.size<=8}
                        and: {lead.every { |e| e.duration<1 and: {e.amp<0.04} }},
                        "A brief melodic accent turned into a lead passage");
                };
                forms.add(plan.formID); lengths.add(plan.length); energies.add(plan.intensity.round(0.05));
                chaosLevels.add(plan.effective.chaos.round(0.02));
                records.add(plan.serial); styles.add(plan.variation.id); keys.add(plan.key);
                palettes.add(plan.palette.id);
                if(recordPalettes[plan.serial].isNil) {
                    recordPalettes[plan.serial]=plan.palette.id;
                    if(plan.serial>0) {
                        assert.value(recordPalettes[plan.serial-1]!=plan.palette.id,"Consecutive records reused their palette");
                    };
                } {
                    assert.value(recordPalettes[plan.serial]==plan.palette.id,"Palette changed in the middle of a record");
                };
                progressions.add(plan.mode.asString ++ plan.progressionID); durations.add(plan.durationID); hooks.add(plan.hookID);
                plan.schedule.do { |chord,i|
                    assert.value(chord.start <= i and: { chord.start + chord.bars > i },"Chord duration coverage invalid");
                };
                if(plan.section == \buildup) { builds=builds+1 };
                if(plan.hook) { hookBars=hookBars+1 };
                if(plan.drumBreak) {
                    drumOnlyBars=drumOnlyBars+1;
                    if(previousSpotlight[plan.serial].notNil) {
                        assert.value((plan.localBar-previousSpotlight[plan.serial])>=32,"Drum spotlights became too frequent");
                    };
                    previousSpotlight[plan.serial]=plan.localBar;
                    assert.value(frame.events.select { |event| event.deck==plan.deck and: { event.lane < 3 } }.isEmpty,
                        "Drum-only spotlight still contains pitched events");
                };
            };
        };
        if(a.state.mixing) { mixed=mixed+1 };
        if(frame.automation.last.progress >= 1) {
            var arriving=frame.decks.detect { |plan| plan.serial==(a.state.currentSerial+1) };
            assert.value(arriving.position >= arriving.sections.first.bars,"Handover left an unfinished intro");
        };
        frame.events.do { |event|
            var plan=frame.decks[event.deck], scale,degree,allowed;
            var onset=seconds + (event.beat * 60 / barBpm);
            var life=(event.duration * 60 / barBpm) + 1;
            assert.value(definitionNames.includes(event.voice),"Event uses an undefined instrument: " ++ event.voice);
            assert.value(event.voice==(plan.palette.voices[event.role] ? event.role),"Event escaped its record's palette");
            if(frame.bar < 4 and: { event.deck==0 and: { event.role==\djHook } }) {
                assert.value(false,"Opening lead arrived before the groove was established");
            };
            assert.value((event.beat >= previous) and: { event.beat < 4 },"Invalid note timing"); previous=event.beat;
            assert.value(event.track >= 0 and: { event.track < 8 } and: { (event.track div: 4) == event.deck },"Invalid deck/track");
            assert.value(event.amp > 0 and: { event.amp <= 0.65 } and: { event.duration > 0 },"Invalid note levels/duration");
            assert.value(event.tone>=0 and: {event.tone<=1} and: {event.drive>=0} and: {event.drive<=1},
                "Invalid tone or drive");
            if(event.swing>0 and: {event.role!=\djClap}) {
                swingHits=swingHits+1;
                assert.value(event.step.odd and: {event.swing<=0.045}
                    and: {(event.beat-(event.step*0.25)-event.swing).abs<=0.006001},
                    "Swing escaped its sixteenth-note pocket");
            };
            if(event.ghost) {
                ghostHits=ghostHits+1;
                assert.value([\djSnare,\djHat].includes(event.role) and: {event.amp<0.035},
                    "Ghost hits became foreground accents");
            };
            if(event.lane < 3) {
                scale=if(plan.mode == \minor,[0,2,3,5,7,8,10],[0,2,4,5,7,9,11]);
                assert.value(scale.includes((event.midinote - plan.key) % 12),"A note escaped its deck's key");
            };
            if(event.lane==0) {
                var message=~djMessage.value(event,1000,110,16,barBpm);
                bassTones.add(event.tone.round(0.02)); bassDrives.add(event.drive.round(0.02));
                assert.value(message[message.indexOf(\drive)+1]==event.drive,"Bass drive did not reach the synth adapter");
                scale=if(plan.mode==\minor,[0,2,3,5,7,8,10],[0,2,4,5,7,9,11]);
                degree=plan.schedule[plan.localBar].degree;
                allowed=[0,4].collect { |offset| (plan.key+scale.wrapAt(degree+offset))%12 };
                bassNotes=bassNotes+1;
                if(allowed.includes(event.midinote%12)) { rootFifths=rootFifths+1 };
            };
            if(event.role==\djKick) { assert.value((event.beat-event.beat.round).abs < 0.000001,"Kick anchor left the grid") };
            active=active.select { |end| end > onset }; active=active.add(onset+life); peak=peak.max(active.size);
        };
        frame.automation.do { |point|
            var g=point.gains;
            assert.value(point.bpm >= 118 and: { point.bpm <= 140 },"Tempo outside range");
            if(previousBpm.notNil) { assert.value((point.bpm-previousBpm).abs <= 0.032,"Tempo jumped during handover") };
            previousBpm=point.bpm;
            assert.value(g.flat.every { |gain| gain >= 0 and: { gain <= 1 } },"Invalid crossfader gain");
            assert.value((g[0][2]+g[1][2]-1).abs < 0.000001,"Drum crossfade is not complementary");
            assert.value(((g[0][0].max(g[0][1]) > 0.000001) and: { g[1][0].max(g[1][1]) > 0.000001 }).not,
                "Different-key pitched decks overlap");
            point.fx.do { |fx|
                assert.value(fx.filter >= 0 and: { fx.filter <= 1 } and: { fx.cutoff >= 500 }
                    and: { fx.cutoff <= 18000 } and: { fx.resonance >= 0.12 } and: { fx.resonance <= 0.9 }
                    and: { fx.echo >= 0 } and: { fx.echo <= 1 } and: { fx.delay >= 0.08 }
                    and: { fx.delay <= 0.75 } and: { fx.reverb >= 0 } and: { fx.reverb <= 1 }
                    and: { fx.stutter >= 0 } and: { fx.stutter <= 1 },"Invalid deck FX automation");
                fxFilters.add(fx.filter.round(0.02)); fxEchoes.add(fx.echo.round(0.02));
                fxReverbs.add(fx.reverb.round(0.02));
            };
            frame.decks.do { |plan,id|
                if(plan.notNil and: {plan.drumBreak}) {
                    assert.value(g[id][0]==0 and: {g[id][1]==0},"Pitched tails leak into drum spotlight");
                };
            };
        };
        seconds=seconds+(240/barBpm);
    };
    assert.value(styles.size == 32 and: { keys.size == 12 } and: { progressions.size == 32 }
        and: { durations.size == 20 } and: { hooks.size == 16 },"Catalog rotation did not cover the library");
    assert.value(forms.size==6 and: { lengths.size >= 5 } and: { energies.size >= 10 }
        and: { chaosLevels.size >= 8 } and: { fxFilters.size >= 8 } and: { fxEchoes.size >= 5 }
        and: { fxReverbs.size >= 6 },"Record length/energy/chaos/FX did not vary");
    assert.value(rootFifths/bassNotes > 0.8,"Bass lost its root/fifth foundation");
    assert.value(leadBars>0 and: {leadBars/deckBars < 0.10} and: {bassBars/deckBars>0.75},
        "Arrangement lost its bass/drums focus or rare melodic accents");
    assert.value(leadLengths.size>=3 and: {leadLengths.maxItem>2} and: {leadLengths.includes(2)},
        "Melodic interventions lost their phrase-length variety");
    assert.value(swingHits>100 and: {ghostHits>100} and: {breaths>100} and: {lowGaps>0} and: {returns>0}
        and: {bassTones.size>12} and: {bassDrives.size>12},"Missing groove, articulation, subtraction or coordinated returns");
    {
        var held=~makeDJEngine.value(2600,128,(hold:true,autoStutter:false)),cells=List.new;
        var tones=List.new,drives=List.new,percCounts=Set.new;
        16.do { |i|
            var frame=held[\nextBar].value,bass=frame.events.select { |e| e.role==\djBass };
            if(i<4) {
                cells.add(bass.collect(_.step)); tones.add(bass.first.tone); drives.add(bass.first.drive);
            };
            percCounts.add(frame.events.count { |e| e.role==\djPerc });
        };
        assert.value(cells[0]==cells[1] and: {cells[1]==cells[2]},"Bass motif changed before its answer");
        assert.value(cells[3]!=cells[0] and: {cells[3].count { |step| cells[0].includes(step) } >= 3},
            "Bass answer lost the memorable cell");
        assert.value(tones.last>(tones.first+0.05) and: {drives.last>(drives.first+0.05)},
            "Bass filter and saturation failed to evolve through the phrase");
        assert.value(percCounts.includes(0) and: {percCounts.any { |n| n>0 }},"Percussion never enters or leaves");
    }.value;
    assert.value(autoBursts>20 and: {autoBars<(8192*0.05)} and: {autoLengths==Set[0.5]}
        and: {autoRates==Set[16]},"Automatic stutter is missing, constant, or has the wrong duration/rate");
    assert.value(palettes.size == ~djLibrary.palettes.size,"Palette rotation did not cover the expanded instruments");
    assert.value(mixed > 0 and: { builds > 0 } and: { hookBars > 0 } and: { drumOnlyBars > 0 }
        and: { peak < 160 },"Missing arrangement, drum spotlight, or excessive voices");
    {
        var held=~makeDJEngine.value(17,128);
        held.controls.hold=true;
        80.do { held[\nextBar].value; assert.value(held.state.currentSerial == 0,"Hold changed records") };
        assert.value(held.state.decks[0].mutations==0,"Hold allowed pattern mutations");
        held[\requestMutation].value; held[\nextBar].value;
        assert.value(held.state.decks[0].mutations==0,"Explicit mutation escaped Hold");
        held[\requestNext].value;
        8.do { held[\nextBar].value };
        assert.value(held.state.mixing,"NEXT did not override Hold");
    }.value;
    {
        var manual=~makeDJEngine.value(19,128),normal=~makeDJEngine.value(19,128),frame;
        manual[\requestHook].value;
        4.do {
            var base=normal[\nextBar].value,bass,baseBass;
            frame=manual[\nextBar].value;
            bass=frame.events.select { |e| e.role==\djBass }.collect(_.amp);
            baseBass=base.events.select { |e| e.role==\djBass }.collect(_.amp);
            assert.value(frame.decks[0].hook and: {bass.maxItem > (baseBass.maxItem*1.05)},
                "Bass hook button did not strengthen the bass for four bars");
            assert.value(frame.events.select { |e| [\djHook,\djStab,\djArp].includes(e.role) }.isEmpty,
                "Bass hook button introduced a lead passage");
        };
        assert.value(manual[\nextBar].value.decks[0].hook.not,"Bass hook button failed to release");
    }.value;
    {
        var low=~makeDJEngine.value(2600,128,(density:0.1,chaos:0)),high=~makeDJEngine.value(2600,128,(density:0.9,chaos:0.8));
        var lowCount=0,highCount=0;
        32.do { lowCount=lowCount+low[\nextBar].value.events.size; highCount=highCount+high[\nextBar].value.events.size };
        assert.value(highCount > (lowCount*1.15),"Density did not affect musical activity");
    }.value;
    [[0,0,0,0],[1,1,1,1],[1,0.2,0.9,0.1],[0.1,0.95,0.1,1]].do { |values|
        var extreme=~makeDJEngine.value(2600,128,
            (chaos:values[0],density:values[1],mutation:values[2],tension:values[3]));
        512.do {
            var frame=extreme[\nextBar].value;
            frame.events.do { |event|
                var plan=frame.decks[event.deck];
                var scale=if(plan.mode==\minor,[0,2,3,5,7,8,10],[0,2,4,5,7,9,11]);
                assert.value(event.beat >= 0 and: { event.beat < 4 } and: { event.amp > 0 }
                    and: { event.amp <= 0.65 } and: { event.duration > 0 },"Invalid extreme-control event");
                if(event.lane < 3) {
                    assert.value(scale.includes((event.midinote-plan.key)%12),"Extreme chaos escaped the key");
                };
            };
        };
    };
    {
        var manual=~makeDJEngine.value(2600,128),frame;
        manual[\requestFill].value; manual[\requestMutation].value; frame=manual[\nextBar].value;
        assert.value(frame.events.count { |event| [\djClap,\djSnare].includes(event.role)
            and: { event.beat >= 3.25 } } >= 3,"Fill request failed");
        assert.value(frame.decks[0].mutations==1,"Mutation request failed");
    }.value;
    {
        var manual=~makeDJEngine.value(2600,128,(autoStutter:false)),frame;
        manual[\requestFX].value(\stutter16,0.5); frame=manual[\nextBar].value;
        assert.value(frame.stutter.bars==0.5 and: {frame.automation[0].fx[0].stutter==0}
            and: {frame.automation[8].fx[0].stutter>0} and: {frame.automation.last.fx[0].stutter==0},
            "Manual half-bar stutter duration failed");
        assert.value(~djAutomation.value(frame.automation[8],[800,801])[0].last==1,
            "Mid-bar phase reset did not reach the server adapter");
        assert.value(manual[\nextBar].value.stutter.isNil,"Half-bar stutter continued into another bar");
        manual[\requestFX].value(\stutter8,4);
        4.do { |i|
            frame=manual[\nextBar].value;
            assert.value(frame.stutter.notNil and: {frame.stutter.remaining==(4-i)}
                and: {frame.automation[0].fx[0].stutter>0},"Manual four-bar stutter ended early");
            assert.value(frame.automation[0].fx[0].stutterReset==(i==0),"Long stutter retriggered its phase");
        };
        frame=manual[\nextBar].value;
        assert.value(frame.stutter.isNil and: {frame.automation[0].fx[0].stutter==0},"Long stutter failed to release");
    }.value;
    {
        var on=~makeDJEngine.value(2600,128),off=~makeDJEngine.value(2600,128,(autoStutter:false)),frame;
        var fields={ |f| f.events.collect { |e| [e.voice,e.beat,e.midinote,e.duration,e.amp] } };
        256.do {
            frame=off[\nextBar].value;
            assert.value(frame.stutter.isNil,"Auto stutter OFF still generated effects");
            assert.value(fields.value(on[\nextBar].value)==fields.value(frame),"FX scheduling changed the composition");
        };
    }.value;
    {
        var engine=~makeDJEngine.value(2600,128),frame,found=false;
        96.do {
            if(found.not) {
                frame=engine[\nextBar].value;
                found=frame.stutter.notNil;
            };
        };
        assert.value(found,"Default settings never perform automatic stutter");
        engine.controls.autoStutter=false;
        assert.value(engine[\nextBar].value.stutter.isNil,"Auto OFF failed to release a running automatic phrase");
    }.value;
    {
        var hot=~makeDJEngine.value(2600,128),frame,deck;
        hot[\requestFX].value(\echo); frame=hot[\nextBar].value;
        deck=hot.state.currentSerial%2;
        assert.value(hot.state.lastFX==\echo and: { frame.automation[0].hotFX==\echo },"Hot FX request was not recorded");
        assert.value(frame.automation.any { |point| point.fx[deck].echo > 0.7 },"Echo throw did not reach the active deck");
        [\filter,\wash,\stutter4,\stutter8,\stutter16,\stutter].do { |kind|
            hot[\requestFX].value(kind); frame=hot[\nextBar].value;
            assert.value(frame.automation[0].hotFX==kind,"Hot FX action did not advance: " ++ kind);
            if(kind==\wash) {
                assert.value(frame.automation[0].fx[deck].reverb < frame.automation[16].fx[deck].reverb,
                    "Wash did not bloom across the bar");
            };
            if([\stutter4,\stutter8,\stutter16,\stutter].includes(kind)) {
                var rate=switch(kind,\stutter4,{1},\stutter8,{2},{4});
                assert.value(frame.automation.every { |point| point.fx[deck].stutterRate==rate },
                    "Stutter division did not reach automation");
                frame=hot[\nextBar].value;
                assert.value(frame.automation.every { |point| point.fx[deck].stutter==0 },
                    "Stutter did not end after one bar");
            };
        };
    }.value;
    ("PASS: 8192 seeded bars; " ++ records.size ++ " records; bass in " ++ bassBars ++ "/" ++ deckBars ++
        " deck-bars; brief lead phrases in " ++ leadBars ++ " (" ++ leadNotes ++ " notes; sizes " ++ leadLengths.asArray.sort ++
        "); four stable rotating palettes; " ++ autoBursts ++
        " automatic half-bar sixteenth phrases / " ++ autoBars ++ " bar equivalents; cooldown and manual half/multi-bar release; unchanged composition with Auto OFF; catalog, harmony, handovers, controls and estimated peak voices " ++ peak).postln;
    ("GROOVE: " ++ swingHits ++ " swung hits / " ++ ghostHits ++ " ghost hits / " ++ breaths ++
        " one-beat pullbacks / " ++ lowGaps ++ " pre-drop pickups / " ++ drumOnlyBars ++ " drum-only bars / " ++ returns ++
        " coordinated drops; bass tone/drive levels " ++
        bassTones.size ++ "/" ++ bassDrives.size ++ "; motif memory and percussion entrances passed").postln;
    0.exit;
} { |error| error.reportError; 1.exit };
)
