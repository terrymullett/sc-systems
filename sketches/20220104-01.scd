"../setup/Setup.scd".loadRelative;

(
var dur = [1.25, 1.125, 1, 1, 0.875, 0.75];
var key = 3;
var notes = [-8, 0, 2, 4, 7, 11] * key;
var roots = Pdup(Prand([2,4], inf), Pseq([0, 4, 2, 6, 3], inf)).asStream;
var rpt = 9;

p.makeTempoClock;
p.clock.tempo_(136/60);

~out = { \in.ar(0!2) };

~out[100] = \filterIn -> {
    |in|
    LeakDC.ar(
        LPF.ar(
            in: Klank.ar(`[
                Array.geom(4, 83.853989, pi),
                Array.fill(4, {|i| 0.95.pow(8 * (i + 1))}) * 0.1,
                Array.geom(4, 0.125, 0.5),
            ], in),
            freq: 2600
        )
    )
};
~out.set(\wet100, 0.75);

~out[200] = \filter -> { |in| LeakDC.ar(BHiPass4.ar(in, 20))}; ~out.set(\wet200, 1);
~out[300] = \filter -> { |in| LeakDC.ar(RLPF.ar(in, 16000, 0.5))}; ~out.set(\wet300, 1);
~out[400] = \filter -> { |in| LeakDC.ar(MidEQ.ar(in, 12000, rq: 1.5, db: 2)) }; ~out.set(\wet400, 1);
~out[500] = \filter -> { |in| LeakDC.ar(MidEQ.ar(in, 9000, rq: 1.5, db: -6)) }; ~out.set(\wet500, 1);

~out.play;
~a <>> ~out;

r{
    loop {
        var durs = dur.scramble;
        var chord = notes.scramble;
        var root = roots.next;
        ~a[0] = Ppar(Array.fill(6, { |i|
            Pbind(
                \instrument, \fm3mc_perc,
                \note, chord[i],
                \root, root,
                \octave, 4,
                \dur, Pseq([durs[i]], rpt),
                \amp, Pgeom(1, 0.707, rpt) * Pwrand([0, 1], [1, 3].normalizeSum, inf),
                \atk, 0.01 + (0.005 * i),
                \rel, Pkey(\dur) - Pkey(\atk),
            )
        })
        );
        (rpt * (2/3)).wait;
    };
}.play(p.clock);

)