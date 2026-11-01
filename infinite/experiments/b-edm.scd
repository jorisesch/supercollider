// EDM B: more bite, same four tracks. Optional args: seed bpm [nogui].
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "launch.scd").load;
(root +/+ "bite-engine.scd").load;
(root +/+ "bite-instruments.scd").load;
~runExperiment.value(\edm, thisProcess.argv, \bite);
)
