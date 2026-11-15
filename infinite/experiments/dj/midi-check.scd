// MIDI export: valid Standard MIDI Files, exact replay of a logged set, and sane mapping. No audio.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,message|if(ok.not){Error(message).throw}};
var parse,controls,script;
// Read a file back: returns (tracks:[(name:,notes:[[tick,key,vel,channel,end]],meta:[...])]).
parse={|bytes|
    var data=bytes.collect {|b|b&255},word={|at|(data[at]<<24)|(data[at+1]<<16)|(data[at+2]<<8)|data[at+3]};
    var at=14,tracks=List.new,count;
    assert.value(data.copyRange(0,3).collect(_.asAscii).join=="MThd","Missing MThd");
    assert.value(word.value(4)==6 and:{data[9]==1},"Expected a type 1 header");
    count=(data[10]<<8)|data[11];
    assert.value(((data[12]<<8)|data[13])==~djMidiPPQ,"Wrong resolution");
    count.do {
        var length,end,tick=0,open=Dictionary.new,notes=List.new,meta=List.new,name,ended=false;
        assert.value(data.copyRange(at,at+3).collect(_.asAscii).join=="MTrk","Missing MTrk");
        length=word.value(at+4); at=at+8; end=at+length;
        while {at<end} {
            var delta=0,status,byte;
            while {byte=data[at]; at=at+1; delta=(delta<<7)|(byte&127); byte>=128};
            tick=tick+delta; status=data[at];
            assert.value(ended.not,"Events after end of track");
            case
            {status==255}{
                var type=data[at+1],size=data[at+2];
                if(type==3){name=data.copyRange(at+3,at+2+size).collect(_.asAscii).join};
                if(type==47){ended=true};
                meta.add([type,data.copyRange(at+3,at+2+size)]); at=at+3+size;
            }
            {(status&240)==144}{
                var key=data[at+1],vel=data[at+2];
                assert.value(vel.inclusivelyBetween(1,127),"Bad velocity");
                assert.value(open[key].isNil,"Overlapping note " ++ key);
                open[key]=[tick,key,vel,status&15]; at=at+3;
            }
            {(status&240)==128}{
                var key=data[at+1];
                assert.value(open[key].notNil,"Note off without note on");
                assert.value(tick>open[key][0],"Zero-length note");
                notes.add(open[key]++[tick]); open[key]=nil; at=at+3;
            }
            {(status&240)==192}{at=at+2}
            {true}{Error("Unexpected MIDI status " ++ status).throw};
        };
        assert.value(at==end and:{ended},"Track length or end marker is wrong");
        assert.value(open.isEmpty,"Notes left hanging");
        tracks.add((name:name,notes:notes,meta:meta));
    };
    assert.value(at==data.size,"Trailing bytes after the last track");
    tracks;
};
// A scripted listener: Energy moves every 24 bars and Next is pressed once.
script={|index,engine|
    var value=[0.38,0.7,0.15,0.95,0.5].wrapAt(index div:24);
    engine.controls.chaos=0.08+(value*0.34); engine.controls.density=0.28+(value*0.54);
    engine.controls.mutation=0.12+(value*0.36); engine.controls.tension=0.02+(value*0.36);
    if(index==150){engine[\requestNext].value};
};
try {
    (root+/+"engine.scd").load; (root+/+"midi-export.scd").load;
    [[\edme,11,0],[\edme,4242,2],[\pop,2600,1],[\pop,90001,0],[\rock,77,1],[\dubstep,5,0]].do {|item|
        var channel=item[0],seed=item[1],serial=item[2],bpm=if(channel==\edme){134}{~djDefaultBpm.value(channel)};
        var live=~djMidiCollect.value(~makeDJEngine.value(seed,bpm,(channel:channel)),serial,script);
        var replay=~djMidiCollect.value(~makeDJEngine.value(seed,bpm,(channel:channel)),serial,script);
        var result=~djMidiBytes.value(live),tracks=parse.value(result.bytes),plan=live.frames.first.plan;
        var drums=tracks.detect {|track|track.notes.notEmpty and:{track.notes.first[3]==9}};
        var tempo=tracks[0].meta.detect {|m|m[0]==81}[1];
        assert.value(live.complete,"Song did not finish");
        assert.value(result.bytes==~djMidiBytes.value(replay).bytes,"Replayed set exported a different song: " ++ item);
        assert.value(tracks.size==result.tracks,"Track count mismatch");
        assert.value(result.bars.inclusivelyBetween(16,400),"Implausible song length " ++ result.bars);
        assert.value(((60000000/((tempo[0]<<16)|(tempo[1]<<8)|tempo[2]))-result.bpm).abs<0.01,"Tempo meta is wrong");
        assert.value(drums.notNil and:{drums.notes.every {|n|n[1].inclusivelyBetween(35,81)}},"Drums left the GM map");
        assert.value(tracks.drop(1).every {|track|track.notes.notEmpty},"Empty part track");
        // Pitched parts hold only the played notes: bass and lead are one note at a time
        // (no octave or harmonic doublings), chords stay within two octaves.
        tracks.drop(1).do {|track|
            if(track.notes.first[3]!=9){
                var onsets=Dictionary.new;
                assert.value(track.notes.every {|n|n[1].inclusivelyBetween(24,108)},"Pitch out of range in " ++ track.name);
                track.notes.do {|n|onsets[n[0]]=(onsets[n[0]] ?? {List.new}).add(n[1])};
                if(track.name.beginsWith("Bass") or:{track.name.beginsWith("Lead")}){
                    assert.value(onsets.every {|keys|keys.size==1},"Stacked notes in " ++ track.name);
                }{
                    assert.value(onsets.every {|keys|(keys.maxItem-keys.minItem)<=24},"Chord too wide in " ++ track.name);
                };
            };
        };
        assert.value(~djMidiHex.value(result.bytes).copyRange(0,7)=="4d546864","Hex encoding is wrong");
        assert.value(result.fileName.endsWith(".mid") and:{result.fileName.every {|c|c.isAlphaNum or:{"-.".includes(c)}}},"Unsafe file name");
        ("PASS " ++ item ++ " " ++ result.name ++ " " ++ result.bars ++ " bars " ++ result.notes ++ " notes").postln;
    };
    // Key signatures: [key, scale] -> [sharps, minor].
    [[6,[0,1,3,5,7,8,10],[2,1]],[0,[0,2,3,5,7,9,10],[-2,1]],[7,[0,2,4,5,7,9,11],[1,0]],
        [9,[0,2,3,5,7,8,10],[0,1]],[1,[0,2,4,5,7,9,11],[-5,0]],[4,[0,2,3,5,7,8,11],[1,1]]].do {|item|
        var got=~djMidiKeySignature.value((key:item[0],scale:item[1]));
        assert.value(got==item[2],"Key signature for " ++ item ++ " was " ++ got);
    };
    assert.value([[\djKick,\djAnalogKick,36],[\djSnare,\djDubRim,37],[\djClap,\djAnalogClap,39],[\djHat,\rockHat,42],
        [\rockCrash,\rockCrash,49],[\eShaker,\edmEShaker,70]].every {|item|
        ~djMidiDrumNote.value((role:item[0],voice:item[1],duration:0.1))==item[2]
    },"Drum map changed");
    "PASS midi-check".postln;
    0.exit;
} {|error| error.reportError; 1.exit};
)
