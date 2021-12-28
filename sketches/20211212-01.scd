"../setup/Setup.scd".loadRelative;
(
p.fadeTime_(2);
~out = { \in.ar(0!2) };
~out.play;
~out[10] = \filter -> { |in| BHiPass4.ar(in, 40)}; ~out.set(\wet10, 1);
~a.ar(2);
~a <>> ~out;
~lfo1 = {LFNoise2.kr(0.5).range(0, 2)};
~lfo2 = {LFNoise2.kr(0.5).range(0, 1)};
~lfo3 = {LFNoise2.kr(0.5).range(0, 0.5)};
~lfo4 = {LFNoise2.kr(0.5).bipolar(0.5)};

{
    var nextProxy = 0;
    e.playing = true;
    {e.playing}.while {
        ~a[nextProxy] = Pbind(
            \instrument, \fm3mc_perc,
            \amp, 1,
            \scale, Scale.minorPentatonic,
            \root, 3,
            \octave, Pdup(4, Pseq([3,4,5].scramble, inf) ),
            \degree, Pseq([0, 2, 4, 6].scramble, inf),
            \dur, Pseq([0.0625, 0.125, 0.25, 0.5, 1, 2].scramble * 4, rrand(1, 4)),
            \vel, Pseq([ 0.2, 0.6, 9 ].scramble, inf),
            \mIndex1, ~lfo1,
            \mIndex2, ~lfo2,
            \mIndex3, ~lfo3,
            \pan, ~lfo4,
        );
        nextProxy = nextProxy + 1 % 16;
        // exprand(1, 8).round.wait;
        [4, 8].choose.wait;
    };
    16.do{|i| ~a[i] = 0; 1.wait};
}.fork;
)
e.playing = false;
