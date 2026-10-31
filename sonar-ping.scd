// Definition only. Select-all playback is in audio/sonar-ping.scd.
(
~sonarPingDef = SynthDef(\sonarPing, { |out=0, gate=1, amp=0.62, freq=960,
    decay=4.2, reverb=0.42, water=0.14, hull=0.34, creakRate=0.28, pan=0|
    var hullEnv, pingEnv, strikeEnv, overall, pingHz, hullHz;
    var projected, hullTone, hullRes, strike, metal, direct;
    var returnA, returnB, returnC, returns, waterBed, creakTrig, creaks;
    var verb, signal;

    // The emitter is a mid-band ping; the body below it is the submarine structure.
    hullEnv = EnvGen.ar(Env([0, 1, 0.62, 0], [0.006, 0.08, 0.72], [-4, -2, -5]));
    pingEnv = EnvGen.ar(Env([0, 1, 0.68, 0], [0.002, 0.075, 0.72], [-5, -2, -5]));
    strikeEnv = EnvGen.ar(Env.perc(0.0004, 0.024, 1, -7));
    overall = EnvGen.ar(
        Env([0, 1, 1, 0], [0.008, decay + 1.6, 1.6], [-4, 0, -5]),
        gate, doneAction: 2
    );

    pingHz = XLine.kr(freq.clip(500, 2200) * 1.06,
        freq.clip(500, 2200) * 0.88, 0.28);
    projected = (SinOsc.ar(pingHz) * 0.42)
        + (SinOsc.ar(pingHz * 2.01) * 0.07)
        + (SinOsc.ar(pingHz * 3.02) * 0.022);
    projected = projected * pingEnv;

    hullHz = XLine.kr(245, 175, 0.36);
    hullTone = (SinOsc.ar(hullHz) * 0.3)
        + (SinOsc.ar(hullHz * 1.47) * 0.09)
        + BPF.ar(BrownNoise.ar(0.28), hullHz * 1.7, 0.7);
    hullRes = Mix(Ringz.ar(hullEnv * 0.22,
        [hullHz, hullHz * 1.47, hullHz * 2.05], [1.7, 1.0, 0.55])) * 0.58;
    hullTone = (hullTone + hullRes) * hull.clip(0, 1);

    // A narrow, hard attack gives the ping a physical striker/transducer edge.
    strike = BPF.ar(WhiteNoise.ar(0.38), (freq * 2.9).clip(2200, 7000), 0.24)
        * strikeEnv;
    metal = Mix(Ringz.ar((strikeEnv * 0.2) + (pingEnv * 0.08),
        [freq * 1.7, freq * 2.6], [0.8, 0.45])) * 0.14;
    direct = projected + hullTone + strike + metal;

    // Returns are separate paths: each is darker and quieter than the direct ping.
    returnA = LPF.ar(DelayC.ar(direct * 0.34, 1.8, 0.43), 1500);
    returnB = LPF.ar(DelayC.ar(direct * 0.22, 1.8, 0.89), 820);
    returnC = LPF.ar(DelayC.ar(direct * 0.13, 1.8, 1.53), 460);
    returns = returnA + returnB + returnC;

    // Almost inaudible water movement and rare structural creaks prevent a sterile tail.
    waterBed = (LPF.ar(BrownNoise.ar(0.1), 130)
        + BPF.ar(PinkNoise.ar(0.035), 300, 1.1))
        * water.clip(0, 0.8) * LFNoise2.kr(0.17).range(0.72, 1);
    creakTrig = Dust2.ar(creakRate.clip(0, 1));
    creaks = Ringz.ar(creakTrig * 0.012, [125, 210, 355], [0.9, 0.6, 0.32]).sum
        + (BPF.ar(WhiteNoise.ar(0.18), 520, 0.7)
            * Decay2.ar(creakTrig, 0.001, 0.035) * 0.2);
    creaks = Pan2.ar(creaks, LFNoise1.kr(0.7, 0.65));

    verb = FreeVerb.ar((direct + returns) ! 2,
        reverb.clip(0, 1), 0.94, 0.2) * 0.28;
    signal = LeakDC.ar((direct ! 2) + (returns ! 2) + verb
        + (waterBed ! 2) + creaks);
    signal = Balance2.ar(signal[0], signal[1], Lag.kr(pan.clip(-1, 1), 0.15));
    Out.ar(out, Limiter.ar(signal.tanh * amp * overall, 0.88));
});
)
