"../setup/Setup.scd".loadRelative;

(
p.makeTempoClock(1);
p.quant_(4).fadeTime_(2);
)

(
~out = { \in.ar(0!2) };
~out.play;
~a <>> ~out;
)

(
~a = Pbind(
	\instrument, \fm3mc_perc,
	\legato, Pfunc({rrand(0.01,1)}),
    \scale, Scale.dorian,
    \root, 3,
    \degree, Pseq([0,2,5,6,8,11].scramble, inf),
    \dur, Pseq( 2.pow((-4..1).scramble), inf ),
	\octave, Pdup(3, Pseq([3,4,5], inf) ),
	\vel, Pdup(6, Pseq([ 0.2, 0.6, 1 ].scramble, inf)),
    \amp, 1,
	\mRatio1, Pseq( (3..5).scramble, inf ),
	\mRatio2, Pseq( (1..3).scramble, inf ),
	\mRatio3, Pseq( (3..5) / (1..3).scramble, inf ),
	\mIndex1, Pfunc{rrand(0,2.0)},
	\mIndex2, Pfunc{rrand(0,1.0)},
	\mIndex3, Pfunc{rrand(0,0.5)},
	\pan, 0,
);
)

(
{
    (0..32).do{
        ~a = Pbind(
            \instrument, \fm3mc_perc,
            \legato, Pfunc({rrand(0.01,1)}),
            \scale, Scale.phrygian,
            \root, 3,
            \degree, Pseq([0,2,5,6,8,11].scramble, inf),
            \dur, Pseq( 2.pow((-4..1).scramble), inf ),
            \octave, Pdup(4, Pseq([3,4,5], inf) ),
            \vel, Pdup(6, Pseq([ 0.2, 0.6, 1 ].scramble, inf)),
            \amp, 1,
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
    "done".postln;
    ~a.objects[0].stop;
}.fork;
)


~a.objects
[0].stop;
~a = 0;

t = Ptrace(~a[0].source, \degree, prefix: "degree: ").play;
t.stop;
t = Ptrace(~a[0].source, \dur, prefix: "dur: ").play;

p.clear; s.freeAll; s.quit;
ProxySpace.pop;



