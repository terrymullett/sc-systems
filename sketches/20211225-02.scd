"../setup/Setup.scd".loadRelative;

(
p.makeTempoClock(1).quant_(0).fadeTime_(2);
{
    var proxyNum = 0, maxProxies = 5;
    var tune = Pxrand([[-20], [-12], [-10], [-5], [-1], [-8], [0], [2], [4], [7], [11], [-12, 12], [-10,14], [-5,19]] + 63, inf).asStream;
    e.playing = true;
    {e.playing}.while {
        {
            var note = tune.next;
            var time = [4,3,2].choose, rpt = 9;
            var trend = Pgeom(1, 1/(2.sqrt), rpt).asStream;
            var proxy = ("p" ++ proxyNum.asString).asSymbol;
            var factor;
            p[proxy].play;
            p[proxy][100] = \filterIn -> {
                |in|
                LeakDC.ar(
                    LPF.ar(
                        in: Klank.ar(`[
                            Array.geom(4, 120, 2.7),
                            Array.fill(4, {|i| 0.9.pow(8 * (i + 1))}),
                            Array.geom(4, 0.125, 0.5),
                        ], in),
                        freq: (note.sort.reverse[0].midicps * \lpfFactor.kr(24)).clip(20, 20000);
                    )
                )
            };
            {notNil(factor = trend.next)}.while {
                p[proxy][0] = Pbind(
                    \instrument, \fm3mc_perc,
                    \dur, Pseq([time], 8),
                    \midinote, note,
                    \amp, (440/Pkey(\freq)).pow(0.3333) * (1/(2.sqrt)) * factor,
                    \vel, (1/(2.sqrt)) * factor,
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
                p[proxy].set(\wet100, 1-(0.5.pow(factor)) * 0.2);
                p[proxy].set(\lpfFactor, 5.pow(factor));
                time.wait;
            };
        }.fork(p.clock);
        (10 - rrand(1, 8)).wait;
        proxyNum = (proxyNum + 1) % maxProxies;
    };
}.fork;
)
