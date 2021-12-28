"../setup/Setup.scd".loadRelative;

(
p.makeTempoClock(1);
p.quant_(4).fadeTime_(2);
)
(
~out = { \in.ar(0!2) };
~out.play;
~out[10] = \filter -> { |in| BHiPass4.ar(in, 40)}; ~out.set(\wet10, 1);
~a <>> ~out;
~lfo0 = { LFNoise2.ar(0.5).range(0, 1) };
)

(
~out[10] = \filterIn -> {
    |in|
    //controls
    var hpf = \hpf.kr(50);                  // high pass filter cutoff frequency for the output
    var lpf = \lpf.kr(6000);                // low pass filter cutoff frequency for the output
    var lpf1 = \lpf1.kr(2000);              // low pass filter cutoff frequency for the Comb array
    var decay = \decay.kr(0.5);             // reverberation decay time
    var predelay = \predelay.kr(0.05);      // reverb pre-delay

    var sig = DelayN.ar(in, predelay);
    sig = LPF.ar(Mix.ar(Array.fill(16, { CombL.ar(sig, 0.1, LFNoise1.kr(0.1.rand, 0.04, 0.05), decay) })), lpf1);
    8.do({ sig = AllpassN.ar(sig, 0.050, [0.050.rand, 0.050.rand], decay) });
    LeakDC.ar(HPF.ar(LPF.ar(sig, lpf), hpf));
};
~out.set(\wet10, 0.1);
)

//adapted from Alik Rustamoff
(
~a[0] =  Pbind(
	\instrument, \chimes,
	\dur, Pseq([Pseq([0.5, 2, 4, 8], 12), 8], 1),
    \scale, Scale.dorian,
    \root, 9,
	\degree, Pseq([0, 2, 4, 6, 8, 10], inf),
	\octave, Pdup(4, Pseq([3, 4, 5], inf) ),
	\atk, Pexprand(3, 4, inf),
	\sus, Pwrand([0.5, 1], [0.25, 0.75], inf),
	\rel, Pwhite(8.0, 10.0, inf),
	\detune, Pwhite(0.25, 0.5, inf),
    \lpf, (Pkey(\freq) * Pkey(\freq).expexp(41,2640,8,1.1,-6)).clip(20,20000),
	\rq, 0.6,
	\vel, Pwhite(0.4, 0.6, inf) * Pkey(\freq).explin(28,100,-3,-9).dbamp,
    \amp, 1,
	\pan, Pexprand(0.1,0.7,inf) * Pseq([-1,1],inf),
);
~a[1] =  Pbind(
	\instrument, \wtmorph0,
    \bufX, e.wt.wt0.bufnum,
    \bufY, e.wt.wt1.bufnum,
    \morph, ~lfo0,
	\dur, Pseq([Pseq([8, 4, 2, 0.5], 12), 8], 1),
    \scale, Scale.dorian,
    \root, 9,
	\degree, Pseq([-3, -1, 0, 2, 4, 6], inf),
	\octave, Pdup(4, Pseq([4, 5, 6], inf) ),
	\atk, Pexprand(3, 4, inf),
	\sus, Pwrand([0.5, 1], [0.25, 0.75], inf),
	\rel, Pwhite(8.0, 10.0, inf),
	\detune, Pwhite(0.25, 0.5, inf),
    \lpf, (Pkey(\freq) * Pkey(\freq).expexp(41,2640,8,1.1,-6)).clip(20,20000),
	\rq, 0.5,
	\vel, Pwrand([Pwhite(0.4, 0.6) * Pkey(\freq).explin(28,100,-3,-9).dbamp], [0.75, 0.25], inf),
    \amp, 1,
	\pan, Pexprand(0.1,0.7,inf) * Pseq([-1,1],inf),
);
)

~a.removeAt(0);

p.clear; s.freeAll; s.quit;
