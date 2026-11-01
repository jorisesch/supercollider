(
~neonBpm=138;
~neonDuration=0.1+(48*4*60/~neonBpm)+4;
~neonScore = {
    var events=List.new, id=1000, beat=60/~neonBpm;
    var roots=[45,41,48,43]; // A minor, F, C, G
    var hook=[0,0,7,12,10,7,3,7, 0,3,7,10,7,3,2,7];
    var add={ |b,name,args| events.add([0.1+(b*beat),[\s_new,name,id,0,0,\out,16]++args]); id=id+1; };
    events.add([0]++~neonDefs.collect { |def| [\d_recv,def.asBytes] });
    events.add([0.01,[\s_new,\neonMaster,900,1,0]]);
    48.do { |bar|
        var root=roots[(bar div:2)%4];
        var breakdown=(bar>=16) and:{bar<24};
        var full=(bar>=8) and:{bar<40};
        if(breakdown.not or:{bar>=22}) {
            4.do { |i| if((bar!=23) or:{i<2}) { add.value(bar*4+i,\neonKick,[\amp,0.62]); } };
        };
        if(breakdown.not) {
            8.do { |i| add.value(bar*4+(i*0.5)+0.25,\neonHat,[\amp,0.07,\pan,if(i.even){-0.25}{0.25}]); };
            4.do { |i| add.value(bar*4+i+0.5,\neonHat,[\amp,0.10,\dur,0.15]); };
            [1,3].do { |i| add.value(bar*4+i,\neonClap,[\amp,0.32]); };
            8.do { |i| add.value(bar*4+(i*0.5)+0.5,\neonBass,[\freq,(root-12+if(i%4==3){12}{0}).midicps,\amp,0.23]); };
        };
        if(bar>=4 and:{bar<44}) {
            [0,3,7].do { |n| add.value(bar*4,\neonPad,[\freq,(root+12+n).midicps,\dur,beat*3.3,\amp,if(breakdown){0.14}{0.065}]); };
        };
        if(full and:{breakdown.not}) {
            16.do { |i|
                if((i%8!=7) and:{(bar!=23)}) {
                    add.value(bar*4+(i*0.25),\neonLead,[\freq,(69+hook[(i+(bar%2*8))%16]+if(bar%8>=4){-2}{0}).midicps,\amp,0.115,\bright,if(bar<16){4200}{6800},\pan,0.12]);
                };
            };
        };
        if(breakdown and:{bar<22}) {
            [0,1.5,3].do { |i| add.value(bar*4+i,\neonLead,[\freq,(root+24+7).midicps,\dur,0.4,\amp,0.09,\bright,2400]); };
        };
        if([6,22,30].includes(bar)) { add.value(bar*4,\neonRise,[\dur,beat*8,\amp,0.13]); };
        if([15,23,31,39].includes(bar)) {
            8.do { |i| add.value(bar*4+2+(i*0.25),\neonClap,[\amp,0.12+(i*0.018)]); };
        };
    };
    events.add([~neonDuration,[\c_set,0,0]]);
    events.asArray.sort { |a,b| a[0]<b[0] };
};
)
