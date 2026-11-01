// Optional SuperCollider startup example for Tidal / SuperDirt.
// Requires SuperDirt and its samples to be installed.
// This repository file is NOT loaded automatically. See README.md before installing.
// Based on the SuperDirt startup example:
// https://github.com/musikinformatik/SuperDirt/blob/develop/superdirt_startup.scd
(
s.options.numBuffers = 1024 * 256;
s.options.memSize = 8192 * 32;
s.options.numWireBufs = 2048;
s.options.maxNodes = 1024 * 32;
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels = 0;
s.latency = 0.3;

// Boots the default audio server if needed. Does not reboot an existing server.
// Changed server options take effect on its next boot.
s.waitForBoot {
    ~dirt.stop;
    ~dirt = SuperDirt(2, s);
    ~dirt.loadSoundFiles;
    // Add your own sample folders or SynthDef loads here, using portable paths.
    // Optional example: ~dirt.loadSoundFiles(Platform.userHomeDir +/+ "Dirt/samples/*");
    s.sync;
    ~dirt.start(57120, 0 ! 12);
    SuperDirt.default = ~dirt;
    "SuperDirt ready / OSC port 57120 / 12 stereo orbits".postln;
};
)
