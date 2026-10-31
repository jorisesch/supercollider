// Pure checks; no server, playback, or files containing audio.
(
var root=thisProcess.nowExecutingPath.dirname, assert={ |condition,message| if(condition.not) { Error(message).throw } };
try {
    var a,b,styles=Set.new, keys=Set.new, progressions=Set.new, durations=Set.new, hooks=Set.new;
    var forms=Set.new,lengths=Set.new,energies=Set.new,chaosLevels=Set.new;
    var bassNotes=0,rootFifths=0;
    var records=Set.new, previousBpm, mixed=0, builds=0, hookBars=0, active=[], peak=0, seconds=0;
    ["live.scd","controls.scd","launch.scd","../c-edm.scd"].do { |file|
        assert.value(File.readAllString(root +/+ file).compile.notNil,"Parse failed: " ++ file);
    };
    (root +/+ "engine.scd").load;
    (root +/+ "instruments.scd").load;
    ~djDefs.do { |def| assert.value(def.asBytes.size > 0,"Invalid instrument") };
    a=~makeDJEngine.value(2600,128); b=~makeDJEngine.value(2600,128);
    8192.do {
        var frame=a[\nextBar].value, other=b[\nextBar].value, previous=0, barBpm=frame.automation[0].bpm;
        assert.value(frame.events.asCompileString == other.events.asCompileString,"Seeded notes changed");
        assert.value(frame.automation.asCompileString == other.automation.asCompileString,"Seeded mixing changed");
        frame.decks.do { |plan|
            if(plan.notNil) {
                forms.add(plan.formID); lengths.add(plan.length); energies.add(plan.intensity.round(0.05));
                chaosLevels.add(plan.effective.chaos.round(0.02));
                records.add(plan.serial); styles.add(plan.variation.id); keys.add(plan.key);
                progressions.add(plan.mode.asString ++ plan.progressionID); durations.add(plan.durationID); hooks.add(plan.hookID);
                plan.schedule.do { |chord,i|
                    assert.value(chord.start <= i and: { chord.start + chord.bars > i },"Chord duration coverage invalid");
                };
                if(plan.section == \buildup) { builds=builds+1 };
                if(plan.hook) { hookBars=hookBars+1 };
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
            assert.value((event.beat >= previous) and: { event.beat < 4 },"Invalid note timing"); previous=event.beat;
            assert.value(event.track >= 0 and: { event.track < 8 } and: { (event.track div: 4) == event.deck },"Invalid deck/track");
            assert.value(event.amp > 0 and: { event.amp <= 0.65 } and: { event.duration > 0 },"Invalid note levels/duration");
            if(event.lane < 3) {
                scale=if(plan.mode == \minor,[0,2,3,5,7,8,10],[0,2,4,5,7,9,11]);
                assert.value(scale.includes((event.midinote - plan.key) % 12),"A note escaped its deck's key");
            };
            if(event.lane==0) {
                scale=if(plan.mode==\minor,[0,2,3,5,7,8,10],[0,2,4,5,7,9,11]);
                degree=plan.schedule[plan.localBar].degree;
                allowed=[0,4].collect { |offset| (plan.key+scale.wrapAt(degree+offset))%12 };
                bassNotes=bassNotes+1;
                if(allowed.includes(event.midinote%12)) { rootFifths=rootFifths+1 };
            };
            if(event.voice==\djKick) { assert.value((event.beat-event.beat.round).abs < 0.000001,"Kick anchor left the grid") };
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
        };
        seconds=seconds+(240/barBpm);
    };
    assert.value(styles.size == 32 and: { keys.size == 12 } and: { progressions.size == 32 }
        and: { durations.size == 20 } and: { hooks.size == 16 },"Catalog rotation did not cover the library");
    assert.value(forms.size==6 and: { lengths.size >= 5 } and: { energies.size >= 10 }
        and: { chaosLevels.size >= 8 },"Record length/energy/chaos did not vary");
    assert.value(rootFifths/bassNotes > 0.8,"Bass lost its root/fifth foundation");
    assert.value(mixed > 0 and: { builds > 0 } and: { hookBars > 0 } and: { peak < 160 },"Missing arrangement or excessive voices");
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
        var manual=~makeDJEngine.value(19,128), frame;
        manual[\requestHook].value; frame=manual[\nextBar].value;
        assert.value(frame.decks[0].hook,"Hook request failed");
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
        assert.value(frame.events.count { |event| [\djClap,\djSnare].includes(event.voice)
            and: { event.beat >= 3.25 } } >= 3,"Fill request failed");
        assert.value(frame.decks[0].mutations==1,"Mutation request failed");
    }.value;
    ("PASS: 8192 seeded bars; " ++ records.size ++ " records; all 32 variations, 32 progressions, 20 duration patterns, 16 hooks and 12 keys; six song forms with varying length/energy/chaos; baseline Markov bass; density response; eight lanes; tempo continuity; pitched-key isolation; Hold/NEXT/hooks; estimated peak voices " ++ peak).postln;
    0.exit;
} { |error| error.reportError; 1.exit };
)
