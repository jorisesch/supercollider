// Experiment A: melodic/progressive EDM. Optional args: seed bpm [nogui].
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "launch.scd").load;
~runExperiment.value(\edm, thisProcess.argv);
)
