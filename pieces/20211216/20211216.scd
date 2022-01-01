(
"../../setup/Setup.scd".loadRelative;
{
    var numVoices = 8;
    var scale = Scale.leadingWhole, root = 3;
    var w, b, player, playing = false;

    0.1.wait;
    topEnvironment.use { {~envReady.isNil}.while {0.01.wait}};
    p.clear;
    p.fadeTime_(2);
    ~out = { \in.ar(0!2) };
    ~out.play;
    ~out[10] = \filterIn -> {
        |in|
        var sig = NHHall.ar(
            in: in,
            rt60: 2,
            stereo: 0.5,
            lowFreq: 200,
            lowRatio: 0.5,
            hiFreq: 3000,
            hiRatio: 0.5,
            earlyDiffusion: 0.5,
            lateDiffusion: 0.5,
            modRate: 0.2,
            modDepth: 0.3
        );
        LeakDC.ar(HPF.ar(LPF.ar(sig, 4000), 20));
    };
    ~out.set(\wet10, 0.1);
    ~out[20] = \filter -> { |in| BHiPass4.ar(in, 40)}; ~out.set(\wet20, 1);
    ~a.ar(2);
    ~a <>> ~out;
    ~lfo0 = {LFNoise2.kr(0.5).bipolar(0.5)};
    ~lfo1 = {LFNoise2.kr(0.5).range(0, 0.2)};

    player = r{
        var nextProxy = 0;
        playing = true;
        {playing}.while {
            ~a[nextProxy] = Pbind(
                \instrument, \highLonesome1,
                \amp, 0.2,
                \scale, scale,
                \root, root,
                \octave, Pdup(4, Pseq([3,4,5].scramble, inf) ),
                \degree, Pseq([0, 2, 4, 6, 8].scramble, inf),
                \dur, Pseq([0.0625, 0.125, 0.25, 0.5, 1, 2].scramble * 8, rrand(1, 2)),
                \vel, Pseq([ 0.2, 0.6, 0.9 ].scramble, inf),
                \rel, 4,
                \pan, ~lfo0,
                \detuner, ~lfo1,
            );
            nextProxy = nextProxy + 1 % numVoices;
            exprand(1, 8).wait;
        };
        numVoices.do{|i| ~a[i].free(fadeTime: 0.5); 0.5.wait};
        ~a.free(fadeTime: 2);
        2.wait;
        { b.valueAction_(0) }.defer;
    };

    Window.allWindows.do{|x| if( x.name == "Control", {x.close})};
    w = Window.new("Control", Rect(50,100,256,256), resizable: false);
    b = Button(w, Rect(0, 0, 256, 256))
    .font_(Font("Monaco", 60))
    .canFocus_(false)
    .states_([["Play"],["Stop"],["Stopping"]])
    .action_({|v|
        switch (v.value,
            {1}, {
                player.reset.play;
            },
            {2}, {
                playing = false;
                b.enabled_(false);
            },
            {0}, {
                b.enabled_(true);
            },
        );
    });
    w.front;

}.fork(AppClock);
)
