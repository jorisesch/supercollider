// EDM D: syncopated groove, delayed lead vibrato, richer percussion, and pad texture.
// Optional args: seed bpm [nogui].
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "launch.scd").load;
(root +/+ "d-engine.scd").load;
(root +/+ "d-instruments.scd").load;
~runExperiment.value(\edm, thisProcess.argv);
)
