// Standalone EDM E render. Args: compare, set, bass, percussion, chords, or track.
(
var root=thisProcess.nowExecutingPath.dirname;
~djRenderChannel=\edme;
(root +/+ "dj/render.scd").load;
)
