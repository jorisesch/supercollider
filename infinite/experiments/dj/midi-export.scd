// Standard MIDI File export of one generated Infinite DJ song.
// Pure language code: the desktop script and the web player share it.
//
// ~djMidiCollect drives an engine until the song with the given serial has finished
// and keeps only that song's deck. ~djMidiBytes turns the capture into a type 1 file:
// a tempo track, one track per pitched voice and one General MIDI drum track.
(
~djMidiPPQ=480;

// General MIDI percussion keys for the engine's drum roles and voices.
~djMidiDrumNote={|event|
    var role=event[\role] ? \none,name=event.voice.asString.toLower;
    case
    {role==\djKick or:{name.contains("kick")}}{36}
    {name.contains("rim")}{37}
    {role==\djClap or:{name.contains("clap")}}{39}
    {name.contains("snare")}{38}
    {name.contains("crash")}{49}
    {role==\djImpact or:{name.contains("impact")}}{57}
    {name.contains("tom")}{
        var note=event.midinote ? 50;
        case {note<=47}{41} {note<=52}{45} {note<=57}{47} {note<=62}{48} {true}{50}
    }
    {name.contains("shaker")}{70}
    {role==\djHat or:{name.contains("hat")}}{if((event.duration ? 0)>0.3){46}{42}}
    {true}{75};
};

// A General MIDI program so the file sounds roughly right before any sound is chosen.
~djMidiProgram={|lane,voice,channel|
    var name=voice.asString.toLower;
    case
    {[\rockGuitar,\rockExpressiveGuitar].includes(voice) or:{name.contains("humbucker") or:{name.contains("singlecoil") or:{name.contains("guitar")}}}}{if(lane==2){29}{30}}
    {lane==0}{if(channel==\rock){33}{38}}
    {name.contains("keys")}{4}
    {name.contains("pluck")}{46}
    {name.contains("brass")}{62}
    {name.contains("acid")}{81}
    {name.contains("echo")}{17}
    {name.contains("stab") or:{name.contains("chord")}}{62}
    {name.contains("pad")}{89}
    {lane==1}{80}
    {true}{89};
};

// "neonSoftKeys" -> "Neon Soft Keys".
~djMidiVoiceName={|voice|
    var text=voice.asString,out=String.new;
    text.do {|char,i|
        if(i>0 and:{char.isUpper}){out=out++" "};
        out=out++if(i==0){char.toUpper}{char};
    };
    out;
};

// Run the engine until the song with `serial` has played and mixed out.
// before.value(barIndex, engine) runs ahead of each bar (replayed controls on the web);
// yield.value(barIndex) lets a Routine hand time back to live playback.
~djMidiCollect={|engine,serial,before,maxBars=4000,yield|
    var frames=List.new,seen=false,done=false,count=0;
    while {done.not and:{count<maxBars}} {
        var frame,plan;
        before !? {before.value(count,engine)};
        frame=engine[\nextBar].value;
        plan=frame.decks.detect {|deck|deck.notNil and:{deck.serial==serial}};
        count=count+1;
        if(plan.notNil){
            seen=true;
            frames.add((
                plan:plan,drumBreak:plan.drumBreak==true,
                events:frame.events.select {|event|event.deck==plan.deck},
                gains:frame.automation.collect {|point|point.gains[plan.deck].copy},
                bpm:frame.automation[0].bpm,
                alone:frame.decks.count(_.notNil)==1
            ));
        }{
            if(seen){done=true};
        };
        yield !? {yield.value(count)};
    };
    if(seen.not){Error("Song " ++ serial ++ " never played").throw};
    (frames:frames,complete:done,channel:engine.channel,seed:engine.seed,serial:serial);
};

// Music, bass and drum gains in the deck mixer, by lane.
~djMidiGainIndex=[1,0,0,2];

// Notes as (track key, lane, voice, start tick, end tick, key, velocity).
~djMidiNotes={|capture|
    var notes=List.new,peaks=Dictionary.new,first;
    capture.frames.do {|frame,bar|
        frame.events.do {|event|
            var step=(event.beat*4).round.asInteger.clip(0,16);
            var gain=frame.gains[step][~djMidiGainIndex[event.lane]];
            // Noise risers are a mix effect, not a playable part.
            if(gain>0.02 and:{event.voice!=\djRise} and:{(frame.drumBreak and:{event.lane<3}).not}){
                var trackKey=if(event.lane==3){\drums}{(event.lane.asString++"/"++event.voice).asSymbol};
                var start=((bar*4)+event.beat)*~djMidiPPQ;
                var key=if(event.lane==3){~djMidiDrumNote.value(event)}{event.midinote.round.asInteger.clip(0,127)};
                var peakKey=[event.lane,event.voice];
                notes.add((track:trackKey,lane:event.lane,voice:event.voice,start:start.round.asInteger,
                    end:(start+(event.duration.max(0.03)*~djMidiPPQ)).round.asInteger,key:key,amp:event.amp,peak:peakKey));
                peaks[peakKey]=(peaks[peakKey] ? 0).max(event.amp);
                first=(first ? inf).min(bar);
            };
        };
    };
    if(notes.isEmpty){Error("The song has no audible notes").throw};
    // Start on the first audible bar; scale loudness per voice so ghost notes stay softer.
    notes.do {|note|
        var shift=(first*4*~djMidiPPQ).asInteger;
        note.start=note.start-shift; note.end=note.end-shift;
        note.velocity=(36+(91*(note.amp/peaks[note.peak].max(1e-6)).sqrt)).round.asInteger.clip(1,127);
    };
    (notes:notes,firstBar:first);
};

// Key signature from the scale's parent major key; minor when the third is minor.
// plan.scale holds steps above the tonic, plan.key the tonic pitch class.
~djMidiKeySignature={|plan|
    var tonic=(plan.key ? 0)%12,classes=(plan[\baseScale] ? plan.scale ? [0,2,4,5,7,9,11]).collect {|step|step%12}.asSet;
    var minor=classes.includes(3) and:{classes.includes(4).not};
    var parent=(0..11).detect {|root|[0,2,4,5,7,9,11].collect {|step|(root+step-tonic)%12}.asSet==classes};
    var sharps;
    parent=parent ?? {if(minor){(tonic+3)%12}{tonic}};
    sharps=(parent*7)%12; if(sharps>6){sharps=sharps-12};
    [sharps,if(minor){1}{0}];
};

~djMidiVarLen={|value|
    var bytes=[value&127];
    value=value>>7;
    while {value>0} {bytes=[(value&127)|128]++bytes; value=value>>7};
    bytes;
};
~djMidiText={|text|text.asString.ascii.select {|code|code>=32 and:{code<=126}}};
~djMidiChunk={|tag,data|tag.ascii++[(data.size>>24)&255,(data.size>>16)&255,(data.size>>8)&255,data.size&255]++data};
// items: [tick, order, bytes]; note-offs sort before note-ons on the same tick.
~djMidiTrack={|items|
    var data=List.new,last=0;
    items.sort {|a,b|if(a[0]==b[0]){a[1]<=b[1]}{a[0]<b[0]}}.do {|item|
        data.addAll(~djMidiVarLen.value(item[0]-last)); data.addAll(item[2]); last=item[0];
    };
    data.addAll(~djMidiVarLen.value(0)++[255,47,0]);
    ~djMidiChunk.value("MTrk",data.asArray);
};

// The whole file. Returns (bytes:Int8Array, name:..., bpm:..., bars:..., tracks:...).
~djMidiBytes={|capture|
    var plan=capture.frames.first.plan,palette=plan.palette ? (),built=~djMidiNotes.value(capture);
    var notes=built.notes,channelOf=Dictionary.new,nextChannel=0,tracks=List.new,trackOrder,bpm,tempo,sig,file,name,bars;
    var steady=capture.frames.select(_.alone).collect(_.bpm);
    bpm=if(steady.isEmpty){plan.targetBpm ? capture.frames.first.bpm}{steady[steady.size div:2]};
    tempo=(60000000/bpm).round.asInteger;
    sig=~djMidiKeySignature.value(plan);
    bars=(notes.collect(_.end).maxItem/(4*~djMidiPPQ)).ceil.asInteger;
    name=[if(plan.edmAnthem==true){"Anthem"}{palette.name ? "Infinite DJ"},plan.keyName].join(" - ");
    tracks.add(~djMidiTrack.value([
        [0,0,[255,3]++~djMidiVarLen.value(~djMidiText.value(name).size)++~djMidiText.value(name)],
        [0,0,[255,81,3,(tempo>>16)&255,(tempo>>8)&255,tempo&255]],
        [0,0,[255,88,4,4,2,24,8]],
        [0,0,[255,89,2,sig[0]&255,sig[1]]]
    ]));
    // Pitched voices in lane order (bass, lead, chords), drums last on channel 10.
    trackOrder=notes.collect(_.track).asSet.asArray.sort {|a,b|
        var la=notes.detect {|n|n.track==a}.lane,lb=notes.detect {|n|n.track==b}.lane;
        if(la==lb){a.asString<b.asString}{la<lb}
    };
    trackOrder.do {|trackKey|
        var mine=notes.select {|note|note.track==trackKey},sample=mine.first,lane=sample.lane,items=List.new;
        var channel=if(lane==3){9}{var c=nextChannel; nextChannel=nextChannel+1; if(nextChannel==9){nextChannel=10}; c.clip(0,15)};
        var label=if(lane==3){"Drums - " ++ (palette.kitName ? "Kit")}{
            ["Bass","Lead","Chords"][lane] ++ " - " ++ ~djMidiVoiceName.value(sample.voice)
        };
        var byKey=Dictionary.new;
        items.add([0,0,[255,3]++~djMidiVarLen.value(~djMidiText.value(label).size)++~djMidiText.value(label)]);
        if(lane<3){items.add([0,0,[192|channel,~djMidiProgram.value(lane,sample.voice,capture.channel)]])};
        // Same key on the same channel: drop exact repeats, end each note before the next.
        mine.do {|note|byKey[note.key]=(byKey[note.key] ?? {List.new}).add(note)};
        byKey.keysValuesDo {|key,list|
            var sorted=list.asArray.sort {|a,b|a.start<b.start},kept=List.new;
            sorted.do {|note|
                if(kept.notEmpty and:{kept.last.start==note.start}){
                    if(note.velocity>kept.last.velocity){kept.last.velocity=note.velocity};
                }{kept.add(note)};
            };
            kept.do {|note,i|
                var end=note.end;
                if(i+1<kept.size){end=end.min(kept[i+1].start)};
                end=end.max(note.start+1);
                items.add([note.start,2,[144|channel,key,note.velocity]]);
                items.add([end,1,[128|channel,key,64]]);
            };
        };
        tracks.add(~djMidiTrack.value(items));
    };
    file=~djMidiChunk.value("MThd",[0,1,(tracks.size>>8)&255,tracks.size&255,(~djMidiPPQ>>8)&255,~djMidiPPQ&255]);
    tracks.do {|track|file=file++track};
    (bytes:Int8Array.newFrom(file.collect {|byte|if(byte>127){byte-256}{byte}}),
        name:name,bpm:bpm,bars:bars,tracks:tracks.size,notes:notes.size,keyName:plan.keyName,
        fileName:~djMidiFileName.value(capture,plan,palette));
};

~djMidiFileName={|capture,plan,palette|
    var words=["infinite-dj",if(capture.channel==\edme){"edm"}{capture.channel},palette.name ? "song",plan.keyName,"seed"++capture.seed,"song"++(capture.serial+1)];
    words.collect {|word|
        word.asString.toLower.collect {|char|if(char.isAlphaNum){char}{$-}}
    }.join("-").replace("--","-").replace("--","-") ++ ".mid";
};

~djMidiWrite={|result,path|
    var file=File(path,"wb");
    if(file.isOpen.not){Error("Could not write " ++ path).throw};
    file.write(result.bytes); file.close; path;
};

~djMidiHex={|bytes|
    var digits="0123456789abcdef",out=String.newClear(bytes.size*2);
    bytes.do {|byte,i|
        byte=byte&255; out[i*2]=digits[byte>>4]; out[(i*2)+1]=digits[byte&15];
    };
    out;
};
)
