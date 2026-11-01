// EDM C: evolving infinite DJ. Args: seed bpm chaos density mutation tension [nogui].
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "dj/launch.scd").load;
~djRun.value(thisProcess.argv);
)
