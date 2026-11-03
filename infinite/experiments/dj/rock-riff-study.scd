// Offline A/B of the current Riff and a melody-led phrase over the same backing.
(
var root = thisProcess.nowExecutingPath.dirname;
var repo = root.dirname.dirname.dirname;
var score = List.new, frames, harmony, engine, pitches, motif, answer, target, run, leads;
var tempo = 102, beatSeconds = 60 / 102, entry = 0.1, sectionSeconds = 14, duration = 28;
var node = 2000, osc = Platform.defaultTempDir +/+ "rock-riff-study.osc";
var opens = [40, 45, 50, 55, 59, 64], nearest, makeLead;
try {
    (root +/+ "engine.scd").load;
    (root +/+ "instruments.scd").load;
    TempoClock.default.tempo = 1;
    engine = ~makeDJEngine.value(2600, tempo, (channel: \rock, palette: 1, hold: true, rockLeadVersion: 1, rockToneVersion: 2,
        tonality: \aeolian, autoStutter: false));
    8.do { engine[\nextBar].value };
    {
        var plan = engine.state.decks[0];
        var position = plan.position;
        var advance = (0..15).detect { |offset|
            var start = position + offset;
            plan.schedule.wrapAt(start).degree != plan.schedule.wrapAt(start+1).degree
                and: { (start+3) < plan.schedule.size };
        };
        if(advance.isNil) { Error("No chord change found for the riff study").throw };
        advance.do { engine[\nextBar].value };
    }.value;
    engine[\requestHook].value;
    harmony = Array.newClear(4);
    frames = Array.fill(4, { |bar|
        var frame = engine[\nextBar].value, plan = frame.decks[0];
        var degree = plan.schedule[plan.localBar].degree;
        harmony[bar] = [0, 2, 4].collect { |offset| (plan.key + plan.scale.wrapAt(degree+offset)) % 12 };
        if(bar == 0) {
            pitches = (57..84).select { |note| plan.scale.includes((note-plan.key) % 12) };
        };
        (events: frame.events, automation: frame.automation);
    });
    nearest = { |notes, goal| notes.sort { |a,b| (a-goal).abs < (b-goal).abs }.first };
    {
        var first = nearest.value(pitches.select { |note| (note%12) == harmony[0][0] }, 67);
        var index = pitches.indexOf(first), shifts;
        motif = [-1, 2, 0].collect { |offset| pitches[index+offset] };
        shifts = (-7..7).select { |shift|
            motif.every { |note| pitches.includes(note+shift) }
                and: { harmony[1].includes((motif.last+shift)%12) };
        };
        if(shifts.notEmpty) {
            answer = motif + nearest.value(shifts, 0);
        } {
            var landing = nearest.value(pitches.select { |note| harmony[1].includes(note%12) }, motif.last);
            answer = [-1, 2, 0].collect { |offset| pitches[pitches.indexOf(landing)+offset] };
        };
    }.value;
    target = nearest.value(pitches.select { |note| (note%12) == harmony[3][0] }, 76);
    run = pitches.copyRange(pitches.indexOf(target)-5, pitches.indexOf(target)-1);
    leads = [
        [[0.22, 0.30, motif[0]], [0.78, 0.34, motif[1]], [1.48, 1.25, motif[2]]],
        [[0.22, 0.30, answer[0]], [0.78, 0.34, answer[1]], [1.48, 1.25, answer[2]]],
        run.collect { |note,i| [1.75+(i*0.25), 0.20, note] },
        [[0.24, 0.40, run.last], [1.24, 2.45, target]]
    ];
    makeLead = { |bar|
        var template = frames[bar].events.detect { |event| event.role == \djHook };
        leads[bar].collect { |note,i|
            var event = template.copy, landing = (bar == 3) and: { i == 1 };
            var startNote = note[2] - if(landing) { 1 } { 0 };
            var strings = (0..5).select { |string| (startNote-opens[string]).inclusivelyBetween(1, 22) };
            event.beat = note[0];
            event.duration = note[1];
            event.midinote = note[2];
            event.fromNote = note[2];
            event.stringIndex = strings.sort { |a,b| (startNote-opens[a]-7).abs < (startNote-opens[b]-7).abs }.first;
            event.slideBeats = 0;
            event.articulation = 0;
            event.bendSemis = if(landing) { 1 } { 0 };
            event.bendMode = if(landing) { 2 } { 0 };
            event.vibrato = if(landing) { 0.13 } { if(note[1] > 1) { 0.10 } { 0 } };
            event.seed = template.seed + i;
            if(event.stringIndex.isNil) { Error("Unplayable study note").throw };
            event;
        };
    };
    if(harmony[0] == harmony[1] or: { harmony[1].includes(answer.last%12).not }
        or: { harmony[3].includes(target%12).not }) { Error("Study lost its harmonic targets").throw };
    ["Rock riff study", harmony, motif, answer, run, target].postln;
    ~djDefs.do { |def| score.add([0, [\d_recv,def.asBytes]]) };
    2.do { |take|
        var offset = take*sectionSeconds, group = 100+take, source = 110+take;
        var decks = [800+(take*2), 801+(take*2)], master = 900+take, mix = ~djMixSpec.value(\rock,2);
        var end = offset+entry+(16*beatSeconds);
        score.add([offset+0.01, [\g_new,group,0,1], [\g_new,source,0,group],
            [\s_new,mix.deck,decks[0],1,group,\in,16,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,tempo],
            [\s_new,mix.deck,decks[1],1,group,\in,22,\out,28,\musicGain,0,\bassGain,0,\drumsGain,0,\bpm,tempo],
            [\s_new,\djMaster,master,1,group,\in,28,\drive,mix.drive]]);
        frames.do { |frame,bar|
            var at = offset+entry+(bar*4*beatSeconds);
            var events = if(take == 0) { frame.events } {
                frame.events.reject { |event| event.role == \djHook } ++ makeLead.value(bar)
            };
            frame.automation.do { |point|
                score.add([at+(point.beat*beatSeconds)] ++ ~djAutomation.value(point,decks));
            };
            events.do { |event|
                score.add([at+(event.beat*beatSeconds), ~djMessage.value(event,node,source,16,tempo)]);
                node = node+1;
            };
        };
        score.add([end+0.01, [\n_set,master,\gate,0]]);
        score.add([end+3.5, [\n_free,group]]);
    };
    score.add([duration,[\c_set,0,0]]);
    Score(score.asArray.sort { |a,b| a[0]<b[0] }).recordNRT(oscFilePath: osc,
        outputFilePath: repo +/+ "audio/rock-riff-study.wav", sampleRate: 48000,
        headerFormat: "WAV", sampleFormat: "int24", duration: duration,
        options: ServerOptions.new.numInputBusChannels_(0).numOutputBusChannels_(2)
            .numWireBufs_(128).memSize_(65536).loadDefs_(false),
        action: { |code| File.delete(osc); code.exit });
} { |error| error.reportError; 1.exit };
)
