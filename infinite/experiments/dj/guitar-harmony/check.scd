(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var studies,aliases,oldDefs,oldMotion,chordCount=0,noteCount=0,movement;
    (dj+/+"instruments.scd").load;oldDefs=~djDefs.collect {|d|[d.name,d.asBytes]};oldMotion=~djStringMotion;
    (dj+/+"guitar-prototypes/instruments.scd").load;(dj+/+"guitar-prototypes/gestures.scd").load;
    (dj+/+"guitar-contact/contact.scd").load;(dj+/+"guitar-contact/performance.scd").load;
    (dj+/+"guitar-contact/instruments.scd").load;(root+/+"harmony.scd").load;(root+/+"performance.scd").load;
    aliases=(pedalE:\e,pedalA:\ae,pedalD:\de,pedalE7:\e7,highA:\a,highEgs:\egs,
        highFsmin7:\fsmin7,highE:\e,highD:\d,highE7shell:\e7shell);
    ~ghShapes.keysValuesDo {|name,voices|
        var key=aliases[name] ? name,spec=~ghSpecs[key],expected=~ghPCs.value(spec),notes=voices.collect {|p|p[1]};
        if(spec[\bass].notNil){expected.add(spec[\bass])};
        assert.value(~ghPlayable.value(voices),"Unplayable guitar shape: "++name);
        assert.value(notes.collect {|n|n%12}.asSet==expected,"Chord spelling lost: "++name);
        assert.value((notes.minItem%12)==(spec[\bass] ? spec[\root]),"Slash/root bass lost: "++name);chordCount=chordCount+1;
    };
    [\a,\fsmin,\d,\e].do {|key|(0..2).do {|inversion|
        var candidates=~ghTriads.value(key,#[2,3,4],inversion);
        assert.value(candidates.notEmpty,"Missing playable inversion");
        candidates.do {|voices|
            var spec=~ghSpecs[key],notes=voices.collect {|p|p[1]};
            assert.value((notes.minItem-spec[\root])%12==spec[\intervals][inversion],"Wrong inversion bass");
            assert.value(notes.collect {|n|n%12}.asSet==~ghPCs.value(spec),"Triad has a missing/doubled pitch class");
        };
    }};
    studies=~ghBuildStudies.value;
    movement={|path|var total=0;path.do {|voices,i|if(i>0){total=total+~ghMove.value(path[i-1],voices)}};total};
    assert.value(movement.value(~ghPaths[\led])<movement.value(~ghPaths[\root]),"Inversions did not reduce voice movement");
    assert.value(~ghLead.value(~ghPaths[\keys],false)==~ghPaths[\led],"Voicing path is not deterministic");
    assert.value(~ghLead.value([\a]).size==1,"Single-chord path is not supported");
    studies.keysValuesDo {|key,events|events.do {|e|
        var c=~ghChanges[e[\change]],pcs=~ghPCs.value(~ghSpecs[c[\key]]);
        if(~ghSpecs[c[\key]][\bass].notNil){pcs.add(~ghSpecs[c[\key]][\bass])};
        assert.value(pcs.includes(e[\note]%12),"Playing pattern introduced a wrong chord tone");
        assert.value(e[\hold].inclusivelyBetween(0.06,4),"Invalid note hold");noteCount=noteCount+1;
    }};
    {
        var descending=~ghChanges.select {|c|c[\study]==\slash and:{c[\section]==2}}.collect {|c|c[\bass]};
        assert.value(descending==[57,56,54,52,50,49,47,52],"Descending bass changed register or inversion");
    }.value;
    assert.value(~djStringMotion==oldMotion,"Harmony study changed accepted motion");
    oldDefs.do {|d|assert.value(~djDefs.detect {|x|x.name==d[0]}.asBytes==d[1],"Harmony study changed accepted instrument")};
    ("PASS: "++chordCount++" named guitar shapes; "++noteCount++" chord-tone events; actual inversion/slash basses, distinct sevenths/add9/ninths, minimum-motion voicings, rhythmic patterns and unchanged accepted synthesis").postln;
    ("Voice movement / root-only "++movement.value(~ghPaths[\root])++" / inversions "++movement.value(~ghPaths[\led])).postln;
    0.exit;
} {|error|error.reportError;1.exit};
)
