// Definitions only: eight logical lanes across two decks; stock UGens throughout.
(
var root=thisProcess.nowExecutingPath.dirname;
~djDefs=[
    SynthDef(\djBass, { |out=0, freq=65, amp=0.19, sustain=0.25, color=0, tone=0.4, pan=0, drive=0.35|
        var env=EnvGen.kr(Env([0,1,0.78,0], [0.012,0.055,sustain.max(0.07)], [-2,-2,-4]), doneAction:2);
        var pitch=freq.clip(25,400),grit=drive.clip(0,1), body, harmonic, filter;
        harmonic=Select.ar(color.clip(0,3), [
            Saw.ar(pitch) * 0.5, Pulse.ar(pitch,0.42) * 0.4,
            SinOsc.ar(pitch, SinOsc.ar(pitch * 2) * 1.3) * 0.5,
            (Saw.ar(pitch) + LFTri.ar(pitch)) * 0.25
        ]);
        // Fixed oscillator pitch; gentle filtering instead of B's snapping filter attack.
        filter=210 + (tone.clip(0,1) * 1850) + (env * (220+(tone.clip(0,1)*380)));
        body=(LPF.ar(harmonic,filter) * (1.2+(grit*2))).tanh * (0.60/(1+(grit*0.20)))
            + (SinOsc.ar(pitch) * 0.45);
        Out.ar(out, Pan2.ar(LeakDC.ar(body) * env * amp,pan));
    }),
    SynthDef(\djHook, { |out=0,freq=440,amp=0.075,sustain=0.5,color=0,tone=0.4,pan=0|
        var pitch=freq.clip(100,4000),bright=tone.clip(0,1),env,filterEnv,sig,grit,body;
        // A held, full-bodied voice: octave weight and a broad filter stay open
        // through the phrase, rather than collapsing to a short high note.
        env=EnvGen.kr(Env.linen(0.012,sustain.max(0.08),0.14,curve:-2),doneAction:2);
        filterEnv=EnvGen.kr(Env([0.65,1,0.72],[0.035,sustain.max(0.08)+0.12],[-1,-2]));
        body=(Pulse.ar(pitch*0.5,0.46+(color.clip(0,3)*0.015))*0.26)
            +(LFTri.ar(pitch*0.5)*0.12);
        sig=(Saw.ar(pitch*[0.9985,1.0015]).sum*0.22)+body;
        sig=RLPF.ar(sig,1200+(bright*1800)+(filterEnv*1200),0.82);
        // Keep the crunchy edge as a small parallel layer around a solid body.
        grit=Latch.ar((sig*3.5).tanh,Impulse.ar(18000)).round(1/128);
        sig=((sig*2).tanh*0.90)+(grit*0.10);
        sig=HPF.ar(LPF.ar(LeakDC.ar(sig),7000),90)*env*amp*0.82;
        Out.ar(out,Pan2.ar(sig,pan));
    }),
    SynthDef(\djPad, { |out=0, freq=220, amp=0.027, sustain=2, pan=0, tone=0.4|
        var env=EnvGen.kr(Env.linen(0.18,sustain.max(0.05),0.7,curve:\sin),doneAction:2);
        var sig=VarSaw.ar(freq.clip(40,4000) * [0.999,1.001],0,0.5).sum * 0.3;
        sig=LPF.ar(sig,800 + (tone.clip(0,1) * 1700));
        Out.ar(out,Pan2.ar(sig * env * amp,pan));
    }),
    SynthDef(\djArp, { |out=0, freq=220, amp=0.035, sustain=0.12, pan=0, color=0,tone=0.4|
        var env=EnvGen.kr(Env.perc(0.006,sustain.max(0.025) + 0.08),doneAction:2);
        var sig=(Saw.ar(freq.clip(50,3000))*0.50)+(LFTri.ar(freq)*0.20);
        sig=LPF.ar(sig,550+(tone.clip(0,1)*1800)+(env*1400));
        Out.ar(out,Pan2.ar(sig * env * amp,pan));
    }),
    SynthDef(\djStab,{ |out=0,freq=220,amp=0.03,sustain=0.2,pan=0,tone=0.4,color=0|
        var env=EnvGen.kr(Env.perc(0.012,sustain.max(0.04)+0.12,curve:-4),doneAction:2);
        var sig=(Pulse.ar(freq.clip(60,2500),0.43)*0.36)+(LFTri.ar(freq)*0.28);
        sig=HPF.ar(LPF.ar(sig,700+(tone.clip(0,1)*1600)),150);
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    }),
    SynthDef(\djClap,{ |out=0,amp=0.12,pan=0,seed=2600|
        var env=EnvGen.kr(Env([0,1,0.15,0.8,0.1,0.6,0],
            [0.001,0.008,0.001,0.012,0.001,0.10],-3),doneAction:2),sig;
        RandSeed.ir(1,seed);
        sig=BPF.ar(WhiteNoise.ar,1700,0.9)+(HPF.ar(WhiteNoise.ar,3200)*0.20);
        Out.ar(out,Pan2.ar(sig*env*amp*1.25,pan));
    }),
    SynthDef(\djPerc,{ |out=0,amp=0.03,sustain=0.08,pan= -0.3,seed=2600,color=0|
        var env=EnvGen.kr(Env.perc(0.001,sustain.max(0.025),curve:-5),doneAction:2),sig;
        RandSeed.ir(1,seed);
        sig=(SinOsc.ar(330+(color*70))*0.55)+(BPF.ar(WhiteNoise.ar,1700,0.5)*0.30);
        Out.ar(out,Pan2.ar(sig*env*amp,pan));
    }),
    SynthDef(\djKick, { |out=0,freq=49,amp=0.4,sustain=0.3|
        var env=EnvGen.kr(Env.perc(0.001,sustain.clip(0.12,0.45),curve:-5),doneAction:2);
        var pitch=freq.clip(42,58)*EnvGen.kr(Env([3.7,1.2,1],[0.018,0.055],[-7,-4]));
        var click=HPF.ar(WhiteNoise.ar,4500)*EnvGen.kr(Env.perc(0.001,0.008))*0.035;
        Out.ar(out,Pan2.ar(((SinOsc.ar(pitch)*1.4).tanh*env+click)*amp,0));
    }),
    SynthDef(\djSnare, { |out=0, amp=0.11, sustain=0.12, pan=0, seed=2600|
        var env=EnvGen.kr(Env.perc(0.002,sustain.max(0.03)),doneAction:2);
        var sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(LPF.ar(WhiteNoise.ar,8000),1400) * 0.7
            + (SinOsc.ar(180) * EnvGen.kr(Env.perc(0.002,0.045)) * 0.3);
        Out.ar(out,Pan2.ar(sig * env * amp,pan));
    }),
    SynthDef(\djHat, { |out=0, freq=6500, amp=0.06, sustain=0.1, pan=0, seed=2600|
        var env=EnvGen.kr(Env.perc(0.001,sustain.max(0.015)),doneAction:2);
        var sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(WhiteNoise.ar,freq.clip(4000,11000));
        Out.ar(out,Pan2.ar(sig * env * amp,pan));
    }),
    SynthDef(\djRise, { |out=0, amp=0.05, sustain=1.8, seed=2600|
        var env=EnvGen.kr(Env.linen(0.02,sustain.max(0.05),0.08),doneAction:2);
        var sweep=Line.kr(650,5500,sustain.max(0.05)), sig;
        RandSeed.ir(1,seed);
        sig=BPF.ar(PinkNoise.ar,sweep,0.5) * Line.kr(0.05,0.4,sustain.max(0.05));
        Out.ar(out,Pan2.ar(sig * env * amp,0));
    }),
    SynthDef(\djImpact,{ |out=0,amp=0.1,sustain=2,seed=2600|
        var env=EnvGen.kr(Env.perc(0.001,sustain.max(0.2),curve:-5),doneAction:2),sig;
        RandSeed.ir(1,seed);
        sig=HPF.ar(LPF.ar(WhiteNoise.ar,7500),900)*env;
        Out.ar(out,Pan2.ar(sig*amp,0));
    }),
    SynthDef(\djDeck, { |in=16,out=28,musicGain=1,bassGain=1,drumsGain=1,bpm=128,
        fxFilter=0,fxCutoff=12000,fxResonance=0.35,fxEcho=0,fxDelay=0.75,fxReverb=0.08,fxStutter=0,
        fxStutterRate=4,t_stutter=0|
        var music=In.ar(in,2),bass=In.ar(in+2,2),drums=In.ar(in+4,2);
        var smoothBpm=Lag.kr(bpm.clip(118,140),3);
        var trigger=Amplitude.kr(LPF.ar(drums.sum,150),0.001,0.105);
        var duck=1-(trigger*4.5).clip(0,0.74);
        var musicLevel=Lag.kr(musicGain,0.02),bassLevel=Lag.kr(bassGain,0.02),drumsLevel=Lag.kr(drumsGain,0.02);
        var echoSend=Lag.kr(fxEcho.clip(0,1),0.06),verbSend=Lag.kr(fxReverb.clip(0,1),0.4);
        var delay=Lag.kr(fxDelay.clip(0.08,0.75),0.5)*(60/smoothBpm);
        var filterAmount=Lag.kr(fxFilter.clip(0,1),0.06),cutoff=Lag.kr(fxCutoff.clip(500,18000),0.08);
        var stutter=Lag.kr(fxStutter.clip(0,1),0.015),phase,program,echo,verb,gate,filtered;
        // The same kick envelope pumps the bass, riff and their returns together.
        music=HPF.ar(music,115); bass=LPF.ar(bass,1800);
        program=(music*duck*musicLevel)+(bass*duck*bassLevel)+(drums*drumsLevel);
        // Sends go INTO the delays. Reducing a send allows the existing tail to decay.
        echo=LPF.ar(CombC.ar(HPF.ar(music,450)*echoSend,2,delay,3.6),4200)*0.40;
        verb=FreeVerb2.ar(music[0]*verbSend,music[1]*verbSend,1,0.73,0.65)*0.26;
        program=program+((echo+verb)*duck*musicLevel);
        filtered=RLPF.ar(program,cutoff,Lag.kr(fxResonance.clip(0.25,0.9),0.08));
        program=(program*(1-filterAmount))+(filtered*filterAmount);
        // 1/2/4 pulses per quarter-note beat; each HOT hit resets to its bar.
        phase=Phasor.kr(t_stutter,(bpm.clip(118,140)/60)*fxStutterRate.clip(1,4)*ControlDur.ir,0,1,0);
        gate=1-(stutter*(1-Lag.kr(phase<0.48,0.006)));
        Out.ar(out,LeakDC.ar(program*gate));
    }),
    SynthDef(\djMaster, { |in=28, out=0, gate=1, amp=0.92, attack=0.1,drive=3.4|
        var env=EnvGen.kr(Env.asr(attack.max(0.02),1,3),gate,doneAction:2);
        var sig=HPF.ar(LeakDC.ar(In.ar(in,2)),25);
        sig=sig*Lag.kr(drive.clip(0.5,4),0.1);
        sig=Compander.ar(sig,sig,0.48,1,0.55,0.006,0.12);
        Out.ar(out,Limiter.ar(sig,0.82) * amp * env);
    })
];
(root +/+ "palette-instruments.scd").load;
)
