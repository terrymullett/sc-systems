"../setup/Setup.scd".loadRelative;

(
p.makeTempoClock;
p.clock.tempo_(2);
p.quant_(4).fadeTime_(2);
~out = { \in.ar(0!2) };
~out[10] = \filter -> { |in| BHiPass4.ar(in, 40)}; ~out.set(\wet10, 1);
~a <>> ~out;
)

(
{
    var r = p.record(key: \out, sampleFormat: "int32").record;
    ~out.play;
    1.wait;
    r.unpause;
    (0..8).do{
        |i|
        var newTempo =
        [2, 1].wchoose([0.75, 0.25]);
        // 1;
        // 2;
        // 135/60;
        p.clock.tempo_(newTempo);
        [i, newTempo].postln;
        ~a[0] = Pbind(
            \instrument, \fm3mc_perc,
            \legato, Pfunc({rrand(0.01,1)}),
            \scale, Scale.locrian,
            \root, 3,
            \degree, Pseq([0,2,5,6,8,11].scramble, inf),
            \dur, Pseq( 2.pow((-4..1).scramble), inf ),
            \octave, Pdup(4, Pseq([3,4,5], inf) ),
            \vel, Pdup(6, Pseq([ 0.2, 0.6, 9 ].scramble, inf)),
            \amp, 0.7,
            \mRatio1, Pseq( (3..5).scramble, inf ),
            \mRatio2, Pseq( (1..3).scramble, inf ),
            \mRatio3, Pseq( (3..5) / (1..3).scramble, inf ),
            \mIndex1, Pfunc{rrand(0,2.0)},
            \mIndex2, Pfunc{rrand(0,1.0)},
            \mIndex3, Pfunc{rrand(0,0.5)},
            \pan, 0,
        );
        [8, 16, 24].choose.wait;
    };
    ~a.objects.do( _.stop );
    8.wait;
    "done".postln;
    ~a = 0;
    r.close;
    2.wait;
    s.freeAll;
}.fork;
)

(
{
p.clear; s.sync;
s.freeAll; s.sync;
s.quit;
}.fork;
)


