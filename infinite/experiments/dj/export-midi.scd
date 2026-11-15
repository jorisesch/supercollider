// Export one generated song as a Standard MIDI File.
// sclang export-midi.scd [channel=edm] [seed=1] [song=1] [out.mid]
// The song number counts from the start of the set (song 1 is the opening song).
(
var root=thisProcess.nowExecutingPath.dirname,args=thisProcess.argv;
var channel,seed,song,path,engine,capture,result;
try {
    (root+/+"engine.scd").load; (root+/+"midi-export.scd").load;
    channel=~djResolveChannel.value((args[0] ? "edm").asSymbol);
    seed=(args[1] ? "1").asInteger; song=(args[2] ? "1").asInteger.max(1);
    engine=~makeDJEngine.value(seed,if(channel==\edme){134}{~djDefaultBpm.value(channel)},(channel:channel));
    capture=~djMidiCollect.value(engine,song-1);
    result=~djMidiBytes.value(capture);
    path=args[3] ?? {root+/+"midi"+/+result.fileName};
    File.mkdir(path.dirname);
    ~djMidiWrite.value(result,path);
    ("MIDI " ++ result.name ++ " / " ++ result.bpm.round(0.1) ++ " BPM / " ++ result.bars ++ " bars / "
        ++ (result.tracks-1) ++ " parts / " ++ result.notes ++ " notes -> " ++ path).postln;
    0.exit;
} {|error| error.reportError; 1.exit};
)
