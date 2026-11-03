// Render current Rock players without overwriting the earlier listening reference.
(
var root=thisProcess.nowExecutingPath.dirname;
~djRockRenderNames=["rock-player-set","rock-player-comparison"];
~djRockTimelineDir=root;
(root.dirname+/+"rock-render.scd").load;
)
