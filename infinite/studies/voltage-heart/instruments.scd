// Load the voices without starting audio.
{
    var root = thisProcess.nowExecutingPath.dirname;
    ["drums.scd", "bass.scd", "harmony.scd", "lead.scd"].collect { |file|
        (root +/+ file).load
    }.flat
}.value
