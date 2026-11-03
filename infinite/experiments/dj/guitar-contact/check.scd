(
var root=thisProcess.nowExecutingPath.dirname,dj=root.dirname,assert={|ok,msg|if(ok.not){Error(msg).throw}};
try {
    var oldMotion,oldDefs,studies,count=0,hard,thin;
    (dj+/+"instruments.scd").load;oldMotion=~djStringMotion;oldDefs=~djDefs.collect {|d|[d.name,d.asBytes]};
    (dj+/+"guitar-prototypes/instruments.scd").load;(dj+/+"guitar-prototypes/gestures.scd").load;
    (root+/+"contact.scd").load;(root+/+"performance.scd").load;(root+/+"instruments.scd").load;
    hard=~gcInitial.value(67,4,\hard);thin=~gcInitial.value(67,4,\flexible);
    assert.value((hard[\pickStiffness]/thin[\pickStiffness]-8).abs<1e-8,"Thickness no longer changes beam stiffness cubically");
    (0..5).do {|string|[\hard,\angled,\flexible,\flesh,\nail].do {|material|
        [0.65,1.5,3.2].do {|speed|[0.0002,0.00042,0.0008].do {|depth|
            var note=[40,45,50,55,59,64][string]+7,c=~gcInitial.value(note,string,material,depth,speed);
            assert.value(c[\displacement]>0 and:{c[\displacement]<depth},"Contact creates displacement without hand travel");
            assert.value((c[\pickStiffness]*(depth-c[\displacement])-c[\force]).abs<1e-7,"Pick/string force equilibrium lost");
            assert.value(c[\releaseSeconds].inclusivelyBetween(1e-6,0.01),"Unbounded release time");
            assert.value(c[\q].size==40 and:{c[\q].every {|v|v.abs<0.002}},"Invalid modal initial condition");
            assert.value(c[\energyDelta].inclusivelyBetween(0,5),"Unbounded pluck-induced tension");count=count+1;
        }};
    }};
    [\down,\up,\simultaneous].do {|direction|
        var events=~gcStroke.value(~gcVoicings[\em],0.1,direction),strings=events.collect {|e|e[\string]},times=events.collect {|e|e[\at]};
        assert.value(strings==if(direction==\up){[5,4,3,2,1,0]}{[0,1,2,3,4,5]},"Wrong physical string order");
        if(direction==\simultaneous){assert.value(times.asSet.size==1,"Control chord is not simultaneous")}{
            assert.value(times==times.sort and:{(times.last-times.first).inclusivelyBetween(0.03,0.04)},"Sweep timing ignores string spacing/speed")};
    };
    studies=~gcBuildStudies.value;
    studies[\doubles].clump(2).do {|pair|
        assert.value(pair.size==2 and:{pair[0][\string]!=pair[1][\string]},"Double stop shares one string");
        if(pair.any {|e|e[\gesture].notNil}){assert.value(pair.count {|e|e[\gesture].notNil}==1,"Oblique bend also bends the held partner")};
    };
    assert.value(~djStringMotion==oldMotion,"Contact experiment replaced accepted motion");
    oldDefs.do {|old|assert.value(~djDefs.detect {|d|d.name==old[0]}.asBytes==old[1],"Contact experiment changed a live definition")};
    ~djDefs.do {|d|assert.value(d.asBytes.size<65000,"Oversized OSC definition")};
    ("PASS: "++count++" contact states; force equilibrium, cubic pick stiffness, finite modal energy, physical sweep order, separate double-stop strings and unchanged accepted definitions").postln;
    0.exit;
} {|e|e.reportError;1.exit};
)
