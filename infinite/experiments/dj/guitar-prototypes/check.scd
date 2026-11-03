// Gesture bounds, varied timing, reproducibility and accepted-source isolation.
(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname;
var assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var oldMotion,oldDefs,count=0,kinds=Set.new,delays=Set.new,undershot=false,overshot=false;
    (dj+/+"instruments.scd").load;oldMotion=~djStringMotion;
    oldDefs=~djDefs.collect {|d|[d.name,d.asBytes]};
    (root+/+"gestures.scd").load;(root+/+"instruments.scd").load;
    assert.value(~djStringMotion==oldMotion,"Study replaced the accepted motion function");
    oldDefs.do {|old|assert.value(~djDefs.detect {|d|d.name==old[0]}.asBytes==old[1],"Study changed a live/saved SynthDef")};
    [\restrained,\loose,\urgent].do {|profile|64.do {|seed|
        var plain=0,straight=0;
        ~gpPhrase.do {|note,i|
            var hold=note[2]*60/96,p=~gpGesture.value(profile,note,i,hold,seed+731);
            assert.value(p==~gpGesture.value(profile,note,i,hold,seed+731),"Gesture is not reproducible");
            assert.value((p[\times].sum-hold).abs<1e-8,"Bend times exceed the note");
            assert.value(p[\levels].every {|n|n.inclusivelyBetween(0,2.5)},"Unbounded finger bend");
            assert.value(p[\depth].inclusivelyBetween(0,0.55),"Unbounded vibrato");
            assert.value(p[\delay].inclusivelyBetween(0,hold),"Vibrato starts after note end");
            assert.value(p[\rateStart].inclusivelyBetween(3.5,7) and:{p[\rateEnd].inclusivelyBetween(3.5,7.5)},"Unbounded vibrato rate");
            if(p[\levels].maxItem==0){plain=plain+1};if(p[\depth]==0){straight=straight+1};
            if(p[\offset]<0){
                assert.value((note[1]+p[\offset]-if(note[1]<67){59}{64})>=0,"Bend starts below its open string");
                if(p[\levels].last<2){undershot=true};if(p[\levels].maxItem>2.08){overshot=true};
            };
            if(p[\depth]>0){delays.add(p[\delay].round(0.01))};kinds.add(p[\kind]);count=count+1;
            if(p[\kind]==\anchor){assert.value(p[\offset]==0 and:{p[\levels].maxItem==0},"Phrase ending lost its root anchor")};
        };
        assert.value(plain>=8 and:{straight>=5},"Every note is being ornamented");
    }};
    assert.value(kinds.includes(\preRelease) and:{kinds.includes(\release)} and:{kinds.includes(\curl)} and:{kinds.includes(\double)},"Missing bend direction/type");
    assert.value(delays.size>20 and:{undershot} and:{overshot},"Missing timing/intonation variety");
    ~djDefs.do {|d|assert.value(d.asBytes.size<65000,"Oversized OSC definition: "++d.name)};
    ("PASS: "++count++" prototype notes; "++delays.size++" onset delays; straight notes, up/down/partial/staged bends, imperfect intonation, stable roots and unchanged live definitions").postln;
    0.exit;
} {|error|error.reportError;1.exit};
)
