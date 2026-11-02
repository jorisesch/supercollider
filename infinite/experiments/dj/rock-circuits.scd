// Reduced circuit models, stock UGens only. Equations/references: GUITAR.md.
// Signal units are nominal pickup volts until the rig output attenuation.
(
~djRC={|input,hz,high=false|
    var k=(pi*hz.clip(1,20000)/SampleRate.ir).tan,c=1/(1+k);
    if(high){FOS.ar(input,c,c.neg,(1-k)*c)}{FOS.ar(input,k*c,k*c,(1-k)*c)};
};
~djDiodeRoot={|input,resistance=2200,thermal=0.045,leakage=2.52e-9|
    // Kirchhoff + antiparallel Shockley diodes: x = y + 2 R Is sinh(y/nVT).
    var x=input.clip(-32,32),a=resistance*(2*leakage),y,z;
    y=(thermal*((x.abs*2/a)+1).log).min(x.abs)*x.sign;
    4.do {z=(y/thermal).clip(-24,24);y=y-((y+(a*z.sinh)-x)/(1+((a/thermal)*z.cosh)))};
    y;
};
~djDiode={|input,resistance=2200,thermal=0.045|
    // First-order ADAA using the analytical integral of the implicit I/V curve.
    var x=input.clip(-32,32),a=resistance*5.04e-9,y,z,integral,dx,den,result;
    y=~djDiodeRoot.value(x,resistance,thermal);z=y/thermal;
    integral=(y.squared*0.5)+(a*((y*z.sinh)-(thermal*(z.cosh-1))));
    dx=x-Delay1.ar(x);den=(dx.sign*dx.abs.max(0.0002))+((dx.abs<1e-12)*0.0002);
    result=(integral-Delay1.ar(integral))/den;
    Select.ar(dx.abs<0.0002,[result,(y+Delay1.ar(y))*0.5]);
};
~djRail={|input,rail=3.2,bias=0|
    // Differential-pair saturation approximation; ADAA, with bias removed at DC.
    var x=(input/rail)+bias,ax=x.abs,integral,dx,den,y;
    integral=ax+((-2*ax).exp+1).log-2.log;
    dx=x-Delay1.ar(x);den=(dx.sign*dx.abs.max(0.0002))+((dx.abs<1e-12)*0.0002);
    y=Select.ar(dx.abs<0.0002,[(integral-Delay1.ar(integral))/den,((x+Delay1.ar(x))*0.5).tanh]);
    (y-bias.tanh)*rail;
};
~djTSTone={|input,tone=0.5|
    // Yeh/Abel/Smith eq.24, bilinear transform of the complete active tone block.
    var t=tone.clip(0.02,0.98),rl=t*20000,rr=(1-t)*20000;
    var parallel=(rl*rr)/(rl+rr),y=(rl+rr)*(220+parallel),w=y/((rl*1000)+y);
    var x=rr/(rl+rr)/((220+parallel)*0.22e-6);
    var wz=1/((220+parallel)*0.22e-6),wp=1/((1000*10000/11000)*0.22e-6);
    var gain=((rl*1000)+y)/(y*1000*0.22e-6),k=2*SampleRate.ir;
    var a1=wp+wz+x,a0=wp*wz,d=k.squared+(a1*k)+a0;
    SOS.ar(input,gain*(k+(w*wz))/d,2*gain*w*wz/d,gain*((w*wz)-k)/d,
        (2*(k.squared-a0))/d,((a1*k)-k.squared-a0)/d);
};
~djTubeScreamer={|input,drive=0.3,tone=0.5|
    var x=~djRC.value(~djRC.value(input,15.9,true),15.6,true),rf=51000+(drive*500000),feedback;
    // TS: the unclipped input survives; only the frequency-dependent feedback
    // voltage is diode-limited. The 51pF feedback memory is a linear approximation.
    feedback=~djRC.value(x,1/(2pi*4700*0.047e-6),true)*(rf/4700);
    feedback=~djRC.value(feedback,1/(2pi*rf*51e-12));
    ~djTSTone.value(((x+Delay1.ar(x))*0.5)+~djDiode.value(feedback,rf),tone)*0.40;
};
~djPedals={|input,pedal=0,drive=0.3,tone=0.5,fuzz=0|
    var x=~djRC.value(~djRC.value(input,15.9,true),15.6,true);
    var ts=~djTubeScreamer.value(input,drive,tone),ds,bd,a,b,clean,muff;
    // DS-1: BJT preamplifier, gain-dependent op-amp shelf and a diode shunt.
    a=~djRC.value(~djRC.value(x,3,true),600,true)*63.1;
    a=~djRail.value(a,3.2,0.035);
    a=a+(~djRC.value(~djRC.value(a,1/(2pi*((1-drive)*100000+4700)*1e-6),true),
        1/(2pi*(drive*100000+1)*250e-12))*(drive*100000/((1-drive)*100000+4700)));
    ds=~djDiode.value(~djRC.value(~djRail.value(a,3.6),1/(2pi*2200*0.01e-6)),2200);
    ds=((~djRC.value(ds,320)*(1-tone))+(~djRC.value(ds,1160,true)*tone))*0.70;
    // BD-2: two separated rail-limited discrete gain blocks, interstage bass/
    // treble shaping and two series diodes per direction. Not a transistor solver.
    a=x+(~djRC.value(x,1/(2pi*1800*0.15e-6),true)*(2+(drive*28)));
    a=~djRail.value(a,2.8,0.055);
    a=(~djRC.value(a,480)*0.55)+(~djRC.value(a,1150,true)*0.38);
    b=a+(~djRC.value(a,1/(2pi*4700*1e-6),true)*(1+(drive*12)));
    b=~djRail.value(b,2.8,-0.035);
    bd=~djDiode.value(b,1000,0.090);
    bd=(~djRC.value(bd,1000)*(1-tone))+(~djRC.value(bd,1000,true)*tone);
    bd=bd*0.28;
    // Muff-family reduction: two AC-coupled feedback-diode stages, not a
    // square-wave overlay. The same chord passes through both clipping stages.
    muff=x;
    2.do {muff=~djRC.value(muff,35,true);muff=~djRC.value(muff,1/(2pi*470000*470e-12));
        muff=~djDiode.value(muff*(8+(drive*18)),470000)*0.8};
    muff=(~djRC.value(muff,600)*(1-tone))+(~djRC.value(muff,1600,true)*tone);
    clean=input*1.35;
    (SelectX.ar(Lag.kr(pedal.clip(0,3),0.06),[clean,bd,ts,ds])*(1-fuzz))+(muff*fuzz*0.65);
};
~djGuitarCompressor={|input,amount=0|
    var detector=Amplitude.ar(input.abs.sum*0.5,0.006,0.12).max(1e-7).ampdb;
    var over=detector+24,ratio=1+(amount*3),knee=6,reduction;
    // Quadratic soft knee, gain computer in dB; detector attack preserves the pick.
    reduction=Select.ar(over>3,[(over+3).max(0).squared/(2*knee),over])*(1-(1/ratio));
    input*(reduction.neg+(amount*2)).dbamp;
};
~djGuitarChorus={|input,amount=0|
    // One shared BBD clock for the two guitar tracks. Rate changes clock period,
    // hence delay and pitch. Filtering represents the audio bandwidth of a BBD.
    var clock=LFTri.kr(0.78).range(65000,105000),delay=1024/(2*clock);
    var wet=~djRC.value(~djRC.value(input,6200),6200);
    wet=DelayC.ar(wet,0.02,delay);wet=~djRC.value(~djRC.value(wet,5000),5000);
    (input*(1-(amount*0.35)))+(wet*amount*0.65);
};
~djGuitarRig={|input,comp=0,chorus=0,pedal=0,drive=0.3,tone=0.5,fuzz=0|
    var x=~djGuitarCompressor.value(input,comp),cab;
    x=~djPedals.value(x,pedal,drive,tone,fuzz);
    x=~djGuitarChorus.value(x,chorus);
    // Broad loudspeaker rolloff/low resonance; intentionally not a measured IR.
    cab=HPF.ar(x,75)+(BPF.ar(x,125,0.8)*0.20);
    cab=LPF.ar(LPF.ar(cab,4700),6200);
    LeakDC.ar(cab)*0.40;
};
)
