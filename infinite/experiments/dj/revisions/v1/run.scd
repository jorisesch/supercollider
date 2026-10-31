(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "launch.scd").load;
~djRun.value(thisProcess.argv);
)
