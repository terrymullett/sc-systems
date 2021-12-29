(
{
    var wt, wtFiles = ["AKWF_0001", "AKWF_0003", "AKWF_0006"];
    var firstWt, lastWt;

    "../setup/Setup.scd".loadRelative;
    topEnvironment.use { {~envReady.isNil}.while{0.1.wait} };
    p.makeTempoClock(2).quant_(4).fadeTime_(2);

    wt = Buffer.allocConsecutive(wtFiles.size, s, 8192);
    wtFiles.do{
        |which, i|
        wt[i].read(thisProcess.nowExecutingPath.dirname +/+ "../wt/" +/+ which ++ ".wav.wtable");
    };

    ~out = { \in.ar(0!2) };
    ~out.play;
    ~a <>> ~out;

    ~lfo0 = { LFNoise2.ar(0.25).range(wt[0].bufnum, wt[wt.size-1].bufnum) };

    ~a[0] = Pbind(
        \instrument, \wtmorph0,
        \bufX, wt[0].bufnum,
        \bufY, wt[wt.size - 1].bufnum,
        \morph, ~lfo0,
        \dur, Pseq([4, 2, 8.5], 15),
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

    );
}.fork(AppClock);
)

