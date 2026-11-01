// Play the lead-forward candidate from before the bass-led arrangement.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "launch.scd").load;
~djRun.value(thisProcess.argv);
)
