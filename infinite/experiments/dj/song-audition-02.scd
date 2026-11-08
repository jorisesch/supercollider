// Six separate arrangement grammars for the second listening round. Offline only.
(
var root=thisProcess.nowExecutingPath.dirname, output=thisProcess.argv.at(0), index=0, render;
var four=[0,4,8,12], recipes=[
    (id:"A",name:"Voltage Leak",channel:\edme,style:\acid,bpm:144,keyName:"F# Phrygian",tonic:42,
        scale:[0,1,3,5,7,8,10],paletteName:"Resonant mono acid",seed:140207,
        kicks:[[0,4,8,12]],snares:[4,12],hats:[2,6,10,14],chords:[0,0,1,0],drum:\djDustKick,form:[4,12,16]),
    (id:"B",name:"Closed Circuit",channel:\edme,style:\electro,bpm:140,keyName:"C Aeolian",tonic:36,
        scale:[0,2,3,5,7,8,10],paletteName:"Metal hits and sub",seed:235401,
        kicks:[[0,6,10],[0,7,10,15]],snares:[4,12],hats:[2,5,8,11,14],chords:[0,0,5,6],drum:\djElectroKick,form:[2,16,20]),
    (id:"C",name:"Pressure Front",channel:\edme,style:\breaks,bpm:158,keyName:"D Dorian",tonic:38,
        scale:[0,2,3,5,7,9,10],paletteName:"Dry break kit and FM stabs",seed:352703,
        kicks:[[0,6,10],[0,7,10,14]],snares:[4,12],hats:[2,6,8,14],chords:[0,0,3,0],drum:\djElectroKick,form:[2,10,12]),
    (id:"D",name:"Night Relay",channel:\edme,style:\trance,bpm:146,keyName:"B Harmonic minor",tonic:35,
        scale:[0,2,3,5,7,8,11],paletteName:"Rolling bass and pulse lead",seed:451309,
        kicks:[[0,4,8,12]],snares:[4,12],hats:[2,6,10,14],chords:[0,5,3,4],drum:\djAnalogKick,form:[6,14,18]),
    (id:"E",name:"Silver Hours",channel:\pop,style:\synthPop,bpm:132,keyName:"E Aeolian",tonic:40,
        scale:[0,2,3,5,7,8,10],paletteName:"Electric keys and soft pulse",seed:562901,
        kicks:[[0,8,10],[0,6,8,14]],snares:[4,12],hats:[2,6,10,14],chords:[0,5,2,6],drum:\djKick),
    (id:"F",name:"White Lines",channel:\rock,style:\motorik,bpm:118,keyName:"G Mixolydian",tonic:43,
        scale:[0,2,4,5,7,9,10],paletteName:"Dry single-coil and motorik drums",seed:684023,
        kicks:[[0,8,10],[0,8]],snares:[4,12],hats:[0,2,4,6,8,10,12,14],chords:[0,6,3,0],drum:\djAnalogKick,form:[4,12,16])
];
var voices=[
    SynthDef(\auditionAcid,{|out=0,freq=55,from=55,slide=0,amp=0.12,sustain=0.16,tone=0.4,pan=0|
        var pitch=Select.kr(slide>0,[freq,XLine.kr(from.max(25),freq,slide.max(0.005))]);
        var contour=EnvGen.kr(Env.perc(0.003,0.16,curve:-4));
        var env=EnvGen.kr(Env.linen(0.004,sustain,0.035),doneAction:2);
        var cutoff=(220+(tone*1450)+(contour*(680+(tone*2200)))).clip(160,6500);
        var sig=RLPF.ar(Saw.ar(pitch)*0.68+Pulse.ar(pitch,0.44)*0.32,cutoff,0.18);
        Out.ar(out,Pan2.ar(HPF.ar((sig*2.8).tanh,34),pan,amp*env));
    }),
    SynthDef(\auditionSub,{|out=0,freq=55,amp=0.13,sustain=0.14,tone=0.4,pan=0|
        var env=EnvGen.kr(Env.linen(0.006,sustain,0.038),doneAction:2);
        var sig=(SinOsc.ar(freq)*0.75)+(LPF.ar(Pulse.ar(freq*2,0.37),430+(tone*1100))*0.25);
        Out.ar(out,Pan2.ar(sig,pan,amp*env));
    }),
    SynthDef(\auditionFM,{|out=0,freq=330,amp=0.1,sustain=0.2,tone=0.4,pan=0,ratio=2|
        var strike=EnvGen.kr(Env.perc(0.001,0.19,curve:-4));
        var env=EnvGen.kr(Env([0,1,0.48,0],[0.003,sustain,0.14],[-3,-2,-4]),doneAction:2);
        var signal=SinOsc.ar(freq,SinOsc.ar(freq*ratio,0,0.2+(strike*tone*3.5)));
        Out.ar(out,Pan2.ar(signal,pan,amp*env));
    }),
    SynthDef(\auditionPulse,{|out=0,freq=330,amp=0.1,sustain=0.2,tone=0.4,pan=0|
        var env=EnvGen.kr(Env.linen(0.012,sustain,0.12),doneAction:2);
        var width=SinOsc.kr(0.9).range(0.31,0.47);
        var sig=LPF.ar(Pulse.ar(freq*[0.997,1.003],width),720+(tone*2700));
        Out.ar(out,Balance2.ar(sig[0],sig[1],pan,amp*env));
    }),
    SynthDef(\auditionSoftSnare,{|out=0,amp=0.08,pan=0,seed=1|
        var env=EnvGen.kr(Env.perc(0.002,0.092,curve:-4),doneAction:2), body, brush;
        RandSeed.ir(1,seed);
        body=SinOsc.ar(172)*EnvGen.kr(Env.perc(0.002,0.042));
        brush=BPF.ar(WhiteNoise.ar,1650,0.88);
        Out.ar(out,Pan2.ar((body*0.39)+(brush*0.92),pan,amp*env));
    }),
    SynthDef(\auditionGuitarMix,{
        Out.ar(28,LPF.ar(HPF.ar(In.ar(24,2),100),5700)*0.31);
    })
];
try {
    if(output.isNil or:{File.exists(output).not}){Error("Provide an existing output directory").throw};
    (root+/+"engine.scd").load;
    (root+/+"instruments.scd").load;
    (root+/+"feedback.scd").load;
    TempoClock.default.tempo=1;
    render={
        var spec=recipes[index], style=spec.style, score=List.new, beat=60/spec.bpm, bars=24;
        var add, pitch, counter=1100, currentBar, duration, path, phases, hatAmp, kick, snare;
        var form=spec.form ? [0,24,24];
        ~djDefs.select {|def|[spec.drum,\djSnare,\djElectroSnare,\djHat,\djMaster,\rockSingleCoilDecay].includes(def.name.asSymbol)}
            .do {|def|score.add([0,[\d_recv,def.asBytes]])};
        voices.do {|def|score.add([0,[\d_recv,def.asBytes]])};
        score.add([0.01,[\s_new,\djMaster,900,1,1,\in,28,\drive,1.9]]);
        if(style==\motorik){score.add([0.02,[\s_new,\auditionGuitarMix,899,2,900]])};
        pitch={|degree,octave=0|spec.tonic+spec.scale.wrapAt(degree)+(12*((degree div:7)+octave))};
        add={|voice,step,note,span,gain,tone=0.4,pan=0,extra|
            var time=0.11+(((currentBar*4)+(step*0.25))*beat);
            var guitar=voice==\rockSingleCoilDecay;
            score.add([time,[\s_new,voice,counter,2,if(guitar){899}{900},\out,if(guitar){24}{28},\freq,note.midicps,
                \sustain,span*beat,\amp,gain,\pan,pan,\tone,tone,\seed,spec.seed+counter]++(extra ? #[])]);
            counter=counter+1;
        };
        phases=case {style==\synthPop}{[[0,"verse"],[8,"chorus"],[16,"verse"],[20,"chorus"]]}
            {style==\trance}{[[0,"rhythm"],[8,"lead"],[14,"contrast"],[18,"return"]]}
            {[[0,"statement"],[form[0],"full groove"],[form[1],"contrast"],[form[2],"return"]]};
        bars.do {|bar|
            var chorus=(bar>=8 and:{bar<16}) or:{bar>=20};
            var contrast=bar>=form[1] and:{bar<form[2]}, full=bar>=form[0] and:{contrast.not};
            var cell=bar%2, degree=spec.chords.wrapAt(bar div:2), riff, accent, from, bassSteps;
            currentBar=bar;
            if(style==\synthPop and:{chorus.not}){degree=[0,0,5,6].wrapAt(bar div:2)};
            kick=spec.kicks.wrapAt(cell);
            snare=case {style==\motorik}{\auditionSoftSnare} { [\breaks,\electro].includes(style)}{\djElectroSnare} {\djSnare};
            hatAmp=switch(style,\breaks,{0.034},\motorik,{0.011},{0.022});
            if(style==\trance and:{contrast}){kick=[0,8]};
            if(style==\electro and:{contrast}){kick=[0,10]};
            kick.do {|step|add.value(spec.drum,step,33,0.52,if(step==0){0.29}{0.25})};
            spec.snares.do {|step|add.value(snare,step+0.025,50,0.22,if(style==\motorik){0.068}{0.105},0.4,-0.05)};
            spec.hats.do {|step,i|add.value(\djHat,step,104,0.11,hatAmp*[1,0.68,0.9].wrapAt(i),0.4,0.18)};
            if(style==\breaks and:{cell==1}){
                add.value(snare,15.06,50,0.10,0.025,0.4,0.1);
            };
            switch(style,
                \acid,{
                    riff=if(cell==0){[[1,0],[3,0],[6,7],[7,5],[9,0],[13,2],[15,1]]}
                        {[[1,0],[4,0],[6,4],[9,0],[11,0],[14,1]]};
                    from=pitch.value(degree);
                    riff.do {|hit,j|
                        var note=pitch.value(degree+hit[1]), glide=[3,7,15].includes(hit[0]);
                        accent=[1,6,13,14].includes(hit[0]);
                        add.value(\auditionAcid,hit[0],note,if(glide){0.17}{0.27},
                            if(accent){0.165}{0.107},if(contrast){0.27}{if(full){0.58}{0.35}},
                            0,[\from,from.midicps,\slide,if(glide){0.061}{0}]);
                        from=note;
                    };
                },
                \electro,{
                    bassSteps=if(cell==0){[0,3,6,11]}{[0,5,10,13]};
                    bassSteps.do {|step,j|add.value(\auditionSub,step,pitch.value(degree+if(j==3){4}{0}),0.4,0.15)};
                    if(full or:{contrast}){
                        riff=if(cell==0){[[1,7],[7,5],[12,3]]}{[[3,2],[8,1]]};
                        riff.do {|hit,j|add.value(\auditionFM,hit[0],pitch.value(hit[1],2),
                            if(contrast){0.62}{0.22},if(contrast){0.052}{0.077},0.64,(j-1)*0.22,[\ratio,2.71])};
                    };
                },
                \breaks,{
                    kick.do {|step,j|add.value(\auditionSub,step+0.22,pitch.value(degree+[0,0,4,0][j]),0.30,0.15,0.51)};
                    if(full){
                        (if(cell==0){[2,8]}{[2,13]}).do {|step,j|add.value(\auditionFM,step,pitch.value(degree+[7,4][j],2),
                            0.19,0.077,0.69,(j-1)*0.22,[\ratio,1.49])};
                    };
                },
                \trance,{
                    bassSteps=if(contrast){[2,6,10,14]}{four.collect {|step|[step+1,step+2,step+3]}.flat};
                    bassSteps.do {|step|add.value(\auditionSub,step,pitch.value(degree),0.16,0.13,0.61)};
                    if(bar>=8){
                        riff=if(cell==0){[[2,0,1.2],[8,2,0.43],[11,4,1.0]]}{[[2,4,0.58],[7,2,0.42],[10,0,1.12]]};
                        riff.do {|hit,j|add.value(\auditionPulse,hit[0],pitch.value(degree+hit[1],2),hit[2],0.074,
                            if(contrast){0.22}{0.46},(j-1)*0.15)};
                        [0,2,4].do {|offset,j|add.value(\auditionPulse,0,pitch.value(degree+offset,1),3.6,0.021,0.18,(j-1)*0.4)};
                    };
                },
                \synthPop,{
                    [0,3,8,11].do {|step,j|add.value(\auditionSub,step,pitch.value(degree+[0,0,4,0][j]),0.45,0.13)};
                    [0,2,4].do {|offset,j|
                        [2,10].do {|step|add.value(\auditionFM,step,pitch.value(degree+offset,2),0.8,0.044,0.26,(j-1)*0.27)};
                    };
                    if(chorus){
                        riff=if(cell==0){[[0,4,0.7],[4,4,0.38],[7,2,0.3],[10,0,1.05]]}{[[2,2,0.53],[6,4,0.41],[10,2,1.11]]};
                        riff.do {|hit|add.value(\auditionPulse,hit[0],pitch.value(degree+hit[1],2),hit[2],0.083,0.38)};
                    };
                },
                \motorik,{
                    four.do {|step|add.value(\auditionSub,step,pitch.value(degree),0.45,0.11,0.26)};
                    [0,3,6,8,11,14].do {|step,j|
                        var note=pitch.value(degree+[0,4,7,4,2,4][j],1);
                        add.value(\rockSingleCoilDecay,step,note,0.57,0.072,0.62,-0.17,
                            [\stringIndex,2,\pickPosition,0.088,\mute,0.22,\color,1]);
                    };
                    if(full){
                        [0,4,7].do {|offset,j|add.value(\rockSingleCoilDecay,8+(j*0.095),
                            pitch.value(degree+offset,1),1.45,0.052,0.52,0.25,
                            [\stringIndex,j+1,\pickPosition,0.13,\mute,0.08,\color,1])};
                    };
                }
            );
        };
        duration=0.11+(bars*4*beat)+2.2;
        score.add([duration-2.2,[\n_set,900,\gate,0]]);
        score.add([duration,[\c_set,0,0]]);
        path=output+/+spec.id;
        File.use(path++".json","w",{|f|
            f.write(~djJSON.value(spec.copy.putAll((file:spec.id++".wav",bars:bars,
                sections:phases,seconds:duration)))++"\n");
        });
        ("Rendering "++spec.id++" "++spec.name).postln;
        Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:path++".osc",
            outputFilePath:path++".wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:duration,
            options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
                .numWireBufs_(128).memSize_(65536).loadDefs_(false),
            action:{|code|
                File.delete(path++".osc");
                if(code!=0){code.exit};
                index=index+1;
                if(index>=recipes.size){0.exit}{try {render.value}{|error|error.reportError;1.exit}};
            });
    };
    render.value;
} {|error|error.reportError;1.exit};
)
