// Evaluate the first block, then use the individual controls below.
(
var root = thisProcess.nowExecutingPath.dirname;
(root +/+ "sonar-ping.scd").load;
s.waitForBoot {
    ~sonarPingDef.add;
    s.sync;
    ~sonar = Synth(\sonarPing, [\freq, 960, \decay, 4.2, \reverb, 0.42]);
};
)

// Trigger another ping after the previous one has faded.
~sonar = Synth(\sonarPing, [\freq, 960, \decay, 4.2, \reverb, 0.42]);
~sonar = Synth(\sonarPing, [\freq, 780, \decay, 5.0, \reverb, 0.58, \water, 0.2, \hull, 0.42]);
~sonar = Synth(\sonarPing, [\freq, 1280, \decay, 2.8, \reverb, 0.34, \pan, -0.2]);
// A graceful early stop, if needed.
~sonar.set(\gate, 0);
