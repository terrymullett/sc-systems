"../setup/Setup.scd".loadRelative;

(
p.clear;
p.makeTempoClock(1);
p.quant_(4).fadeTime_(2);
~out = { \in.ar(0!2) };
~a.ar(2);
~out.play;
~a <>> ~out;
~lfo0 = { LFNoise2.ar(0.25).range(0, 1) };

~out[100] = \filterIn -> {
    |in|
    LeakDC.ar(Klank.ar(`[Array.rand(4, 200, 2000).sort.postln, nil, [0.25, 0.625, 0.5, 0.25]], in) * 0.1 )
};
~out.set(\wet100, 0.05);

~out[200] = \filter -> { |in| BHiPass4.ar(in, 40)}; ~out.set(\wet200, 1);

~a[0] =
Ppar([
    Pbind(
        \instrument, \chimes,
        \dur, Pseq(list: [Pseq([0.5, 2, 4, 8].scramble, 16), 4], repeats: 1).trace(prefix: "[0]: "),
        \scale, Scale.minorPentatonic,
        \root, 5,
        \degree, Pseq([0, 2, 4, 6, 8, 10], inf),
        \octave, Pdup(4, Pseq([3, 4, 5], inf) ),
        \atk, Pkey(\dur) * 0.5,
        \sus, Pkey(\dur) * 0.5,
        \rel, Pkey(\dur) * [1, 0.5].wchoose([4, 1].normalizeSum),
        \detune, Pwhite(0.25, 0.5, inf),
        \lpf, (Pkey(\freq) * Pkey(\freq).expexp(41,2640,8,1.1,-6)).clip(20,20000),
        \lpfRq, 0.6,
        \vel, Pwhite(0.4, 0.6, inf) * Pkey(\freq).explin(28,100,-3,-9).dbamp,
        \amp, 0.3,
        \pan, Pexprand(0.1,0.7,inf) * Pseq([-1,1],inf),
    ),
    Pbind(
        \instrument, \wtmorph0,
        \bufX, e.wt.wt0.bufnum,
        \bufY, e.wt.wt1.bufnum,
        \morph, ~lfo0,
        \dur, Pseq([4, 2, 8.5], 15).trace(prefix: "[1]: "),
        \scale, Scale.minorPentatonic,
        \root, 5,
        \degree, Pseq([-2, -1, 0], inf),
        \octave, 4,
        \atk, Pkey(\dur) * 0.5,
        \sus, Pkey(\dur),
        \rel, Pkey(\dur),
        \detune, Pwhite(0.25, 0.5, inf),
        \lpfRq, 0.5,
        \vel, Pwrand([Pwhite(0.4, 0.6) * Pkey(\freq).explin(28,100,-3,-9).dbamp], [0.75, 0.25], inf),
        \amp, 0.15,
        \pan, Pexprand(0.1,0.7,inf) * Pseq([-1,1],inf),
    ),
]);
)

~a.removeAll;
