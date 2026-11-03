// Read-only sound benchmark: dedicated server, hardware output muted.
(
var root=thisProcess.nowExecutingPath.dirname.dirname,server,rows=List.new,phase=nil,start=0;
var status,fail,late,failures=List.new,lates=List.new,tag,flush,groups,decks,master,group,sources,bus=16;
var measureFrom=0,rig,play,static,reportPath=Platform.defaultTempDir+/+"rock-cpu-samples.tsv";
(root+/+"engine.scd").load;(root+/+"instruments.scd").load;
(root+/+"guitar-prototypes/instruments.scd").load;
(root+/+"guitar-contact/contact.scd").load;(root+/+"guitar-contact/instruments.scd").load;
server=Server(\guitarCpu,NetAddr("127.0.0.1",57156),ServerOptions.new.numInputBusChannels_(0)
    .numOutputBusChannels_(2).sampleRate_(48000).blockSize_(64).numWireBufs_(256).memSize_(65536).loadDefs_(false));
server.latency=0.1;server.volume.mute;
status=OSCFunc({|msg|
    if(phase.notNil and:{Main.elapsedTime>=measureFrom}){
        rows.add([phase,Main.elapsedTime-start,msg[6],msg[7],msg[3],msg[2],msg[8],msg[9]]);
    };
},'/status.reply',server.addr);
fail=OSCFunc({|msg|if(msg[1]!="/d_load"){failures.add(msg)}},'/fail',server.addr);
late=OSCFunc({|msg|lates.add(msg)},'/late',server.addr);
flush={
    File.use(reportPath,"w",{|f|
        f.write("case\tseconds\taverage_cpu\tpeak_cpu\tsynths\tugens\tsample_rate\tactual_sample_rate\n");
        rows.do {|r|f.write(r.collect(_.asString).join("\t")++"\n")};
    });
};
tag={|name,warm=1|
    phase=name;start=Main.elapsedTime;measureFrom=start+warm;
    ("MEASURE / "++name).postln;
};
rig={|count=2|
    group=Group.new(server);sources=[Group.head(group),Group.head(group)];
    decks=Array.fill(count,{|i|Synth.tail(group,\rockPhysicalDeck,[\in,bus+(i*6),\out,bus+12,
        \musicGain,1,\bassGain,1,\drumsGain,1,\guitarPedal,2,\guitarDrive,0.35,\guitarComp,0.18])});
    master=Synth.tail(group,\djMaster,[\in,bus+12,\drive,1.8]);
};
play={|name,settings,bars=6,mix=false|
    var engine=~makeDJEngine.value(2600,102,settings.copy.put(\rockLeadVersion,2).put(\rockToneVersion,2)),tempo=102;
    8.do {engine[\nextBar].value};engine[\requestHook].value;
    if(mix){engine[\requestNext].value};
    rig.value(2);server.sync;tag.value(name,2.5);
    bars.do {
        var frame=engine[\nextBar].value,actions=List.new,previous=0;
        frame.automation.do {|point|actions.add((beat:point.beat,automation:point))};
        frame.events.do {|event|actions.add((beat:event.beat,note:event))};
        actions.sort {|a,b|if(a.beat==b.beat){a[\automation].notNil and:{b[\automation].isNil}}{a.beat<b.beat}}.do {|action|
            ((action.beat-previous)*60/tempo).wait;previous=action.beat;
            if(action[\automation].notNil){
                tempo=action.automation.bpm;server.sendBundle(server.latency,*~djAutomation.value(action.automation,decks.collect(_.nodeID)));
            }{
                server.sendBundle(server.latency,~djMessage.value(action.note,-1,sources[action.note.deck].nodeID,bus,tempo));
            };
        };
        ((4-previous)*60/tempo).wait;
    };
    (server.latency+0.12).wait;phase=nil;group.free;server.sync;1.5.wait;flush.value;
};
static={|name,contact=false,count=6,rigs=1|
    var voices=[[0,40],[1,47],[2,54],[3,56],[4,59],[5,64]],msgs=List.new;
    rig.value(rigs);server.sync;1.5.wait;
    count.do {|i|
        var pair=voices.wrapAt(i),out=if(rigs==0){bus+12}{if(rigs>1){bus+((i div:12)*6)}{bus}},msg;
        if(contact){
            msg=[\s_new,\rockContactGuitar,-1,0,sources[(i div:12).min(1)].nodeID,
                \out,out,\freq,pair[1].midicps,\stringIndex,pair[0],\sustain,4,\amp,0.08,\seed,731+i]
                ++~gcArgs.value(~gcInitial.value(pair[1],pair[0],\hard));
        }{
            msg=[\s_new,\rockPhysicalGuitar,-1,0,sources[(i div:12).min(1)].nodeID,
                \out,out,\freq,pair[1].midicps,\stringIndex,pair[0],\sustain,4,\amp,0.04,\seed,731+i];
        };
        msgs.add(msg);
    };
    server.sendBundle(server.latency,*msgs);tag.value(name,1.2);3.9.wait;
    phase=nil;group.free;server.sync;1.6.wait;flush.value;
};
SystemClock.sched(240,{flush.value;server.quit;1.exit;nil});
server.waitForBoot {
    Routine {
        var polling;
        try {
            ~djDefs.do {|def|def.send(server)};server.sync;
            polling=Routine {loop {server.sendMsg('/status');0.25.wait}}.play(SystemClock);
            tag.value("idle",2);6.wait;phase=nil;
            rig.value(1);server.sync;tag.value("one-deck-idle",2);6.wait;phase=nil;group.free;server.sync;1.wait;
            rig.value(2);server.sync;tag.value("two-decks-idle",2);6.wait;phase=nil;group.free;server.sync;1.wait;
            ["Rook","June","Flint"].do {|name,id|play.value("song-"++name,(channel:\rock,palette:id,hold:true),4)};
            play.value("song-handover",(channel:\rock),8,true);
            1.do {|trial|
                [[false,6,0],[false,6,1],[false,12,1],[false,24,2],[true,6,1],[true,12,1],[true,24,2]].do {|spec|
                    static.value(if(spec[2]==0){"dry-live-"}{if(spec[0]){"contact-"}{"live-"}}++spec[1]++"-voices-trial-"++trial,spec[0],spec[1],spec[2]);
                };
            };
            polling.stop;status.free;fail.free;late.free;flush.value;
            ("RESULT / "++rows.size++" samples / failures "++failures.size++" / late "++lates.size).postln;
            ("FORMAT / "++server.sampleRate++" Hz / block "++server.options.blockSize).postln;
            if(failures.notEmpty){failures.postln};
            server.quit;if(failures.isEmpty){0.exit}{1.exit};
        } {|e|e.reportError;flush.value;server.quit;1.exit};
    }.play(SystemClock);
};
)
