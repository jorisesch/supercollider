// Definitions only. Select-all playback is in audio/pod-racer.scd.
(
~podRacerDef = SynthDef(\podRacer, { |out=0, gate=1, amp=0.68, speed=0.12,
    lfoRate=0.3, lfoDepth=0.7, lfoShape=0, cutoff=320, resonance=0.24,
    noise=0.025, gear=0, flyby=0, canyon=0, clankRate=0.35, pan=0|
    var v, accel, engineHz, lfo, cv, sawPair, piston, starter, gearTrig, gearEnv;
    var gearNoise, air, grit, clankTrig, clank, flyTrig, flyEnv, flyFreq, flyPan;
    var doppler, dry, canyonSend, echo, signal, env;

    RandSeed.ir(1, 1969);
    v = LagUD.kr(speed.clip(0, 1), 0.28, 0.7);
    accel = HPZ1.kr(v).max(0).clip(0, 1) * 5;
    // The familiar mechanical pitch rises with velocity; the filter CV accelerates too.
    engineHz = v.linexp(0, 1, 38, 215) * LFNoise2.kr(0.24).range(0.985, 1.015);
    lfo = Select.kr(lfoShape.clip(0, 1), [
        LFTri.kr(lfoRate.clip(0.05, 10)),
        LFPulse.kr(lfoRate.clip(0.05, 10), 0, 0.5).range(-1, 1)
    ]);
    cv = (cutoff.clip(80, 7000) * (1 + (lfo * lfoDepth.clip(0, 1)))).clip(70, 11000);

    // Two slightly detuned saws: the coherent “vehicle” layer.
    sawPair = Saw.ar([engineHz * 0.997, engineHz * 1.003], 0.24).sum;
    sawPair = RLPF.ar(sawPair, cv, resonance.clip(0.08, 0.85));
    sawPair = sawPair + (RHPF.ar(sawPair, (cv * 0.4).clip(60, 6000), 0.7) * 0.12);

    // Twin-piston start and idle. This layer gets out of the way at racing speed.
    piston = Mix.fill(2, { |i|
        var rate, fire, lobe, exhaust, rod;
        rate = engineHz * [0.93, 1.07][i];
        fire = Impulse.ar(rate * (1 + (accel * 0.04)));
        lobe = VarSaw.ar(rate, 0, [0.31, 0.39][i], 0.18)
            + Pulse.ar(rate * 2.01, [0.15, 0.19][i], 0.08);
        exhaust = Decay2.ar(fire, 0.001, 0.04) * PinkNoise.ar(0.32);
        rod = LPF.ar(BrownNoise.ar(0.16), 90 + (v * 170));
        Pan2.ar((lobe + (exhaust * 0.22) + rod) * (1 - (v * 0.84)), [-0.4, 0.4][i]);
    });
    starter = EnvGen.kr(Env([1, 1, 0], [0.4, 4.2], [-2, -4]));
    piston = piston * (0.72 + (starter * 0.5));

    // Gear-change transition: a short burst of uneven broadband energy.
    gearTrig = Trig1.kr(HPZ1.kr(gear).max(0), 0.01);
    gearEnv = EnvGen.kr(Env([0, 1, 0.5, 0], [0.04, 0.18, 0.72], [-3, 0, -4]), gearTrig);
    gearNoise = BPF.ar(WhiteNoise.ar(0.8 ! 2),
        EnvGen.kr(Env([180, 2400, 420], [0.22, 0.78], [-3, -4]), gearTrig), 0.22)
        * gearEnv;

    // Wind and sand are supporting perspective layers, kept below the engine.
    air = BPF.ar(PinkNoise.ar(0.16 ! 2), 500 + (v * 2500), 0.75) * (0.02 + (v * 0.12));
    grit = HPF.ar(LPF.ar(PinkNoise.ar(0.22 ! 2), 1800 + (v * 1800)), 240)
        * noise.clip(0, 0.12) * (0.25 + (v * 0.7));

    // Rare panel/rod strikes: a real event with a metal tail, not a rhythmic layer.
    clankTrig = Dust2.ar(clankRate.clip(0, 2));
    clank = Ringz.ar(clankTrig * 0.012, [430, 760, 1180], [0.06, 0.08, 0.045]).sum
        + (BPF.ar(WhiteNoise.ar(0.25), 1450, 0.8)
            * Decay2.ar(clankTrig, 0.001, 0.018) * 0.22);
    clank = Pan2.ar(clank * 1.4, LFNoise1.kr(3, 0.6));

    // A slow fly-by sweep gives the passing vehicle its changing perspective.
    flyTrig = Trig1.kr(HPZ1.kr(flyby).max(0), 0.01);
    flyEnv = EnvGen.kr(Env([0, 1, 0.75, 0], [0.16, 0.42, 1.85], [-2, 0, -4]), flyTrig);
    flyFreq = EnvGen.kr(Env([110, 2300, 360], [0.4, 2.4], [-3, -4]), flyTrig);
    flyPan = EnvGen.kr(Env([-1, 1, 0], [0.45, 1.9], [-2, -2]), flyTrig);
    doppler = Pan2.ar(BPF.ar(WhiteNoise.ar(0.35), flyFreq, 0.19) * flyEnv * (0.16 + (v * 0.18)), flyPan);

    dry = sawPair + piston + (gearNoise * 0.7) + air + grit + clank + doppler;
    // Only the pass and gear transient feed the canyon: fading low wall-whomps.
    canyonSend = ((piston * 0.08) + gearNoise + (doppler * 0.8)) * Lag.kr(canyon.clip(0, 1), 0.3);
    echo = CombC.ar(canyonSend, 1.2, [0.34, 0.53], 2.7, 0.5)
        + CombC.ar(canyonSend.reverse, 1.2, [0.71, 0.89], 2.1, 0.32);
    echo = LPF.ar(echo, 2600);
    signal = dry + echo;
    signal = Balance2.ar(signal[0], signal[1], Lag.kr(pan.clip(-1, 1), 0.25));
    env = EnvGen.kr(Env.asr(0.18, 1, 2.2), gate, doneAction: 2);
    Out.ar(out, Limiter.ar(LeakDC.ar(signal).tanh * amp * env, 0.88));
});
)
