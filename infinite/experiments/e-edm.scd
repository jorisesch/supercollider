// Standard EDM alias (formerly E): bass-led DJ with chord stabs, percussion phrases and articulation.
// Optional args: seed bpm chaos density mutation tension [nogui].
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "dj/launch.scd").load;
~djRun.value(["edme"] ++ thisProcess.argv);
)
