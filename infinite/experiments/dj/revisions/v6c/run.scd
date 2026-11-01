// Play the source preserved when groove track v6.2 became the favourite.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "launch.scd").load;
~djRun.value(thisProcess.argv);
)
