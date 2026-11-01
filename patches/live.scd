// Evaluate this block to load instruments and start the five-second launch countdown.
(
var root = thisProcess.nowExecutingPath.dirname;
(root +/+ "instruments.scd").load;
s.waitForBoot {
    ~quindarDef.add; ~quindarRadioDef.add; ~rocketDef.add; ~countdownDef.add;
    s.sync;
    ~launchRoutine = Routine {
        5.do { Synth(\launchBeep); 1.wait };
        Synth(\launchBeep, [\freq, 1320, \dur, 0.35]);
        ~rocket = Synth(\rocketEngine);
    }.play;

};
)

// Evaluate individual lines after ignition:
Synth(\quindar, [\freq, 2525]); // IN
Synth(\quindar, [\freq, 2475]); // OUT
~rocket.set(\throttle, 0.85, \grit, 0.7); // accelerate
~rocket.set(\throttle, 0.18, \pan, -0.25); // idle, drift left
~rocket.set(\gate, 0); // graceful 2.5-second stop
// Cmd+. stops all sound in the SuperCollider IDE if needed.

// Separate vinyl-textured variants (noise ranges from 0 to 1):
Synth(\quindarRadio, [\freq, 2525, \seed, 1962]); // noisy IN
Synth(\quindarRadio, [\freq, 2475, \seed, 1969, \variant, 1]); // noisy OUT

// Rocket motion and failures:
~rocket.set(\cycle, 7, \motion, 0.12);
~rocket.set(\malfunction, 0.95); // choking, misfire, pitch instability
~rocket.set(\malfunction, 0, \throttle, 0.8); // recover and accelerate

~rocket.set(\sand, 0.28); // subdued sand texture (0–1.5)

~launchRoutine.stop; // cancel a countdown before ignition
