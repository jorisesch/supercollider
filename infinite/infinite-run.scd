// Command-line launcher; args: mode chaos density mutation tension bpm seed [nogui].
// From repository root: sclang -D infinite/infinite-run.scd edm 0.25 0.55 0.30 0.20 128 2600
(
var root=thisProcess.nowExecutingPath.dirname, args=thisProcess.argv;
var mode=(args.at(0) ? "edm").asSymbol, values, bpm, seed, server;
if([\edm, \soundscape].includes(mode).not) {
    "Usage: infinite-run.scd edm|soundscape chaos density mutation tension bpm seed [nogui]".postln;
    1.exit;
};
values=[0.25, 0.55, 0.30, 0.20].collect { |fallback, i|
    if(args.at(i + 1).notNil) { args[i + 1].asFloat.clip(0, 1) } { fallback };
};
bpm=if(args.at(5).notNil) { args[5].asFloat.clip(40, 200) } { if(mode == \edm, 128, 60) };
seed=if(args.at(6).notNil) { args[6].asInteger } { 2600 };
(root +/+ "infinite-live.scd").load;
~setInfinite.value(*values);
// Own server: do not replace or reconfigure an existing IDE server.
server=Server(\infiniteMusic, NetAddr("127.0.0.1", 57130),
    ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2));
~startInfinite.value(mode, seed, bpm, server);
if(args.includes("nogui").not) {
    (root +/+ "infinite-controls.scd").load;
    {
        var close;
        ~showInfiniteControls.value;
        close=~infiniteWindow.onClose;
        ~infiniteWindow.onClose_ {
            close.value;
            SystemClock.sched(3.5, { server.quit; 0.exit; nil });
        };
    }.defer;
};
"Close the control window to fade out and exit; Ctrl+C in this terminal exits immediately.".postln;
)
