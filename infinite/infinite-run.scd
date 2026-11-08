// Command-line launcher; args: mode chaos density mutation tension bpm seed [nogui].
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "infinite-launch.scd").load.value(thisProcess.argv);
)
