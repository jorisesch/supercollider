// Same notes, level and brightness: original Digital Drive lead, then rounded lead.
// Standalone NRT comparison; no hardware playback. Optional output WAV argument.
(
var root=thisProcess.nowExecutingPath.dirname,repo=root.dirname.dirname.dirname;
var output=thisProcess.argv.at(0) ? (repo +/+ "audio/digital-drive-lead-ab-v6d.wav");
var score=List.new,old,new,before,changed,node=1000,osc=Platform.defaultTempDir +/+ "dj-lead-compare.osc";
var cases=[[60,0.35],[67,0.55],[74,0.75],[74,1]];
try {
    (root +/+ "engine.scd").load;
    (root +/+ "revisions/v6c/instruments.scd").load;
    old=~djDefs.detect { |def| def.name==\djFMLead };
    before=Dictionary.new;
    ~djDefs.do { |def| before[def.name]=def.asBytes };
    (root +/+ "instruments.scd").load;
    new=~djDefs.detect { |def| def.name==\djFMLead };
    changed=~djDefs.select { |def| def.asBytes!=before[def.name] }.collect(_.name);
    if(changed!=[\djFMLead]) {Error("Unexpected instrument changes: " ++ changed).throw};
    "PASS: only the Digital Drive lead SynthDef changed from the favourite snapshot".postln;
    TempoClock.default.tempo=1;
    [old,new].do { |def,version|
        score.add([version*4,[\d_recv,def.asBytes]]);
        cases.do { |pair,index|
            var event=(voice:\djFMLead,deck:0,lane:1,midinote:pair[0],amp:0.09,
                duration:1,pan:0,color:2,tone:pair[1],seed:2600);
            score.add([0.1+(version*4)+index,~djMessage.value(event,node,1,0,120)]);
            node=node+1;
        };
    };
    score.add([8.2,[\c_set,0,0]]);
    Score(score.asArray).recordNRT(oscFilePath:osc,outputFilePath:output,
        sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",
        options:ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false),duration:8.2,
        action:{ |code| File.delete(osc); code.exit });
} { |error| error.reportError; 1.exit };
)
