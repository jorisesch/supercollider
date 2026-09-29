// Evaluate this block to load instruments and start the drone.
(
var root = thisProcess.nowExecutingPath.dirname;
(root +/+ "instruments.scd").load;
s.waitForBoot {
    ~quindarDef.add; ~quindarRadioDef.add; ~racerDef.add;
    s.sync;
    ~racer = Synth(\desertRacer);
};
)

// Evaluate individual lines after boot:
Synth(\quindar, [\freq, 2525]); // IN
Synth(\quindar, [\freq, 2475]); // OUT
~racer.set(\throttle, 0.85, \grit, 0.7); // accelerate
~racer.set(\throttle, 0.18, \pan, -0.25); // idle, drift left
~racer.set(\gate, 0); // graceful 2.5-second stop
// Cmd+. stops all sound in the SuperCollider IDE if needed.

// Separate vinyl-textured variants (noise ranges from 0 to 1):
Synth(\quindarRadio, [\freq, 2525, \seed, 1962]); // noisy IN
Synth(\quindarRadio, [\freq, 2475, \seed, 1969, \variant, 1]); // noisy OUT

// Racer motion and failures:
~racer.set(\cycle, 7, \motion, 0.12);
~racer.set(\malfunction, 0.95); // choking, misfire, pitch instability
~racer.set(\malfunction, 0, \throttle, 0.8); // recover and accelerate

~racer.set(\sand, 0.28); // subdued sand texture (0–1.5)
