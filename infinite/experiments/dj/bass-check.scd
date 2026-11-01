// Isolated NRT check of filter/drive through the same adapter as live playback.
// Four control settings per bass voice; no hardware playback.
(
var root=thisProcess.nowExecutingPath.dirname,score=List.new,node=1000;
var output=thisProcess.argv.at(0) ? (Platform.defaultTempDir +/+ "dj-bass-check.wav");
var osc=Platform.defaultTempDir +/+ "dj-bass-check.osc",settings=[[0,0.35],[1,0.35],[0.55,0],[0.55,1]];
try {
    (root +/+ "engine.scd").load; (root +/+ "instruments.scd").load;
    TempoClock.default.tempo=1;
    score.add([0] ++ ~djDefs.collect { |def| [\d_recv,def.asBytes] });
    ~djLibrary.palettes.do { |palette,voice|
        settings.do { |control,variant|
            var event=(voice:palette.voices[\djBass],deck:0,lane:0,midinote:33,amp:0.2,
                duration:0.75,pan:0,color:palette.color,tone:control[0],drive:control[1],seed:2600);
            // Bus -2 offsets the bass lane to hardware output zero in this NRT score.
            score.add([0.1+(voice*4)+variant,~djMessage.value(event,node,1,-2,120)]);
            node=node+1;
        };
    };
    score.add([16.1,[\c_set,0,0]]);
    Score(score.asArray).recordNRT(oscFilePath:osc,outputFilePath:output,
        sampleRate:48000,headerFormat:"WAV",sampleFormat:"int24",
        options:ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false),duration:16.1,
        action:{ |code| File.delete(osc); code.exit });
} { |error| error.reportError; 1.exit };
)
