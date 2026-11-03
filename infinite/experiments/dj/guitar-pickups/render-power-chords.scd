// Offline power chords through the shared Tube Screamer and cabinet.
(
var dj=thisProcess.nowExecutingPath.dirname.dirname,repo=dj.dirname.dirname.dirname;
var score=List.new,node=2000,bpm=112,entry=0.10,secondsPerBeat=60/112;
var humbucker=thisProcess.argv.includesEqual("humbucker");
var guitar=if(humbucker){\rockHumbuckerDecay}{\rockSingleCoilDecay};
var deck=if(humbucker){\rockHumbuckerDeck}{\rockPhysicalDeck};
var name=if(humbucker){"rock-humbucker-power-chords"}{"rock-single-coil-power-chords"};
var opens=[40,45,50,55,59,64],rhythm,voicings,hit,osc,duration;
try {
    (dj+/+"instruments.scd").load;
    TempoClock.default.tempo=1;
    voicings=(
        e:[[0,40],[1,47],[2,52]],g:[[0,43],[1,50],[2,55]],
        a:[[1,45],[2,52],[3,57]],b:[[1,47],[2,54],[3,59]]
    );
    // Each hit gives its beat, voicing, hold in beats and palm mute.
    rhythm=[
        [[0,\e,0.43,0.10],[0.75,\e,0.16,0.66],[1.25,\e,0.18,0.60],[2,\g,0.52,0.06],[3,\a,0.72,0.04]],
        [[0,\e,0.55,0.10],[1,\e,0.18,0.63],[1.5,\e,0.17,0.60],[2.5,\g,0.30,0.10],[3.25,\e,0.54,0.08]],
        [[0,\e,0.48,0.10],[0.75,\e,0.16,0.66],[1.25,\e,0.17,0.60],[2,\g,0.52,0.07],[3,\a,0.73,0.04]],
        [[0,\b,0.84,0.06],[1.5,\a,0.37,0.09],[2.25,\g,0.39,0.08],[3,\e,0.68,0.07]],
        [[0,\a,0.57,0.07],[1,\a,0.17,0.56],[1.5,\a,0.19,0.60],[2.25,\g,0.40,0.07],[3,\e,0.68,0.04]],
        [[0,\g,0.52,0.09],[0.75,\a,0.39,0.08],[1.5,\g,0.36,0.08],[2.25,\e,0.49,0.07],[3.25,\e,0.17,0.64]],
        [[0,\e,0.45,0.10],[0.75,\e,0.16,0.66],[1.25,\e,0.17,0.60],[2,\g,0.52,0.07],[3,\a,0.73,0.04]],
        [[0,\b,0.72,0.05],[1,\a,0.55,0.07],[2,\g,0.54,0.08],[3,\e,0.38,0.15]],
        [[0,\e,3.55,0]]
    ];
    ~djDefs.select {|def|[guitar,deck,\djMaster].includes(def.name)}
        .do {|def|score.add([0,[\d_recv,def.asBytes]])};
    score.add([0.01,[\g_new,100,0,1],[\g_new,110,0,100],
        [\s_new,deck,800,1,100,\in,16,\out,28,\bpm,bpm,\musicGain,1.25,
            \bassGain,0,\drumsGain,0,\guitarPedal,2,\guitarDrive,0.76,\guitarTone,0.60,
            \guitarComp,0.06,\fxEcho,0,\fxReverb,0.05],
        [\s_new,\djMaster,900,1,100,\in,28,\drive,1.8]]);
    hit={|bar,stroke|
        var at=entry+(((bar*4)+stroke[0])*secondsPerBeat),palm=stroke[3],chord=voicings[stroke[1]];
        [-0.65,0.65].do {|pan,side|
            chord.do {|pair,i|
                var string=pair[0],note=pair[1],level=(if(stroke[0]==0){0.115}{0.094})*[1,0.89,0.77][i];
                var offset=([0,0.009,0.022][i]+(side*0.013)+((node%5)*0.0009));
                if((note-opens[string]).inclusivelyBetween(0,22).not){Error("Unplayable power chord").throw};
                score.add([at+offset,[\s_new,guitar,node,0,110,\out,16,\freq,note.midicps,
                    \stringIndex,string,\pan,pan,\amp,level*(1-(side*0.07)),\sustain,stroke[2]*secondsPerBeat,
                    \pickPosition,[0.096,0.113][side],\mute,palm,\modalLoss,1,\seed,node]]);
                node=node+1;
            };
        };
    };
    rhythm.do {|bar,i|bar.do {|stroke|hit.value(i,stroke)}};
    duration=22;
    score.add([20,[\n_set,900,\gate,0]]);
    score.add([duration,[\c_set,0,0]]);
    osc=Platform.defaultTempDir+/+(name++".osc");
    Score(score.asArray.sort {|a,b|a[0]<b[0]}).recordNRT(oscFilePath:osc,
        outputFilePath:repo+/+"audio"+/+(name++".wav"),
        sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",duration:duration,
        options:ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2).numWireBufs_(128)
            .memSize_(65536).loadDefs_(false),
        action:{|code|File.delete(osc);code.exit});
} {|error|error.reportError;1.exit};
)
