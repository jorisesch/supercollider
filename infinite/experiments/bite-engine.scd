// Load after launch.scd/live.scd. Adapts A's notes; no new track or playback.
(
var factory=~makeExperimentEngine, adapter=~experimentMessage;
~makeBiteEngine={ |mode=\edm, seed=2600, settings|
    var engine=factory.value(mode, seed, settings), next=engine[\nextBar];
    if((mode == \edm) and: { engine[\profile] != \bite }) {
        engine.profile=\bite; engine.masterSynth=\xbMaster; engine.busChannels=6;
        engine[\nextBar]={
            var events=next.value, bass=events.select { |event| event.track == 0 }, pickup;
            events.do { |event|
                var step=(event.beat * 4).round.asInteger;
                if(event.track == 0) {
                    event.voice=\xbBass;
                    event.accent=if((step % 4) == 0, 1, 0.35);
                    event.duration=if((step % 4) == 0, 0.30, 0.19);
                    event.tone=(0.45 + (event.tone * 0.4) + (event.accent * 0.12)).clip(0, 1);
                    event.amp=event.amp * 0.92;
                };
                if(event.voice == \igKick) { event.voice=\xbKick; event.amp=event.amp * 0.9 };
                if(event.voice == \igSnare) { event.voice=\xbSnare };
                if(event.voice == \xpChord) { event.amp=event.amp * 0.55; event.duration=event.duration * 0.65 };
                if(event.voice == \xpPluck) { event.amp=event.amp * 0.85 };
            };
            // A quiet final sixteenth answers the remembered phrase, then resolves.
            // Keep density's existing extra notes if that slot is already occupied.
            if(engine.state.bar.odd and: { engine.controls.density >= 0.4 } and: { bass.notEmpty }
                and: { bass.any { |event| (event.beat - 3.75).abs < 0.01 }.not }) {
                pickup=bass.last.copy;
                pickup.beat=3.75; pickup.midinote=engine.state.chord[0];
                pickup.duration=0.14; pickup.amp=0.10; pickup.accent=0.25;
                events=events.add(pickup);
            };
            events.sort { |a, b| a.beat < b.beat };
        };
    };
    engine;
};
~makeExperimentEngine=~makeBiteEngine;
~experimentMessage={ |event, engine, node, group, bus|
    var message=adapter.value(event, engine, node, group, bus);
    if(engine[\profile] == \bite) {
        // Six buses: music L/R, drums L/R, dry bass L/R.
        if(event.track == 0) { message[6]=bus + 4 };
        message=message ++ [\accent, event[\accent] ? 0.5];
    };
    message;
};
)
