// Offline renders: all three studies, or one ID (ironwood, greenroom, openroad).
(
var root=thisProcess.nowExecutingPath.dirname,repo=root.dirname.dirname.dirname;
var effects=thisProcess.argv.includesEqual("nofx").not;
var requested=thisProcess.argv.reject {|argu|argu=="nofx"}.at(0),specs,pending,failed=false;
try {
    (root+/+"instruments.scd").load;(root+/+"tracks.scd").load;
    specs=if(requested.isNil){~rockSpecs}{~rockSpecs.select {|spec|spec.id.asString==requested}};
    if(specs.isEmpty){Error("Choose ironwood, greenroom or openroad").throw};
    pending=specs.size;
    TempoClock.default.tempo=1;
    specs.do { |spec|
        var score=List.new,node=1000,events=~rockEvents.value(spec,731,effects),end,duration,osc;
        var file=spec.file++if(effects){""}{"-base"};
        score.add([0]++~rockDefs.collect { |def|[\d_recv,def.asBytes] });
        score.add([0.01,[\g_new,100,0,1],[\s_new,\rkMix,999,1,1,\in,16]]);
        events.do { |event|
            score.add([0.1+(event.beat*60/spec.bpm),~rockMessage.value(event,node,100,16,spec.bpm)]);
            node=node+1;
        };
        end=0.1+(128*60/spec.bpm);duration=end+5;
        score.add([end+2.5,[\n_set,999,\gate,0]]);
        score.add([duration,[\c_set,0,0]]);
        osc=Platform.defaultTempDir+/+(file++".osc");
        ("Rendering "++spec.title++" / "++spec.scaleName++" / "++spec.bpm++" BPM").postln;
        Score(score.asArray).recordNRT(oscFilePath:osc,outputFilePath:repo+/+"audio"+/+(file++".wav"),
            sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:duration,
            options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
                .numWireBufs_(128).memSize_(65536).loadDefs_(false),
            action:{ |code|
                File.delete(osc);failed=failed or:{code!=0};pending=pending-1;
                ("Completed "++spec.file++" / exit "++code).postln;
                if(pending==0){if(failed){1.exit}{0.exit}};
            });
    };
} { |error|error.reportError;1.exit};
)
