// Definitions only: eight logical lanes across two decks; stock UGens throughout.
(
~djDefs=[
    SynthDef(\djBass, { |out=0, freq=65, amp=0.19, sustain=0.25, color=0, tone=0.4, pan=0|
        var env=EnvGen.kr(Env([0,1,0.78,0], [0.012,0.055,sustain.max(0.07)], [-2,-2,-4]), doneAction:2);
        var pitch=freq.clip(25,400), body, harmonic, filter;
        harmonic=Select.ar(color.clip(0,3), [
            Saw.ar(pitch) * 0.5, Pulse.ar(pitch,0.42) * 0.4,
            SinOsc.ar(pitch, SinOsc.ar(pitch * 2) * 1.3) * 0.5,
            (Saw.ar(pitch) + LFTri.ar(pitch)) * 0.25
        ]);
        // Fixed oscillator pitch; gentle filtering instead of B's snapping filter attack.
        filter=650 + (tone.clip(0,1) * 1400) + (env * 450);
        body=(LPF.ar(harmonic,filter) * 1.6).tanh * 0.6 + (SinOsc.ar(pitch) * 0.45);
        Out.ar(out, Pan2.ar(LeakDC.ar(body) * env * amp,pan));
    }),
    SynthDef(\djHook, { |out=0, freq=440, amp=0.075, sustain=0.3, color=0, tone=0.4, pan=0|
        var env=EnvGen.kr(Env.perc(0.014,sustain.max(0.06) + 0.25,curve:-3),doneAction:2);
        var pitch=freq.clip(60,6000), sig;
        sig=Select.ar(color.clip(0,3), [
            VarSaw.ar(pitch * [0.998,1.002],0,0.4).sum * 0.3,
            SinOsc.ar(pitch, SinOsc.ar(pitch * 2) * env * 0.9),
            Pulse.ar(pitch,0.35) * 0.45,
            SinOsc.ar(pitch) * 0.7 + Saw.ar(pitch) * 0.15
        ]);
        sig=LPF.ar(sig,1000 + (tone.clip(0,1) * 4000) + (env * 1300));
        Out.ar(out,Pan2.ar(sig * env * amp,pan));
    }),
    SynthDef(\djPad, { |out=0, freq=220, amp=0.027, sustain=2, pan=0, tone=0.4|
        var env=EnvGen.kr(Env.linen(0.18,sustain.max(0.05),0.7,curve:\sin),doneAction:2);
        var sig=VarSaw.ar(freq.clip(40,4000) * [0.998,1.002],0,0.5).sum * 0.3;
        sig=LPF.ar(sig,800 + (tone.clip(0,1) * 1700));
        Out.ar(out,Pan2.ar(sig * env * amp,pan));
    }),
    SynthDef(\djArp, { |out=0, freq=220, amp=0.035, sustain=0.12, pan=0, color=0|
        var env=EnvGen.kr(Env.perc(0.006,sustain.max(0.025) + 0.08),doneAction:2);
        var sig=SinOsc.ar(freq.clip(50,7000),SinOsc.ar(freq * 2) * env * (0.4 + color.clip(0,3) * 0.2));
        Out.ar(out,Pan2.ar(sig * env * amp,pan));
    }),
    SynthDef(\djKick, { |out=0, freq=49, amp=0.4, sustain=0.3|
        var env=EnvGen.kr(Env.perc(0.002,sustain.max(0.1),curve:-4),doneAction:2);
        var pitch=freq.clip(35,75) * EnvGen.kr(Env([2.6,1.1,1],[0.025,0.1],[-4,-3]));
        var sig=(SinOsc.ar(pitch) * 1.2).tanh * env * amp;
        Out.ar(out,Pan2.ar(sig,0));
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
    SynthDef(\djDeck, { |in=16, out=28, musicGain=1, bassGain=1, drumsGain=1, bpm=128|
        var music=In.ar(in,2), bass=In.ar(in+2,2), drums=In.ar(in+4,2);
        var duck=1 - (Amplitude.kr(LPF.ar(drums.sum,180),0.004,0.18) * 3.5).clip(0,0.5);
        var delay=[0.75,1] * (60 / Lag.kr(bpm.clip(118,140),3)), echo, wet;
        echo=LPF.ar(CombC.ar(HPF.ar(music,400),2,delay,1.4),3200) * 0.12;
        wet=FreeVerb2.ar(music[0] + echo[0],music[1] + echo[1],0.18,0.78,0.6);
        // Post-FX gains mute the outgoing key's reverb as well as its dry notes.
        Out.ar(out,(wet * Lag.kr(musicGain,0.015) * (0.85 + duck * 0.15))
            + (bass * duck * Lag.kr(bassGain,0.015)) + (drums * Lag.kr(drumsGain,0.015)));
    }),
    SynthDef(\djMaster, { |in=28, out=0, gate=1, amp=0.85, attack=0.1|
        var env=EnvGen.kr(Env.asr(attack.max(0.02),1,3),gate,doneAction:2);
        var sig=HPF.ar(LeakDC.ar(In.ar(in,2)),25);
        Out.ar(out,Limiter.ar(sig,0.82) * amp * env);
    })
];
)
