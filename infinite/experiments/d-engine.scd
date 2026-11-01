// EDM D: syncopated, vibrato-led progression with a light supporting texture.
// Load after live.scd. This file only replaces the composition adapter and
// message adapter; it does not start playback.
(
var factory=~makeExperimentEngine, adapter=~experimentMessage;
var dVoices=[\xdBass, \xdLead, \xdArp, \xdPad, \xdKick, \xdSnare, \xdHat,
    \xdGhost, \xdClap, \xdOpenHat];

~makeDExperimentEngine={ |mode=\edm, seed=2600, settings|
    var base=factory.value(mode, seed, settings), next=base[\nextBar];
    var bar=0, randomState=(seed.abs % 2147483646) + 1, random, choose;
    var engine;
    if(mode != \edm) { Error("EDM D only supports \\edm mode").throw };
    random={ randomState=(randomState * 48271) % 2147483647; randomState / 2147483647 };
    choose={ |items| items[(random.value * items.size).floor.asInteger] };
    engine=base.copy;
    engine.profile=\d;
    engine[\nextBar]={
        var events=next.value, density=engine.controls.density.clip(0, 1);
        var chaos=engine.controls.chaos.clip(0, 1), tension=engine.controls.tension.clip(0, 1);
        var position=bar % 64, bass, arp, snare, pad, source, extra, slot;

        // Retain A's phrase and harmony, but give each musical lane its own D voice.
        events.do { |event|
            var step=(event.beat * 4).round.asInteger;
            if(event.voice == \xpBass) {
                event.voice=\xdBass;
                event[\accent]=if((step % 8) == 0, 1, 0.52);
                event[\cutoff]=(250 + (event.tone * 750) + (tension * 380)).clip(160, 1800);
                event.duration=if((step % 8) == 0, 0.28, 0.17);
                event.amp=event.amp * 0.96;
            };
            if(event.voice == \xpPluck) {
                event.voice=\xdLead;
                event[\accent]=if(step == 0, 0.9, 0.55);
                event[\vibDepth]=(0.0012 + (tension * 0.0032)).clip(0.001, 0.006);
                event[\vibRate]=(4.6 + (chaos * 1.8)).clip(3.5, 8);
                event[\vibDelay]=0.10 + (random.value * 0.08);
                event[\cutoff]=(1500 + (tension * 2600)).clip(1200, 5200);
                event.duration=if(step == 0, 0.42, 0.24);
                event.amp=event.amp * 1.12;
            };
            if(event.voice == \xpArp) {
                event.voice=\xdArp;
                event[\accent]=if(step.odd, 0.82, 0.48);
                event[\cutoff]=(900 + (tension * 2600)).clip(700, 4200);
                event.duration=0.16;
                event.amp=event.amp * 1.05;
            };
            if(event.voice == \xpChord) {
                event.voice=\xdPad;
                event[\cutoff]=(650 + (tension * 1700)).clip(500, 2800);
                event[\accent]=0.35 + (tension * 0.3);
                event.amp=event.amp * 0.86;
            };
            if(event.voice == \igKick) {
                event.voice=\xdKick;
                event[\accent]=if(step == 0, 1, 0.75);
                event.amp=event.amp * 0.94;
            };
            if(event.voice == \igSnare) {
                event.voice=\xdSnare;
                event[\accent]=if(step == 12, 0.9, 0.75);
            };
            if(event.voice == \igHat) {
                event.voice=\xdHat;
                event[\accent]=if(step.even, 0.72, 0.45);
                event.amp=event.amp * 0.82;
            };
        };

        bass=events.select { |event| event.voice == \xdBass };
        arp=events.select { |event| event.voice == \xdArp };
        snare=events.select { |event| event.voice == \xdSnare };
        pad=events.select { |event| event.voice == \xdPad };

        // Offbeat roots/fifths create syncopation without changing A's harmony.
        if((density >= 0.42) and: { bass.notEmpty } and: {
            random.value < (0.28 + (density * 0.32))
        }) {
            slot=choose.value(if(position.even, [3, 7], [7, 11, 15]));
            if(bass.any { |event| (event.beat - (slot * 0.25)).abs < 0.01 }.not) {
                source=choose.value(bass).copy;
                source.beat=slot * 0.25;
                source.duration=0.13;
                source.amp=(0.075 + (density * 0.035)).clip(0.07, 0.12);
                source[\accent]=0.34;
                events.add(source);
            };
        };

        // A short turnaround on the last beat makes the phrase answer itself.
        if((position % 8) == 7 and: { density >= 0.48 } and: { arp.notEmpty } and: {
            random.value < (0.48 + (chaos * 0.28))
        }) {
            3.do { |i|
                extra=arp.wrapAt(i).copy;
                extra.beat=3.25 + (i * 0.25);
                extra.duration=0.09;
                extra.amp=0.028 + (density * 0.016);
                extra[\accent]=0.82;
                events.add(extra);
            };
        };

        // Ghost notes, a restrained clap layer, and occasional open hats enrich the grid.
        if((density >= 0.38) and: { snare.notEmpty }) {
            [3, 11].do { |ghostStep|
                if(random.value < (0.18 + (density * 0.32))) {
                    extra=choose.value(snare).copy;
                    extra.voice=\xdGhost;
                    extra.beat=ghostStep * 0.25;
                    extra.duration=0.08;
                    extra.amp=(0.025 + (density * 0.018)).clip(0.02, 0.05);
                    extra[\accent]=0.28;
                    events.add(extra);
                };
            };
            snare.do { |hit|
                if(random.value < (0.35 + (density * 0.28))) {
                    extra=hit.copy;
                    extra.voice=\xdClap;
                    extra.duration=0.11;
                    extra.amp=hit.amp * 0.32;
                    events.add(extra);
                };
            };
        };
        if((density >= 0.52) and: { random.value < (0.35 + (tension * 0.25)) }) {
            [6, 14].do { |openStep|
                if(random.value < 0.58) {
                    source=events.detect { |event| event.voice == \xdHat };
                    if(source.notNil) {
                        extra=source.copy;
                        extra.voice=\xdOpenHat;
                        extra.beat=openStep * 0.25;
                        extra.duration=0.20;
                        extra.amp=0.035 + (density * 0.018);
                        extra[\accent]=0.62;
                        events.add(extra);
                    };
                };
            };
        };

        // One quiet, moving pad tone every four bars keeps the added track supportive.
        if((position % 4) == 0 and: { pad.notEmpty }) {
            extra=pad.first.copy;
            extra.beat=0;
            extra.duration=3.8;
            extra.amp=(0.018 + (tension * 0.012)).clip(0.016, 0.032);
            extra.attack=0.22;
            extra.release=0.8;
            extra[\cutoff]=(700 + (tension * 1300)).clip(600, 2400);
            events.add(extra);
        };

        events=events.sort { |a, b| a.beat < b.beat };
        bar=bar + 1;
        events;
    };
    engine;
};

// The entry point uses the same live runner and master as A, but dispatches to D.
~makeStandardExperimentEngine=~makeExperimentEngine;
~makeExperimentEngine={ |mode=\edm, seed=2600, settings|
    if(mode == \edm) { ~makeDExperimentEngine.value(mode, seed, settings) }
        { ~makeStandardExperimentEngine.value(mode, seed, settings) };
};

// Pass D-only controls without changing the message shape for A, ambient, or B.
~experimentMessage={ |event, engine, node, group, bus|
    var message=adapter.value(event, engine, node, group, bus);
    if(dVoices.includes(event.voice)) {
        message=message ++ [\accent, event[\accent] ? 0.5,
            \cutoff, event[\cutoff] ? 1200,
            \vibDepth, event[\vibDepth] ? 0.002,
            \vibRate, event[\vibRate] ? 5,
            \vibDelay, event[\vibDelay] ? 0.12];
    };
    message;
};
)
