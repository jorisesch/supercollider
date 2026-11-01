// Experiment B: warm ambient. Optional args: seed bpm [nogui].
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "launch.scd").load;
~runExperiment.value(\soundscape, thisProcess.argv);
)
