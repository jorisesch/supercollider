// Small-signal, finite-aperture pickup model. All geometry is measured from
// the bridge in metres. Component values are illustrative, not brand fits.
(
~hpHardware=(
    single:(resistance:6200,inductance:2.5,capacitance:80e-12,loss:300000,gain:1,spacing:0,width:0.006),
    vintage:(resistance:3800,inductance:1.9,capacitance:110e-12,loss:220000,gain:0.72,spacing:0.018,width:0.006),
    hot:(resistance:6300,inductance:3.8,capacitance:150e-12,loss:185000,gain:1.05,spacing:0.018,width:0.006)
);
~hpConfig={|family=\vintage,wiring=\series,center=0.045,cable=470e-12,toneR=500000,balance=1,coupling=0|
    var hw=~hpHardware[family],gains,centers,wires,magnets,r,l,c,hum=0;
    var ratio=balance.clip(0.8,1.2),k=coupling.clip(-0.3,0.3),mode=if(family==\single){\single}{wiring};
    if(hw.isNil){Error("Unknown pickup family").throw};
    center=center.clip(0.015,0.17);
    gains=[hw[\gain],hw[\gain]*ratio];centers=[center-(hw[\spacing]/2),center+(hw[\spacing]/2)];
    magnets=[1,-1];r=hw[\resistance];l=hw[\inductance];c=hw[\capacitance];
    switch(mode,
        \single,{wires=[1,0]},
        \split,{wires=[1,0]},
        \series,{wires=[1,-1];r=r*(1+ratio);l=l*(1+ratio.squared+(2*k*ratio));c=c/(1+ratio)},
        \parallel,{
            if((ratio-1).abs>1e-9){Error("Parallel prototype requires matched coils").throw};
            wires=[0.5,-0.5];r=r*0.5;l=l*(1+k)*0.5;c=c*2;
        },{Error("Unknown pickup wiring").throw});
    wires.do {|sign,i|hum=hum+(sign*gains[i])};
    (family:family,wiring:mode,centers:centers,width:hw[\width],weights:gains*wires*magnets,
        hum:hum,rdc:r,leff:l,windingC:c,cableC:cable.clip(50e-12,2500e-12),
        volumeR:500000,ampR:1000000,lossR:hw[\loss],toneR:toneR.clip(1,500000),toneC:22e-9);
};
~hpSensor={|n,length,p|
    var k=n*pi/length,w=p[\width],sum=0;
    p[\centers].do {|x,i|
        var a=(x-(w/2)).clip(0,length),b=(x+(w/2)).clip(0,length);
        sum=sum+(p[\weights][i]*(((k*a).cos-(k*b).cos)/(k*w)));
    };sum;
};
~hpInitial={|initial,p,polarity=1|
    var result=initial.copy,angle=initial[\tilt].degrad;
    // Start with unobserved string displacement: the contact model's original
    // single-coil q already includes a sensor, and is intentionally replaced.
    result[\q]=initial[\released].collect {|amplitude,i|
        amplitude*~hpSensor.value(i+1,initial[\length],p)*angle.cos*polarity
    };result;
};
~hpNetwork={|p|
    var r=p[\rdc],l=p[\leff],c=p[\windingC]+p[\cableC],ct=p[\toneC],tau=p[\toneR]*ct;
    var g=p[\volumeR].reciprocal+p[\ampR].reciprocal+p[\lossR].reciprocal;
    var a0=1+(r*g),a1=(r*c)+(l*g),a2=l*c,d0,d1,d2,d3,den,lo=0,hi=100,pole,q2,q1,q0;
    // H(s) = 1/(1 + (R+sL)*(G+sC+sCt/(1+sRtCt))).
    // Factor its real pole so stock FOS + SOS implement the complete load.
    d0=a0;d1=a1+(tau*a0)+(r*ct);d2=a2+(tau*a1)+(l*ct);d3=tau*a2;
    den={|s|(((d3*s+d2)*s+d1)*s)+d0};
    while {den.value(hi.neg)>0 and:{hi<1e12}}{hi=hi*2};
    if(den.value(hi.neg)>0){Error("Pickup load has no bracketed real pole").throw};
    64.do {var mid=(lo+hi)*0.5;if(den.value(mid.neg)>0){lo=mid}{hi=mid}};
    pole=(lo+hi)*0.5;q2=d3;q1=d2-(pole*d3);q0=d0/pole;
    if([pole,q0,q1,q2].any {|x|x<=0}){Error("Unstable pickup load").throw};
    (pole:pole,q0:q0,q1:q1,q2:q2,tau:tau,denominator:[d0,d1,d2,d3]);
};
~hpLoad={|input,p|
    var n=~hpNetwork.value(p),k=SampleRate.ir*2,pole=n[\pole],tau=n[\tau];
    var q0=n[\q0],q1=n[\q1],q2=n[\q2],a,b,c,d,signal;
    d=k+pole;
    signal=FOS.ar(input,pole*(1+(tau*k))/d,pole*(1-(tau*k))/d,(k-pole)/d);
    a=q2*k.squared;b=q1*k;c=q0;d=a+b+c;
    SOS.ar(signal,1/(pole*d),2/(pole*d),1/(pole*d),2*(a-c)/d,(b-a-c)/d);
};
~hpPresets=[
    (id:0,name:"Single coil",config:~hpConfig.value(\single)),
    (id:1,name:"Vintage series",config:~hpConfig.value(\vintage,\series)),
    (id:2,name:"Vintage parallel",config:~hpConfig.value(\vintage,\parallel)),
    (id:3,name:"Vintage split",config:~hpConfig.value(\vintage,\split)),
    (id:4,name:"Hot series",config:~hpConfig.value(\hot,\series))
];
)
