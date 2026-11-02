// Modal solution of a stiff plucked string, sensed as velocity at a pickup.
// No free-running body oscillator or per-note clipping. See GUITAR.md.
(
~djStringMotion={|freq,fromFreq,slideTime,bendSemis,bendMode,vibrato,vibratoRate,hold,stringIndex,pickStrength=1,pickPosition=0.12|
    var open=Select.kr(stringIndex.clip(0,5),[40,45,50,55,59,64]).midicps;
    var diameter=Select.kr(stringIndex.clip(0,5),[0.00046,0.00042,0.00036,0.00043,0.00033,0.00025]);
    var mass=Select.kr(stringIndex.clip(0,5),[0.0063,0.0036,0.0023,0.0011,0.00068,0.00039]);
    var ei=200e9*pi*diameter.pow(4)/64,ea=200e9*pi*diameter.squared/4;
    var target=freq.clip(65,1800),base=target/Select.kr(bendMode>1.5,[1,bendSemis.midiratio]);
    var start=Select.kr(fromFreq>0,[base,fromFreq.clip(65,1800)]),fret,progress,length,rest,tension,delta,displacement,bend,vib,depth,pluck;
    progress=Line.kr(0,1,slideTime.max(0.004));
    fret=(start/open).log2*12+(((base/start).log2*12)*progress);
    // A finger slide crosses actual frets. Small smoothing is fret contact time.
    fret=Select.kr(slideTime>0,[((base/open).log2*12),Lag.kr(fret.round(1),0.002)]);
    length=0.648*(2.pow(fret/12)).reciprocal;rest=(0.648-length+0.08).max(0.08);
    tension=(mass*(2*length*base).squared)-(ei*pi.squared/length.squared);
    // For slides, the string's unbent tension stays fixed while length changes.
    tension=Select.kr(slideTime>0,[tension,(mass*(2*0.648*open).squared)-(ei*pi.squared/0.648.squared)]).max(10);
    delta=tension*((bendSemis*2).midiratio-1);
    displacement=(2*delta*0.728/(ea*(length.reciprocal+rest.reciprocal))).max(0).sqrt;
    bend=Select.kr(bendMode.clip(0,2),[0,
        EnvGen.kr(Env([0,0,1,1,0,0],hold*[0.10,0.22,0.30,0.24,0.14],\sin)),
        EnvGen.kr(Env([0,1,1],hold*[0.30,0.70],\sin))]);
    depth=(2*tension*((vibrato*2).midiratio-1)*0.728/(ea*(length.reciprocal+rest.reciprocal))).max(0).sqrt;
    vib=(1-SinOsc.kr((vibratoRate+LFNoise2.kr(1.4,0.07)),pi*0.5))*0.5;
    vib=vib*EnvGen.kr(Env([0,0,1,1,0,0],hold*[0.22,0.14,0.40,0.12,0.12],\sin));
    // Bend/release finger vibrato stays above the unbent tension; both gestures
    // share the same lateral displacement, instead of multiplying pitch LFOs.
    displacement=((displacement*bend).squared+(depth.squared*vib)).sqrt;
    delta=ea/0.728*displacement.squared*((length+(length.squared+displacement.squared).sqrt).reciprocal
        +(rest+(rest.squared+displacement.squared).sqrt).reciprocal);
    // Quasistatic extra tension from triangular-pluck strain energy. Use a
    // two-time-scale energy-loss approximation (bright attack + longer modes).
    pluck=(pickPosition/length).clip(0.04,0.8);
    pluck=(ea/0.728)*(0.00038*pickStrength).squared/(4*length*pluck*(1-pluck));
    pluck=pluck*((EnvGen.kr(Env([1,0],[0.18],-5))*0.5)
        +((Line.kr(0,hold+0.1,hold+0.1)* -1.5).exp*0.5));
    tension=tension+delta+pluck;
    (length:length,tension:tension,mass:mass,ei:ei,fret:fret,
        fundamental:((tension/mass)+(ei/mass*(pi/length).squared)).sqrt/(2*length));
};
~djDefs=~djDefs++[
    SynthDef(\rockPhysicalGuitar,{|out=0,freq=110,amp=0.08,sustain=0.3,pan=0,seed=1,color=0,tone=0.5,mute=0.5,
        fromFreq=0,slideTime=0,bendSemis=0,bendMode=0,vibrato=0,vibratoRate=5.3,stringIndex=3,pickPosition=0.12,articulation=0|
        var hold=sustain.clip(0.03,4),strength=(amp/0.08).clip(0.05,3),motion,time,pluck,pickup,wire,noise,env;
        RandSeed.ir(1,seed);
        motion=~djStringMotion.value(freq,fromFreq,slideTime,bendSemis,bendMode,vibrato,vibratoRate,hold,stringIndex,strength,pickPosition);
        time=Line.kr(0,hold+0.1,hold+0.1);
        pluck=(pickPosition/motion.length).clip(0.04,0.8);
        pickup=(Select.kr(color.clip(0,2),[0.045,0.115,0.055])/motion.length).clip(0.025,0.8);
        wire=Mix.fill(28,{|i|
            var n=i+1,omega=n*pi/motion.length;
            var hz=((motion.tension/motion.mass)+(motion.ei/motion.mass*omega.squared)).sqrt*n/(2*motion.length);
            var displacement=(2*0.00038*strength*(n*pi*pluck).sin)/(pi.squared*n.squared*pluck*(1-pluck));
            var damping=0.48+(n.squared*0.012)+(mute.clip(0,1)*70*(n*pi*0.025/motion.length).sin.squared);
            var velocity=displacement*2pi*hz*(n*pi*pickup).sin;
            var aperture=(n*pi*0.003/motion.length); // finite pickup aperture
            var coefficient=velocity*(aperture.sin/aperture)*((-1*damping*time).exp);
            // Fade partials before Nyquist, never fold them back into the string.
            SinOsc.ar(hz.min(SampleRate.ir*0.45))*coefficient*(((SampleRate.ir*0.45)-hz)/1800).clip(0,1);
        });
        noise=HPF.ar(WhiteNoise.ar,2100)*EnvGen.kr(Env.perc(0.0003,0.006))*0.015*strength*(1-articulation);
        noise=noise+(BPF.ar(WhiteNoise.ar,2800,0.7)*Decay2.kr(Changed.kr(motion.fret.round(1))*(slideTime>0),0.0005,0.008)*0.003);
        wire=(wire*Select.kr(articulation,[1,0.68]))+noise;
        // Pickup inductance 2.5 H and cable capacitance 470 pF -> 4.64 kHz.
        wire=RLPF.ar(wire,1/(2pi*(2.5*470e-12).sqrt),0.9);
        env=EnvGen.kr(Env.linen(0.0015,hold,0.085,curve:-4),doneAction:2);
        Out.ar(out,Pan2.ar(LeakDC.ar(wire)*env,pan));
    })
];
// Keep transport, drum room and bass path identical to the earlier deck.
~djDefs=~djDefs++[SynthDef(\rockPhysicalDeck,{|in=16,out=28,musicGain=1,bassGain=1,drumsGain=1,bpm=102,
    fxFilter=0,fxCutoff=12000,fxResonance=0.35,fxEcho=0,fxDelay=0.75,fxReverb=0.08,fxStutter=0,fxStutterRate=4,t_stutter=0,
    guitarComp=0,guitarChorus=0,guitarPedal=0,guitarDrive=0.3,guitarTone=0.5,guitarFuzz=0|
    var music=In.ar(in,2),bass=LPF.ar(In.ar(in+2,2),1800)*0.72,drums=In.ar(in+4,2)*1.15;
    var musicLevel=Lag.kr(musicGain,0.02),bassLevel=Lag.kr(bassGain,0.02),drumsLevel=Lag.kr(drumsGain,0.02);
    var delay=Lag.kr(fxDelay.clip(0.08,0.75),0.5)*(60/Lag.kr(bpm.clip(72,140),3));
    var echo,verb,room,program,filtered,phase,gate;
    music=HPF.ar(~djGuitarRig.value(music,Lag.kr(guitarComp.clip(0,0.8),0.08),Lag.kr(guitarChorus.clip(0,0.35),0.2),
        guitarPedal,Lag.kr(guitarDrive.clip(0,0.8),0.1),Lag.kr(guitarTone.clip(0,1),0.1),Lag.kr(guitarFuzz.clip(0,1),0.06)),100)*2;
    room=FreeVerb2.ar(drums[0],drums[1],1,0.34,0.65)*0.08;
    echo=LPF.ar(CombC.ar(HPF.ar(music,450)*Lag.kr(fxEcho.clip(0,1),0.06),2,delay,2.6),3900)*0.35;
    verb=FreeVerb2.ar(music[0],music[1],1,0.52,0.6)*Lag.kr(fxReverb.clip(0,1),0.4)*0.22;
    program=((music+echo+verb)*musicLevel)+(bass*bassLevel)+((drums+room)*drumsLevel);
    filtered=RLPF.ar(program,Lag.kr(fxCutoff.clip(500,18000),0.08),Lag.kr(fxResonance.clip(0.25,0.9),0.08));
    program=(program*(1-Lag.kr(fxFilter.clip(0,1),0.06)))+(filtered*Lag.kr(fxFilter.clip(0,1),0.06));
    phase=Phasor.kr(t_stutter,(bpm.clip(72,140)/60)*fxStutterRate.clip(1,4)*ControlDur.ir,0,1,0);
    gate=1-(Lag.kr(fxStutter.clip(0,1),0.015)*(1-Lag.kr(phase<0.48,0.006)));
    Out.ar(out,LeakDC.ar(program*gate));
})];
)
