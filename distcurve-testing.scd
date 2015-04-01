l = LCDevice();
l.knobs.last.makeVolumeKnob();
Log(\DistCurve).level = \info;
DistCurve.know = true;
~sourceBuf = allocRead(s, 1000, 2);

~humF_50 = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/HumF_50.wav");
~humD1_48 = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/HumD1_48.wav");
~humH_52 = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/HumH_52.wav");
~humA1_44 = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/HumA1_44.wav");
~barrellroll_4 = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/barrell-roll_4.wav");


({
	~sourceBuf = ~humH_52;
	DistCurve.a_( [-1, -0.9, -0.1, -0.5, 0, 0.1, 0.0, 1] );
	DistCurve.b_( Env([-1, -0.6, 0.2, 0.6, -0.2, 1], curve:\sin) );
	DistCurve.c_(
		Env([1, -0.2,  0.1, 0.1, -1], curve:\welch),
		Env([-1, -0.99, -0.9,  -0.5, -0.5, 0.9, 0.99, 1], curve:\welch)
	);

	s.sync;

	SynthDef(\destich, {
		var sig, in;
		sig = PlayBuf.ar(3, ~sourceBuf.bufnum, rate:[0.1, 0.2]).sum.sum;
		in = LocalIn.ar(2).sum;
		//in = in[0] - in[1];
		sig = (sig * 8) + LPF.ar(HPF.ar(DelayC.ar(in * 0.8, 4, 0.3), 10), 200);
		sig = DelayC.ar(sig, 0.1, { LFNoise2.ar(0.1.rand) * 0.1 } ! 16);
		sig = Decay.ar(Dust.ar(0.3), 3) + sig;
		sig = (
			Decay.ar(Impulse.ar(0.65), 1.5)
			- Decay.ar(Impulse.ar(0.15, 0.50, 0.6), 4.1)
			- Decay.ar(Impulse.ar(0.0725, 0.25, 0.9), 8.1)
		) + sig;

		sig = DistCurve.a.ar(sig);
		sig = Splay.ar(sig).postln;
		sig = AllpassN.ar(sig, 1, { 1.0.rand }, { 0.1.rand });
		sig = sig + (sig * HPF.ar(WhiteNoise.ar(0.01), 16000));
		sig = DistCurve.c.ar(sig);
		sig = (sig * 0.99) +  LPF.ar(sig, 60) + HPF.ar(sig, 8000);
		sig = Mirror.ar(sig * 0.3);
		sig = DistCurve.b.ar(sig);
		sig = sig * LPF.ar(sig, MouseX.kr(5, 1800));
		sig = LeakDC.ar(sig);
		sig = Splay.ar(sig);
		LocalOut.ar(sig);
		sig * 5;
	})
	//n.free;
}.fork);

~cap = AudioCapture("/Users/fsc/Desktop/SC_CLEAN/DIST/_capture");
~cap.track = "dist";
~cap.stop();


({
	~sourceBuf = ~barrellroll_4 ;
	// tear r ist
	DistCurve.h_(
		[-1, -0.9, -0.1, -0.5, 0, 0.1, 0.0, 1].resamp1(10).collect({ |n| n + 0.01.rand }),
		[1, 0.9, -0.1, -0.5, 0, 0.1, 0.0, 1].resamp1(50).collect({ |n| n + 0.1.rand }),
		[-1, 0.9, -0.1, -0.5, 0, 0.3, -0.9, 1].resamp1(100).collect({ |n| n + 0.3.rand })
	);
	DistCurve.i_(	Env([1, 0.8, 0.2, -0.6, -0.9, -1], curve:\sin)).plot;
	DistCurve.j_(
		[-1, 0, 1],
		Env([0.25, -0.25,  0.1, -0.1, -0.25, 0.25], curve:\sin)
	).plot;
	DistCurve.k_(	Env([-1, -0.9,  -0.5, 0, 0.5, 0.99, 1], curve:\sin));

	[
		~alldelay = CV([0.01, 2]),
		~alldecay = CV([0.01, 1]),
		~hpos = CV([0, 1]),
		~feedDist = CV([0, 1]),
		~speed = CV([-2, 2])
	].do({
		| cv, i |
		l.knobRows[0][i].connect();
		l.knobRows[0][i].cv = cv;
	});


	SynthDef(\tearist, {
		| out = 0, hpos = 0, alldelay, alldecay, feedDist, speed |
		var sig, in;
		in = LocalIn.ar(2).sum;
		in = DistCurve.j.ar(in * feedDist.linlin(0, 1, 1, 2.5), feedDist);
		sig = PlayBuf.ar(3, ~sourceBuf.bufnum, rate:[1, 4/3, 5/3] * LagUD.kr(speed, 0.4, 0.01)).sum.sum;
		sig = (sig * 5) + LPF.ar(HPF.ar(DelayC.ar(in * 0.6, 0.5, 0.3), 1000), 2000);
		sig = DelayC.ar(sig, 0.1, { LFNoise2.ar(0.1.rand) * 0.1 } ! 16);
		sig = Decay.ar(Dust.ar(0.3), 3) + sig;
		//sig = Decay.ar(Impulse.ar(0.3), 3.1) * sig;
		sig = DistCurve.h.ar(sig, hpos);
		alldelay = alldelay.lag(1);
		sig = AllpassN.ar(sig, 2, alldelay + { 0.2.rand }, alldecay + { 0.1.rand });
		sig = sig + (sig * HPF.ar(WhiteNoise.ar(0.1), 16000));
		sig = DistCurve.k.ar(sig);
		sig = (sig * 0.99) +  LPF.ar(sig, 60) + HPF.ar(sig, 8000);
		sig = Mirror.ar(sig * 1);
		sig = DistCurve.i.ar(sig);
		sig = sig * LPF.ar(sig, 20);
		sig = LeakDC.ar(sig);
		sig = Splay.ar(sig);
		LocalOut.ar(sig);
		Out.ar(0, sig);
	}).addReplace;

	l.buttons[6].clear();
	l.buttons[6].buttonOnActions.add({
		"on".postln;
		{

			s.sync;
			~tearist = Synth.controls(\tearist, [
				\hpos, ~hpos, \alldelay, ~alldelay,
				\alldecay, ~alldecay, \feedDist, ~feedDist,
				\speed, ~speed
			]);
		}.fork;
	});

	l.buttons[6].buttonOffActions.add({ ~tearist.free; });
	l.buttons[6].default.connect().toggle_(true);

}.fork)

({
	// ~b[0] = [-1, -0.9, -0.1, -0.5, 0, 0.1, 0.0, 1];
	// ~b[1] = Env([-1, -0.6, -0.2, 0.6, 0.2, 1], curve:\sin);
	// ~b[2] = Env([-1, -0.2,  0.1, 0.1, 1], curve:\welch);
	// ~b[3] = Env([-1, -0.9,  -0.5, 0, 0.5, 0.99, 1], curve:\sin);
	~sourceBuf = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/HumF_50.wav");

	DistCurve.a( [-1, -0.9, -0.1, -0.5, 0, 0.1, 0.0, 1] );
	DistCurve.b(
		Env([-1, -0.6, -0.2, 0.6, 0.2, 1], curve:\sin),
		Env([-1, -0.9, -0.2 -0.4, 0.4, 0, 0.5, -0.9, 1], curve:\welch),
	);
	DistCurve.c( Env([-1, -0.2,  0.1, 0.1, 1], curve:\welch) );
	DistCurve.d( Env([-1, -0.9,  -0.5, 0, 0.5, 0.99, 1], curve:\sin) );


	s.sync;

	SynthDef(\desth, {
		| allpass = 0, hpf = 16000,
		var sig, in;
		sig = PlayBuf.ar(3, ~sourceBuf.bufnum, rate:[0.1, 0.2]).sum;
		in = LocalIn.ar(2).sum;
		//in = in[0] - in[1];
		sig = (sig * 5) + LPF.ar(HPF.ar(DelayC.ar(in * 0.8, 0.5, 0.3), 1000), 2000);
		sig = DelayC.ar(sig, 0.1, { LFNoise2.ar(0.1.rand) * 0.1 } ! 16);
		//sig = Decay.ar(Dust.ar(0.3), 3) + sig;
		//sig = Decay.ar(Impulse.ar(0.3), 3.1) * sig;
		sig = DistCurve.a.ar(sig);
		sig = AllpassN.ar(sig, 3, { allpass * 1.0.rand }, { 0.3.rand });
		sig = sig + (sig * HPF.ar(WhiteNoise.ar(0.1), hpf));
		sig = DistCurve.c.ar(sig);
		sig = (sig * 0.99) +  LPF.ar(sig, 60) + HPF.ar(sig, 8000);
		sig = Mirror.ar(sig * 1);
		sig = DistCurve.b.ar(sig, MouseX.kr(0, 1), MouseX.kr(0, 30));
		sig = sig * LPF.ar(sig, 20);
		sig = LeakDC.ar(sig);
		sig = Splay.ar(sig);
		LocalOut.ar(sig);
		sig;
	}).addReplace;
}.fork)


({
	// ~b[0] = [-1, -0.9, -0.1, -0.5, 0, 0.1, 0.0, 1];
	// ~b[1] = Env([-1, -0.6, -0.2, 0.6, 0.2, 1], curve:\sin);
	// ~b[2] = Env([-1, -0.2,  0.1, 0.1, 1], curve:\welch);
	// ~b[3] = Env([-1, -0.9,  -0.5, 0, 0.5, 0.99, 1], curve:\sin);
	~sourceBuf = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/HumF_50.wav");

	DistCurve.a( [-1, -0.9, -0.1, -0.5, 0, 0.1, 0.0, 1] );
	DistCurve.b(
		Env([-1, -0.2,  0.1, 0.1, 1], curve:\sin),
		Env([1, -0.6, -0.2, -0.6, 0.2, -1], curve:\welch),
	);
	DistCurve.c( Env([-1, -0.2,  0.1, 0.1, 1], curve:\welch) );
	DistCurve.d( Env([-1, -0.9,  -0.5, 0, 0.5, 0.99, 1], curve:\sin) );

	~apDelay = CV(ControlSpec(0.01, 2));
	~apDecay = CV(ControlSpec(0.01, 12));
	~noiseCut = CV(ControlSpec(5, 600, \exp));
	~mirror = CV(ControlSpec(0.2, 4, \exp));


	[~apDelay, ~apDecay, ~noiseCut, ~mirror].do({
		|cv, i|
		OSCFunc({
			| msg |
			cv.input = msg[1];
			cv.value.postln;
		}, "/k/" ++ (i * 4 + 1).asString, recvPort:57120);

	});

	s.sync;

	SynthDef(\dist1, {
		arg out=0, apDelay, apDecay, noiseCut, mirror;
		var sig, in;
		in = LocalIn.ar(2).sum;
		//in = in[0] - in[1];
		sig = Mix(PlayBuf.ar(3, ~sourceBuf.bufnum, rate:[0.1, 0.2]).sum);
		sig = sig + PitchShift.ar(sig, pitchRatio:2) + PitchShift.ar(sig, pitchRatio:4);
		sig = (sig * 2) + LPF.ar(HPF.ar(DelayC.ar(in * 0.08, 0.5, 0.3), 2000), 5000);
		sig = DelayC.ar(sig, 0.1, { LFNoise2.ar(0.1.rand) * 0.1 } ! 16);
		//sig = Decay.ar(Dust.ar(0.3), 3) + sig;
		//sig = Decay.ar(Impulse.ar(0.3), 3.1) * sig;
		sig = DistCurve.b.ar(sig, MouseX.kr(0, 1));
		sig = AllpassN.ar(sig, 2.1, apDelay.lag(5) + { 0.1.rand }, apDecay);
		sig = sig + (sig * HPF.ar(WhiteNoise.ar(0.01), 14000));
		sig = DistCurve.c.ar(sig);
		sig = (sig * 0.99) +  LPF.ar(sig, 60) + HPF.ar(sig, 8000);
		sig = Mirror.ar(sig * mirror);
		sig = DistCurve.d.ar(sig);
		sig = sig * LPF.ar(sig, noiseCut.lag(0.5));
		sig = LeakDC.ar(sig);
		sig = Splay.ar(sig);
		LocalOut.ar(sig);
		Out.ar(out, sig);
	}).add;

	Synth.controls(\dist1, args: [
		\apDelay, ~apDelay,
		\apDecay, ~apDecay,
		\noiseCut, ~noiseCut,
		\mirror, ~mirror
	]);
}.fork)
b





({
	~sourceBuf = Buffer.read(s,  "/Users/fsc/Desktop/SET EM BR/sounds/HumA1_44.wav");
	~sourceBuf = ~humD1_48;

	DistCurve.m_(
		[-1, -0.9, -0.1, -0.5, 0, 0.5, 0.0, 1].resamp1(10).collect({ |n| n + 0.05.rand }),
		[-1, -0.9, -0.1, -0.5, 0, 0.5, 0.0, 1].resamp1(15).collect({ |n| n + 0.07.rand }),
		[-1, -0.7, -0.3, -0.7, 0, -0.3, -0.8, -0.4,  1].resamp1(20).collect({ |n| n + 0.1.rand }),
	).plot;

	DistCurve.n_(Env([-1, -0.6, -0.2, 0.6, 0.2, 1], curve:\sin)).plot;
	DistCurve.o_(Env([-1, -0.9,  0.1, 0.1, 1], curve:\welch));
	DistCurve.p_(Env([-1, -0.9,  -0.5, 0, 0.5, 0.99, 1], curve:\sin)).plot;

	SynthDef(\dest2, {
		| t_pulse = 0, impulseFreq = 0.3, decay=5, srcMix=0, select=0, focus=0.8, oct=1 |
		var source, sig, distSig, in, freqs, amps;
		RandSeed.ir(1, 14455);
		freqs = ( Scale.partch_o1.degreeToRatio((0..12), oct) * 0.2).postln;
		select = SinOsc.ar(impulseFreq / 24, 0.2, 0.5, 0.5);
		select = select * freqs.size();

		source = Splay.ar(
			SelectXFocus.ar(select, PlayBuf.ar(3, ~sourceBuf.bufnum, rate:freqs, loop:1), focus) * 6;
		);
		in = SoftClipper4.ar(LocalIn.ar(2).sum);
		in = Compander.ar(in, in, 0.9, slopeAbove:0.1, relaxTime:5);
		in = in * Lag.kr(Pulse.kr(1 / 18, 0, 2, -1));
		//in = in[0] - in[1];
		source = source;
		sig = (source * 6) + LPF.ar(HPF.ar(DelayC.ar(in * 0.9, 6, impulseFreq.reciprocal * 2), 100), 1000);
		sig = DelayC.ar(sig, 0.1, { LFNoise2.ar(0.1.rand) * 0.1 } ! 16);

		//sig = Decay.ar(Impulse.ar(0.3), 3.1) * sig;
		sig = (LagUD.ar(Impulse.ar(impulseFreq), 0.00001, decay) * sig) +
		(
			Decay.ar(Impulse.ar(0.65), 1.5)
			- Decay.ar(Impulse.ar(0.15, 0.50, 0.6), 4.1)
			- Decay.ar(Impulse.ar(0.0725, 0.25, 0.9), 8.1)
		) * sig;
		srcMix = MouseY.kr(-1, 1);
		distSig = XFade2.ar(sig, source, srcMix) * 8;
		distSig = distSig.tanh * 0.5;
		distSig = DistCurve.m.ar(distSig, 0.7);
		distSig = AllpassN.ar(distSig, 1, { 1.0.rand }, { 0.1.rand });
		distSig = distSig + (distSig * HPF.ar(WhiteNoise.ar(0.04), 16000));
		distSig = DistCurve.o.ar(distSig);
		distSig = (distSig * 0.29) +  LPF.ar(distSig, 60) + HPF.ar(distSig, 12000);
		distSig = Mirror.ar(distSig * 2);
		distSig = DistCurve.n.ar(distSig);
		distSig = distSig * LPF.ar(distSig, 40);

		sig = sig + distSig;
		//sig = distSig;

		sig = LeakDC.ar(sig);
		sig = Splay.ar(sig);
		LocalOut.ar(sig);
		Out.ar(0, sig);
	}).addReplace;

	s.sync;
	n = Synth(\dest2);
	n.set(\oct, 2);
	n.set(\impulseFreq, 4);
	n.set(\decay, 0.3);

	n.free
}.fork)