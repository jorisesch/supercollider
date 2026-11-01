// Native stereo FFT panel. Definitions only; reading the mix never writes audio.
(
~djAddSpectrum={ |window,server,height=120,top=610|
    var scopes,labels,lastSampleRate,power;
    var state=(enabled:true),refresh,kill;
    StaticText(window,Rect(20,top,600,20)).string_("Spectrum")
        .toolTip_("Final stereo output. Logarithmic frequency in Hz/kHz, amplitude over an 80 dB range.");
    power=Button(window,Rect(710,top-2,130,24)).states_([["Spectrum OFF"],["Spectrum ON"]])
        .value_(1).action_ { |view|
            state.enabled=view.value==1;
            ("DJ spectrum: " ++ if(state.enabled) {"ON"} {"OFF"}).postln;
        };
    scopes=Array.fill(2,{ |channel|
        var x=55+(channel*425),scope;
        StaticText(window,Rect(x,top+20,360,12)).font_(Font("Helvetica",10))
            .string_(if(channel==0) {"LEFT"} {"RIGHT"});
        // Root-tail placement inside FreqScopeView reads the final output,
        // after the DJ master and the server's output-volume stage.
        scope=FreqScopeView(window,Rect(x,top+36,360,height),server);
        scope.inBus_(channel).freqMode_(1).dbRange_(80);
        scope.scope.background_(Color.gray(0.07)).waveColors_([Color.new255(84,211,179)]);
        [0,40,80].do { |db|
            StaticText(window,Rect(x-35,top+30+((db/80)*height),30,12))
                .font_(Font("Helvetica",10)).align_(\right)
                .string_(if(db==0) {"0 dB"} {"-" ++ db});
        };
        scope;
    });
    labels=Array.fill(2,{ |channel|
        [50,100,500,1000,5000,10000,20000].collect { |hz|
            [hz,StaticText(window,Rect(0,top+38+height,36,16))
                .font_(Font("Helvetica",10)).align_(\center)
                .string_(if(hz>=1000) {(hz/1000).asInteger.asString ++ "k"} {hz.asString})];
        };
    });
    refresh={ |playing|
        var sampleRate=server.sampleRate ? 48000;
        var analyze=state.enabled and: {playing} and: {server.serverRunning};
        if(sampleRate<=0) {sampleRate=48000};
        scopes.do { |scope| if(scope.active!=analyze) {scope.active_(analyze)} };
        if(sampleRate!=lastSampleRate) {
            labels.do { |ticks,channel|
                var bins=scopes[channel].bufSize/2,binHz=sampleRate/scopes[channel].bufSize;
                ticks.do { |pair|
                    var x=((pair[0]/binHz).log/bins.log).clip(0,1);
                    pair[1].bounds_(Rect(55+(channel*425)+(x*360)-18,top+38+height,36,16));
                    pair[1].visible_(pair[0]<(sampleRate/2));
                };
            };
            lastSampleRate=sampleRate;
        };
    };
    kill={scopes.do(_.kill)};
    (scopes:scopes,power:power,state:state,refresh:refresh,kill:kill);
};
)
