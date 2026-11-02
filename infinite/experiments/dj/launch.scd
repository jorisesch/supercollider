// Defines a standalone CLI runner; live.scd/controls.scd remain loadable in the IDE.
(
var root=thisProcess.nowExecutingPath.dirname;
(root +/+ "live.scd").load;
(root +/+ "controls.scd").load;
~djRun={ |args|
    var seed,bpm,server,values,modeArg,melodyArg,gui;
    args=args ? [];gui=args.includesEqual("nogui").not;
    args=args.reject {|item|item=="nogui"};
    modeArg=args.detect {|item|item.beginsWith("mode=")};
    melodyArg=args.detect {|item|item.beginsWith("melody=")};
    ~djSettings.tonality=if(modeArg.isNil){\original}{modeArg.copyRange(5,modeArg.size-1).asSymbol};
    ~djSettings.melody=if(melodyArg.isNil){\full}{melodyArg.copyRange(7,melodyArg.size-1).asSymbol};
    args=args.reject {|item|item.beginsWith("mode=") or:{item.beginsWith("melody=")}};
    ~djSettings.channel=case {args.includesEqual("rock")} {\rock} {args.includesEqual("pop")} {\pop} {true} {\edme};
    ~djSettings.modalPolicy=if(~djSettings.channel==\rock){\fixed}{\tension};
    ~djSettings.rockLeadVersion=if(~djSettings.channel==\rock){1}{0};
    ~djSettings.rockToneVersion=if(~djSettings.channel==\rock){2}{0};
    ~djSettings.autoStutter=~djSettings.channel!=\rock;
    args=args.reject { |item| ["pop","rock","edm","edme","classic"].includesEqual(item) };
    seed=if(args.at(0).notNil) { args[0].asInteger } { 2600 };
    bpm=if(args.at(1).notNil) { args[1].asFloat } { ~djDefaultBpm.value(~djSettings.channel) };
    values=[0.25,0.55,0.30,0.20].collect { |fallback,i|
        if(args.at(i+2).notNil and: { args[i+2] != "nogui" }) { args[i+2].asFloat.clip(0,1) } { fallback };
    };
    ~djSet.value(*values);
    server=Server(\infiniteDJ,NetAddr("127.0.0.1",57134),
        ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false));
    ~djStart.value(seed,bpm,server);
    if(gui) {
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
