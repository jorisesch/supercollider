// Check the musical contract, not the sound quality. No server or audio playback.
(
var root=thisProcess.nowExecutingPath.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var names;
    (root+/+"instruments.scd").load;(root+/+"tracks.scd").load;
    ["live.scd","run.scd","render.scd"].do {|name|
        assert.value(File.readAllString(root+/+name).compile.notNil,"Parse failed: "++name);
    };
    names=~rockDefs.collect(_.name);~rockDefs.do {|def|assert.value(def.asBytes.notEmpty,"Invalid SynthDef")};
    ~rockSpecs.do {|spec|
        var events=~rockEvents.value(spec),plain=~rockEvents.value(spec,731,false),last=0,pitched;
        var strip={|e|var copy=e.copy;[\overdrive,\fuzz,\wah,\slap,\grit].do {|key|copy.removeAt(key)};copy};
        assert.value(spec.form.sum {|part|part[1]}==32,"Incomplete arrangement");
        assert.value(events.collect(strip)==plain.collect(strip),"Effects changed the backing notes or timing");
        assert.value(events.select {|e|e.voice==\rkGuitar}.any {|e|e.overdrive>0},"No selective overdrive");
        if(spec.style==\riff){assert.value(events.any {|e|e.fuzz>0} and:{events.any {|e|e.grit>0}},"No selective fuzz/bass grit")};
        if(spec.style==\dorian){assert.value(events.any {|e|e.wah>0},"No selective wah")};
        if(spec.style==\mixo){assert.value(events.any {|e|e.slap>0},"No selective slapback")};
        assert.value(events.select {|e|e.lane==2}.every {|e|[e.overdrive,e.fuzz,e.wah,e.slap,e.grit].sum==0},"Guitar effects leaked into drums");
        assert.value(events.select {|e|e.beat<16}.every {|e|[e.overdrive,e.fuzz,e.wah,e.slap,e.grit].sum==0},"Intro effects should be off");
        assert.value(events==~rockEvents.value(spec),"Rock study is not reproducible");
        assert.value(spec.scale.size==if(spec.style==\riff){5}{7},"Wrong scale size");
        events.do {|event|
            assert.value(event.beat>=last and:{event.beat<128.15},"Invalid event timing");last=event.beat;
            assert.value(event.duration>0 and:{event.duration<=2},"Invalid note length");
            assert.value(names.includes(event.voice),"Unknown voice");
            assert.value(event.amp>0 and:{event.amp<0.6},"Invalid gain");
        };
        pitched=events.select {|event|event.lane<2};
        assert.value(pitched.every {|event|spec.scale.includes((event.midinote-spec.tonic)%12)},
            "Backing notes leave the advertised scale: "++spec.title);
        assert.value(pitched.every {|event|[\rkGuitar,\rkBass].includes(event.voice)},"Backing contains a lead solo");
        assert.value(pitched.collect {|event|(event.midinote-spec.tonic)%12}.asSet==spec.scale.asSet,
            "The arrangement never demonstrates part of its advertised scale");
        32.do {|bar|
            var own=events.select {|event|(event.beat>=(bar*4)) and:{event.beat<((bar+1)*4)}};
            assert.value(own.any {|event|event.voice==\rkBass},"Missing bass bar");
            assert.value(own.any {|event|event.voice==\rkSnare},"Missing rock backbeat");
        };
        if(spec.style==\dorian){assert.value(pitched.any {|e|(e.midinote-spec.tonic)%12==9},"Dorian sixth is absent")};
        if(spec.style==\mixo){assert.value(pitched.any {|e|(e.midinote-spec.tonic)%12==10},"Mixolydian flat seventh is absent")};
        ("PASS: "++spec.title++" / "++spec.scaleName++" / "++events.size++" notes / 32 bars + tonic ending").postln;
    };
    0.exit;
} {|error|error.reportError;1.exit};
)
