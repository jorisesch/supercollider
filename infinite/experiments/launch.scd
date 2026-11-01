// Shared command-line setup. No playback until ~runExperiment.value is called.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "live.scd").load;
(root +/+ "controls.scd").load;
~runExperiment={ |mode=\edm, args, profile=\standard|
    var seed, bpm, server;
    args=args ? [];
    seed=if(args.at(0).notNil) { args[0].asInteger } { 2600 };
    bpm=if(args.at(1).notNil) { args[1].asFloat.clip(40, 200) } { if(mode == \edm, 126, 48) };
    if(mode == \edm) { ~setExperiment.value(0.20, 0.60, 0.20, 0.15) }
        { ~setExperiment.value(0.20, 0.45, 0.15, 0.10) };
    server=Server(if(profile == \bite, \experimentBite, if(mode == \edm, \experimentEDM, \experimentAmbient)),
        NetAddr("127.0.0.1", if(profile == \bite, 57133, if(mode == \edm, 57131, 57132))),
        ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2).loadDefs_(false));
    ~startExperiment.value(mode, seed, bpm, server);
    if(args.includes("nogui").not) {
        {
            var close;
            ~showExperimentControls.value;
            close=~experimentWindow.onClose;
            ~experimentWindow.onClose_ {
                close.value;
                SystemClock.sched((~experimentFade ? 5) + 0.5, { server.quit; 0.exit; nil });
            };
        }.defer;
    };
    "Close window to fade and exit. Ctrl+C in the terminal exits immediately. No audio is recorded.".postln;
};
)
