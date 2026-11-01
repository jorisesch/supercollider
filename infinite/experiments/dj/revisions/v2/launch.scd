// Defines a standalone CLI runner; live.scd/controls.scd remain loadable in the IDE.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "live.scd").load;
(root +/+ "controls.scd").load;
~djRun={ |args|
    var seed,bpm,server,values;
    args=args ? [];
    seed=if(args.at(0).notNil) { args[0].asInteger } { 2600 };
    bpm=if(args.at(1).notNil) { args[1].asFloat.clip(118,140) } { 128 };
    values=[0.25,0.55,0.30,0.20].collect { |fallback,i|
        if(args.at(i+2).notNil and: { args[i+2] != "nogui" }) { args[i+2].asFloat.clip(0,1) } { fallback };
    };
    ~djSet.value(*values);
    server=Server(\infiniteDJ,NetAddr("127.0.0.1",57134),
        ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false));
    ~djStart.value(seed,bpm,server);
    if(args.includes("nogui").not) {
        {
            var close;
            ~djShow.value; close=~djWindow.onClose;
            ~djWindow.onClose_ {
                close.value; SystemClock.sched(3.5,{ server.quit; 0.exit; nil });
            };
        }.defer;
    };
    "Infinite DJ running. Close the window to fade and exit; Ctrl+C exits immediately. No recording.".postln;
};
)
