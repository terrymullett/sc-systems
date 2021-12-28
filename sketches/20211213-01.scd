"../setup/Setup.scd".loadRelative;

(
p.clear;
p.fadeTime_(2);
~out = { \in.ar(0!2) };
~out.play;
~out[10] = \filter -> { |in| BHiPass4.ar(in, 40)}; ~out.set(\wet10, 1);
~a.ar(2);
~a <>> ~out;
~lfo0 = {LFNoise2.kr(0.5).bipolar(0.5)};
~lfo1 = {LFNoise2.kr(0.5).range(0, 2)};
~lfo2 = {LFNoise2.kr(0.5).range(0, 2)};
~lfo3 = {LFNoise2.kr(0.5).range(0, 6)};
~lfo4 = {LFNoise2.kr(0.25).range(0, 1)};

{
    var nextProxy = 0;
    e.playing = true;
    {e.playing}.while {
        ~a[nextProxy] = Pbind(
            \instrument, \sin_pulsar,
            \amp, 1,
            \scale, Scale.minorPentatonic,
            \root, 3,
            \octave, Pdup(4, Pseq([3,4,5].scramble, inf) ),
            \degree, Pseq([0, 2, 4, 6].scramble, inf),
            \dur, Pseq([0.0625, 0.125, 0.25, 0.5, 1, 2].scramble * 8, rrand(1, 4)),
            \vel, Pseq([ 0.2, 0.6, 9 ].scramble, inf),
            \formantA, ~lfo1,
            \overlapA, ~lfo2,
            \formantB, ~lfo3,
            \overlapB, ~lfo4,
            \pan, ~lfo0,
            \midEQ, Pkey(\freq) * 4,
            \midEQdb, -12,
            \lpf, Pkey(\freq) * 6,
        );
        nextProxy = nextProxy + 1 % 16;
        exprand(1, 8).round.wait;
        // [4, 8].choose.wait;
    };
    16.do{|i| ~a[i].stop; 0.2.wait};
    ~a.free;
}.fork;
)
e.playing = false;
