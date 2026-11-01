// Standalone launcher for the pre-v3 listening candidate.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "launch.scd").load;
~djRun.value(thisProcess.argv);
)
