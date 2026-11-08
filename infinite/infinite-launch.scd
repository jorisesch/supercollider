// Shared desktop launcher. Named entry points take seed, bpm, then the four controls.
{
    var root=thisProcess.nowExecutingPath.dirname;
    { |args, channel|
        var mode, values, bpm, seed, server, options, named = channel.notNil;
        options=args.select {|item|item=="nogui" or:{item.beginsWith("mode=")} or:{item.beginsWith("melody=")}};
        args=args.reject {|item|options.includesEqual(item)};
        mode=channel ? (args.at(0) ? "edm").asSymbol;
        if([\edm, \soundscape, \pop, \rock, \dubstep, \baseline].includes(mode).not) {
            "Usage: infinite-run.scd edm|soundscape|pop|rock|dubstep|baseline chaos density mutation tension bpm seed [nogui]".postln;
            1.exit;
        };
        values=[0.25, 0.55, 0.30, 0.20].collect { |fallback, i|
            var value=args.at(i + if(named) {2} {1});
            if(value.notNil) { value.asFloat.clip(0, 1) } { fallback };
        };
        bpm=args.at(if(named) {1} {5}).tryPerform(\asFloat);
        bpm=if(bpm.notNil) { bpm.clip(40, 200) } {
            switch(mode,\edm,{128},\baseline,{128},\pop,{138},\rock,{102},\dubstep,{140},{60})
        };
        seed=args.at(if(named) {0} {6}).tryPerform(\asInteger);
        if([\edm,\pop,\rock,\dubstep].includes(mode)) {
            (root +/+ "experiments/dj/launch.scd").load;
            if(seed.isNil) { seed=~djFreshSeed.value };
            ~djRun.value([seed.asString,bpm.asString]++values.collect(_.asString)++[mode.asString]
                ++options);
        } {
            (root +/+ "infinite-live.scd").load;
            ~setInfinite.value(*values);
            // Own server: do not replace or reconfigure an existing IDE server.
            server=Server(\infiniteMusic, NetAddr("127.0.0.1", 57130),
                ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2));
            ~startInfinite.value(if(mode==\baseline){\edm}{mode}, seed ? 2600, bpm, server);
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
    }
}.value
