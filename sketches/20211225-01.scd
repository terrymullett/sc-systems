"../setup/Setup.scd".loadRelative;

(
p.makeTempoClock(1).quant_(0).fadeTime_(2);
)

~a.play;
(
~a = Pbind(
    \instrument, \fm3mc_perc,
    \dur, Pseq([4], 8),
    \note, [2, -12],
    \amp, Pgeom(1, 1/(2.sqrt), inf),
    \vel, Pgeom(1, 1/(2.sqrt), inf),
    \atk, 0.002,
    \rel, Pkey(\dur) * 0.9,
    \curve, -1,
    \mRatio1, 4,
    \mRatio2, 2,
    \mRatio3, 1,
    \mIndex1, 2.0,
    \mIndex2, 1.0,
    \mIndex3, 0.5,
);
~a[100] = \filterIn -> {
    |in|
    LeakDC.ar(
        LPF.ar(
            in: Klank.ar(`[
                Array.geom(4, 120, 2.7),
                Array.fill(4, {|i| 0.9.pow(8 * (i + 1))}),
                Array.geom(4, 0.125, 0.5),
            ], in),
            freq: 9000
        )
    )
};
~a.set(\wet100, 0.1);
)

~a.removeAt(100);
~a.removeAll;

