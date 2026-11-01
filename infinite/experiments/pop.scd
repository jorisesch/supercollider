// Infinite Pop DJ. Same arguments as c-edm.scd; default tempo is 138 BPM.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "dj/launch.scd").load;
~djRun.value(thisProcess.argv++["pop"]);
)
