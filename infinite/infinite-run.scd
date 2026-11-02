// Command-line launcher; args: mode chaos density mutation tension bpm seed [nogui].
// From repository root: sclang -D infinite/infinite-run.scd edm 0.25 0.55 0.30 0.20 128 2600
(
var root=thisProcess.nowExecutingPath.dirname, args=thisProcess.argv;
var mode,values,bpm,seed,server,options;
options=args.select {|item|item=="nogui" or:{item.beginsWith("mode=")} or:{item.beginsWith("melody=")}};
args=args.reject {|item|options.includesEqual(item)};
mode=(args.at(0) ? "edm").asSymbol;
if([\edm, \soundscape, \pop, \rock, \baseline].includes(mode).not) {
    "Usage: infinite-run.scd edm|soundscape|pop|rock|baseline chaos density mutation tension bpm seed [nogui]".postln;
    1.exit;
};
values=[0.25, 0.55, 0.30, 0.20].collect { |fallback, i|
    if(args.at(i + 1).notNil) { args[i + 1].asFloat.clip(0, 1) } { fallback };
};
bpm=if(args.at(5).notNil) { args[5].asFloat.clip(40, 200) } {
    switch(mode,\edm,{128},\baseline,{128},\pop,{138},\rock,{102},{60})
};
seed=if(args.at(6).notNil) { args[6].asInteger } { 2600 };
if([\edm,\pop,\rock].includes(mode)) {
    (root +/+ "experiments/dj/launch.scd").load;
    ~djRun.value([seed.asString,bpm.asString]++values.collect(_.asString)++[mode.asString]
        ++options);
} {
(root +/+ "infinite-live.scd").load;
~setInfinite.value(*values);
// Own server: do not replace or reconfigure an existing IDE server.
server=Server(\infiniteMusic, NetAddr("127.0.0.1", 57130),
    ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2));
~startInfinite.value(if(mode==\baseline){\edm}{mode}, seed, bpm, server);
if(options.includesEqual("nogui").not) {
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
};
)
