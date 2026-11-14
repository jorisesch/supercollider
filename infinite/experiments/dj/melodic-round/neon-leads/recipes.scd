// Same Neon Gravity composition and backing; only the lead tone changes.
(
var original=(thisProcess.nowExecutingPath.dirname.dirname+/+"recipes.scd").load[0];
[
    (id:"A",name:"Neon Gravity / rounded lead",leadVoice:\neonRoundLead,leadAmp:0.060,
        leadTone:0.3,paletteName:"Clean rounded lead; same Neon Gravity groove"),
    (id:"B",name:"Neon Gravity / soft keys",leadVoice:\neonSoftKeys,leadAmp:0.085,
        leadTone:0.3,paletteName:"Soft harmonic keys; same Neon Gravity groove"),
    (id:"C",name:"Neon Gravity / clean pluck",leadVoice:\neonCleanPluck,leadAmp:0.095,
        leadTone:0.3,paletteName:"Clean pluck; same Neon Gravity groove"),
    (id:"D",name:"Neon Gravity / no lead",leadVoice:\neonRoundLead,leadAmp:0.060,
        leadTone:0.3,muteLead:true,paletteName:"Drums, bass and chord bed only")
].collect {|choice|original.deepCopy.putAll(choice)};
)
