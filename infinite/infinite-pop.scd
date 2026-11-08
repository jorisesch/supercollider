// Infinite DJ Pop launcher. Optional args: seed bpm chaos density mutation tension [nogui].
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "infinite-launch.scd").load.value(thisProcess.argv, \pop);
)
