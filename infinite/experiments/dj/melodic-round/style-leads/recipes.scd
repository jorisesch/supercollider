// The two Neon Gravity leads approved in round 04-neon, tried on the other four styles.
// Same backing, melody notes and timing as each approved song; only the lead tone changes.
(
var songs=(thisProcess.nowExecutingPath.dirname.dirname+/+"recipes.scd").load.reject {|spec|spec.id=="A"};
var leads=[(leadVoice:\neonSoftKeys,leadAmp:0.085,leadTone:0.3,label:"soft keys"),
    (leadVoice:\neonCleanPluck,leadAmp:0.095,leadTone:0.3,label:"clean pluck")];
var ids="ABCDEFGH",n=0;
songs.collect {|song|
    leads.collect {|lead|
        var spec=song.deepCopy.putAll((id:ids[n].asString,name:song.name++" / "++lead.label,
            leadVoice:lead.leadVoice,leadAmp:lead.leadAmp,leadTone:lead.leadTone,
            paletteName:lead.label.copy.put(0,lead.label[0].toUpper)++"; same "++song.name++" groove",sourceID:song.id));
        n=n+1;spec;
    };
}.flatten;
)
