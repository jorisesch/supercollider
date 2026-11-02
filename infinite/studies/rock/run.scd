// Terminal playback, once through the arrangement. Args: ironwood|greenroom|openroad.
(
var root=thisProcess.nowExecutingPath.dirname,id=(thisProcess.argv.at(0) ? "ironwood").asSymbol;
var spec,server;
(root+/+"live.scd").load;
spec=~rockSpecs.detect {|item|item.id==id};
if(spec.isNil){"Choose ironwood, greenroom or openroad".postln;1.exit};
server=Server(\rockBacking,NetAddr("127.0.0.1",57146),ServerOptions.new
    .numInputBusChannels_(0).numOutputBusChannels_(2).numWireBufs_(128).memSize_(65536).loadDefs_(false));
server.waitForBoot({
    ~rockPlay.value(id,server,thisProcess.argv.includesEqual("nofx").not);
    SystemClock.sched((128*60/spec.bpm)+6,{server.quit;0.exit;nil});
},onFailure:{1.exit});
"Ctrl+C stops this terminal session. The arrangement otherwise ends automatically.".postln;
)
