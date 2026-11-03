// Reduced pick/string mechanics and modal initial conditions. See RESEARCH.md.
(
~gcMaterials=(
    hard:(name:"Stiff pick, square edge",modulus:2e9,width:0.008,thickness:0.001,freeLength:0.006,
        footprint:0.0004,bevel:0.00018,edge:0,padStiffness:0,releaseExtra:0),
    angled:(name:"Same pick, 45 degree edge",modulus:2e9,width:0.008,thickness:0.001,freeLength:0.006,
        footprint:0.0004,bevel:0.00018,edge:45,padStiffness:0,releaseExtra:0),
    flexible:(name:"Flexible thin pick",modulus:2e9,width:0.008,thickness:0.0005,freeLength:0.006,
        footprint:0.0006,bevel:0.00018,edge:0,padStiffness:0,releaseExtra:0),
    flesh:(name:"Finger pad",modulus:0,width:0,thickness:0,freeLength:0,
        footprint:0.007,bevel:0,edge:0,padStiffness:900,releaseExtra:0.00035),
    nail:(name:"Fingernail edge",modulus:3e9,width:0.006,thickness:0.0006,freeLength:0.0035,
        footprint:0.0008,bevel:0.00012,edge:20,padStiffness:0,releaseExtra:0.00004)
);
~gcSinc={|x|if(x.abs<1e-9){1}{x.sin/x}};
~gcInitial={|note=64,string=4,material=\hard,depth=0.00042,speed=1.5,polarity=1,tilt=20,mute=0.04,pickPosition=0.115|
    var m=~gcMaterials[material],open=[40,45,50,55,59,64][string],fret=note-open;
    var diameter=[0.00046,0.00042,0.00036,0.00043,0.00033,0.00025][string];
    var mass=[0.0063,0.0036,0.0023,0.0011,0.00068,0.00039][string];
    var length=0.648*(2.pow(fret/12)).reciprocal,ei=200e9*pi*diameter.pow(4)/64;
    var ea=200e9*pi*diameter.squared/4,tension,position,ks,weak,strong,k,theta=m[\edge].degrad;
    var h,force,impedance,tau,geometric,footprint,angle=tilt.degrad,energy=0,q=Array.new,phase=Array.new,sigma=Array.new;
    var released=Array.new,pickup=0.045/length,pickupWidth=0.006;
    if(fret<0 or:{fret>24}){Error("Unplayable contact-study fret").throw};
    tension=(mass*(2*length*note.midicps).squared)-(ei*pi.squared/length.squared);
    position=pickPosition.clip(0.04,length*0.8);ks=tension*(position.reciprocal+(length-position).reciprocal);
    if(m[\padStiffness]>0){k=m[\padStiffness]}{
        weak=m[\modulus]*m[\width]*m[\thickness].pow(3)/(4*m[\freeLength].pow(3));
        strong=m[\modulus]*m[\thickness]*m[\width].pow(3)/(4*m[\freeLength].pow(3));
        // Resolve the bending compliance along the rotated contact direction.
        k=((theta.cos.squared/weak)+(theta.sin.squared/strong)).reciprocal;
    };
    h=depth*k/(k+ks);force=ks*h;impedance=(tension*mass).sqrt;
    geometric=2*m[\bevel]*theta.sin.abs/speed;
    tau=(2*impedance/k)+geometric+m[\releaseExtra];
    footprint=m[\footprint]+(m[\thickness]*theta.sin.abs);
    40.do {|i|
        var n=i+1,w=n*pi/length,hz=(tension/mass+(ei/mass*w.squared)).sqrt*n/(2*length);
        var a=2*h*(n*pi*position/length).sin/(pi.squared*n.squared*(position/length)*(1-(position/length)));
        var release=(1+(2pi*hz*tau).squared).sqrt.reciprocal;
        var shape=~gcSinc.value(n*pi*footprint/(2*length));
        var sensor=(n*pi*pickup).sin*~gcSinc.value(n*pi*pickupWidth/(2*length));
        var amplitude=a*shape*release;
        energy=energy+(0.25*mass*length*(2pi*hz).squared*amplitude.squared);
        released=released.add(amplitude);
        q=q.add(amplitude*sensor*angle.cos*polarity);
        phase=phase.add((2pi*hz*tau).atan.neg);
        sigma=sigma.add(0.48+(n.squared*0.012)+(mute*70*(n*pi*0.025/length).sin.squared));
    };
    (note:note,string:string,fret:fret,material:material,length:length,mass:mass,tension:tension,
        pickStiffness:k,stringStiffness:ks,displacement:h,force:force,releaseSeconds:tau,
        releaseLatency:(depth/speed)+geometric+(tau*0.5),footprint:footprint,tilt:tilt,
        q:q,phase:phase,sigma:sigma,released:released,
        horizontalRatio:angle.tan*0.18,energyDelta:ea*energy/(2*length*tension));
};
~gcArgs={|initial|
    var args=[\cHorizontal,initial[\horizontalRatio],\cEnergy,initial[\energyDelta]];
    initial[\q].do {|v,i|args=args++[("cQ"++i).asSymbol,v]};
    initial[\phase].do {|v,i|args=args++[("cP"++i).asSymbol,v]};
    initial[\sigma].do {|v,i|args=args++[("cD"++i).asSymbol,v]};args;
};
)
