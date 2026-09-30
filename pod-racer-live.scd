// Evaluate this block from this saved file in SuperCollider.
(
var root = thisProcess.nowExecutingPath.dirname;
(root +/+ "pod-racer.scd").load;
s.waitForBoot {
    ~podRacerDef.add;
    s.sync;
    ~pod = Synth(\podRacer);
};
)
// Evaluate individual controls:
~pod.set(\speed, 0.8, \lfoRate, 2.8, \cutoff, 1500); // accelerating filter CV
~pod.set(\speed, 0.18, \lfoRate, 0.45, \cutoff, 430); // cheap idle
~pod.set(\lfoShape, 1); // square filter CV
~pod.set(\lfoShape, 0); // triangle filter CV
~pod.set(\gear, 1); // short gear-change surge; return to 0 to re-arm
~pod.set(\gear, 0);
~pod.set(\flyby, 1); // Doppler pass
~pod.set(\flyby, 0); // release the pass trigger
~pod.set(\canyon, 0.8); // send transient material to the wall echoes
~pod.set(\canyon, 0); // dry close-engine perspective
~pod.set(\clankRate, 0.7); // occasional engine casing clanks
~pod.set(\noise, 0.035); // tiny noise bed
~pod.set(\gate, 0); // release
